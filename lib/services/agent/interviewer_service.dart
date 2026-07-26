import '../../data/models/grounded_learning_context.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/source_chunk.dart';
import '../ai/ai_task_result.dart';
import '../ai/tasks/answer_evaluation_task.dart';
import '../ai/tasks/interview_question_task.dart';

class InterviewerService {
  final InterviewQuestionTask _questionTask;
  final AnswerEvaluationTask _evaluationTask;

  InterviewerService({
    required InterviewQuestionTask questionTask,
    required AnswerEvaluationTask evaluationTask,
  })  : _questionTask = questionTask,
        _evaluationTask = evaluationTask;

  Future<AiTaskResult<InterviewQuestionResult>> generateQuestions({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    int questionCount = 1,
    String? followUpQuestion,
    GroundedLearningContext? groundedContext,
  }) {
    return _questionTask.run(
      knowledgePoints: knowledgePoints,
      sourceChunks: sourceChunks,
      questionCount: questionCount,
      followUpQuestion: followUpQuestion,
      groundedContext: groundedContext,
    );
  }

  Future<AiTaskResult<AnswerEvaluationResult>> evaluateAnswer({
    required InterviewQuestionDraft question,
    required String userAnswer,
    required List<SourceChunk> citedChunks,
    GroundedLearningContext? groundedContext,
  }) {
    return _evaluationTask.run(
      question: question.question,
      userAnswer: userAnswer,
      knowledgePointIds: question.knowledgePointIds,
      citedChunks: citedChunks,
      groundedContext: groundedContext,
    );
  }
}
