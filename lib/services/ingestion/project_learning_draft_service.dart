import '../../data/models/knowledge_point.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../ai/tasks/project_understanding_task.dart';
import '../ai/tasks/question_generation_task.dart';
import 'source_grounded_ingestion_service.dart';

enum ProjectLearningDraftStage {
  understanding,
  questions,
  citations;

  String get label {
    switch (this) {
      case ProjectLearningDraftStage.understanding:
        return 'AI 正在生成项目理解...';
      case ProjectLearningDraftStage.questions:
        return 'AI 正在生成练习题...';
      case ProjectLearningDraftStage.citations:
        return '正在预核验引用依据...';
    }
  }
}

class ProjectLearningDraft {
  final Source source;
  final List<SourceChunk> chunks;
  final String deckId;
  final List<KnowledgePoint> knowledgePoints;
  final Map<String, List<String>> sourceChunkIdsByKnowledgePointId;
  final List<Question> questions;

  const ProjectLearningDraft({
    required this.source,
    required this.chunks,
    required this.deckId,
    required this.knowledgePoints,
    required this.sourceChunkIdsByKnowledgePointId,
    required this.questions,
  });
}

class ProjectLearningDraftService {
  final ProjectUnderstandingTask _projectUnderstandingTask;
  final QuestionGenerationTask _questionGenerationTask;
  final SourceGroundedIngestionService _sourceGroundedIngestionService;

  const ProjectLearningDraftService({
    required ProjectUnderstandingTask projectUnderstandingTask,
    required QuestionGenerationTask questionGenerationTask,
    required SourceGroundedIngestionService sourceGroundedIngestionService,
  })  : _projectUnderstandingTask = projectUnderstandingTask,
        _questionGenerationTask = questionGenerationTask,
        _sourceGroundedIngestionService = sourceGroundedIngestionService;

  Future<ProjectLearningDraft> generate({
    required Source source,
    required List<SourceChunk> chunks,
    void Function(ProjectLearningDraftStage stage)? onStage,
  }) async {
    if (chunks.isEmpty) {
      throw StateError('项目材料为空，无法生成学习内容');
    }
    final now = DateTime.now();
    final deckId = '${source.id}_deck';

    onStage?.call(ProjectLearningDraftStage.understanding);
    final understandingResult =
        await _projectUnderstandingTask.run(sourceChunks: chunks);
    if (!understandingResult.isSuccess) {
      throw StateError(
        understandingResult.errorMessage ?? '项目理解生成失败',
      );
    }
    final buildResult =
        _sourceGroundedIngestionService.buildProjectUnderstandingDrafts(
      sourceId: source.id,
      now: now,
      units: understandingResult.requireData.units,
    );

    onStage?.call(ProjectLearningDraftStage.questions);
    final questionResult = await _questionGenerationTask.run(
      knowledgePoints: buildResult.knowledgePoints,
      sourceChunks: chunks,
      questionCount: _sourceGroundedIngestionService.questionCountFor(
        buildResult.knowledgePoints.length,
      ),
    );
    if (!questionResult.isSuccess) {
      throw StateError(questionResult.errorMessage ?? '题目生成失败');
    }
    final questions = questionResult.requireData.questions
        .map((draft) => draft.toQuestion(deckId: deckId))
        .toList();

    onStage?.call(ProjectLearningDraftStage.citations);
    final verifiedQuestions =
        await _sourceGroundedIngestionService.precheckQuestions(
      questions: questions,
      chunks: chunks,
    );

    return ProjectLearningDraft(
      source: source,
      chunks: chunks,
      deckId: deckId,
      knowledgePoints: buildResult.knowledgePoints,
      sourceChunkIdsByKnowledgePointId:
          buildResult.sourceChunkIdsByKnowledgePointId,
      questions: verifiedQuestions,
    );
  }
}
