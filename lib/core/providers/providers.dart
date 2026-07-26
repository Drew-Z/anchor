import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/deck.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/knowledge_point_source.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/programming_exercise_attempt.dart';
import '../../data/models/programming_review_action.dart';
import '../../data/models/product_event.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../data/models/study_record.dart';
import '../../data/models/tutor_turn.dart';
import '../../data/models/user_stats.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/knowledge_point_repository.dart';
import '../../data/repositories/learning_session_repository.dart';
import '../../data/repositories/programming_exercise_repository.dart';
import '../../data/repositories/programming_review_action_repository.dart';
import '../../data/repositories/product_event_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/source_chunk_repository.dart';
import '../../data/repositories/source_repository.dart';
import '../../data/repositories/study_record_repository.dart';
import '../../services/agent/agent_session_memory_index.dart';
import '../../services/agent/grounded_learning_context_service.dart';
import '../../services/agent/hybrid_knowledge_search_service.dart';
import '../../services/agent/interviewer_service.dart';
import '../../services/agent/knowledge_answer_context_service.dart';
import '../../services/agent/knowledge_search_service.dart';
import '../../services/agent/model_search_query_variant_provider.dart';
import '../../services/agent/search_preferences.dart';
import '../../services/agent/learning_agent_checkpoint.dart';
import '../../services/agent/learning_agent_checkpoint_store.dart';
import '../../services/agent/learning_agent_memory_store.dart';
import '../../services/agent/learning_agent_memory_record.dart';
import '../../services/agent/learning_agent_memory_timeline_builder.dart';
import '../../services/agent/learning_agent_next_action.dart';
import '../../services/agent/learning_agent_practice_target.dart';
import '../../services/agent/learning_agent_planner_service.dart';
import '../../services/agent/learning_agent_runtime.dart';
import '../../services/agent/learning_agent_workspace.dart';
import '../../services/agent/project_interview_outcome.dart';
import '../../services/ai/tasks/answer_evaluation_task.dart';
import '../../services/ai/tasks/citation_verification_task.dart';
import '../../services/ai/tasks/concept_prerequisite_task.dart';
import '../../services/ai/tasks/interview_question_task.dart';
import '../../services/ai/tasks/knowledge_answer_task.dart';
import '../../services/ai/tasks/knowledge_extraction_task.dart';
import '../../services/ai/tasks/question_generation_task.dart';
import '../../services/ai/tasks/project_understanding_task.dart';
import '../../services/ai/tasks/programming_exercise_evaluation_task.dart';
import '../../services/ai/tasks/programming_exercise_generation_task.dart';
import '../../services/ai/tasks/tutor_explanation_task.dart';
import '../../services/ai/tasks/tutor_socratic_task.dart';
import '../../services/ai/ai_model_acceptance.dart';
import '../../services/content_analyzer.dart';
import '../../services/gamification_service.dart';
import '../../services/ingestion/android_project_directory_bridge.dart';
import '../../services/ingestion/project_learning_draft_service.dart';
import '../../services/ingestion/project_source_import_service.dart';
import '../../services/ingestion/programming_source_import_service.dart';
import '../../services/ingestion/source_grounded_ingestion_service.dart';
import '../../services/onboarding/first_run_model_readiness.dart';
import '../../services/onboarding/first_run_progress.dart';
import '../../services/openai_service.dart';
import '../../services/privacy/alpha_feedback_service.dart';
import '../../services/privacy/local_data_backup_service.dart';
import '../../services/privacy/local_data_deletion_service.dart';
import '../../services/privacy/privacy_preferences.dart';
import '../../services/privacy/privacy_redactor.dart';
import '../../services/privacy/product_event_recorder.dart';
import '../../services/privacy/support_bundle_service.dart';
import '../../services/scheduling/mastery_service.dart';
import '../../services/scheduling/programming_review_closure_service.dart';
import '../../services/scheduling/concept_learning_path_service.dart';
import '../../services/scheduling/interview_review_closure_service.dart';
import '../../services/scheduling/review_scheduler_service.dart';

// ============ 基础服务 Provider ============

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.read(databaseProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.read(databaseProvider));
});

final studyRecordRepositoryProvider = Provider<StudyRecordRepository>((ref) {
  return StudyRecordRepository(ref.read(databaseProvider));
});

final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return SourceRepository(ref.read(databaseProvider));
});

final sourceChunkRepositoryProvider = Provider<SourceChunkRepository>((ref) {
  return SourceChunkRepository(ref.read(databaseProvider));
});

final knowledgePointRepositoryProvider =
    Provider<KnowledgePointRepository>((ref) {
  return KnowledgePointRepository(ref.read(databaseProvider));
});

final learningSessionRepositoryProvider =
    Provider<LearningSessionRepository>((ref) {
  return LearningSessionRepository(
    ref.read(databaseProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final programmingExerciseRepositoryProvider =
    Provider<ProgrammingExerciseRepository>((ref) {
  return ProgrammingExerciseRepository(
    ref.read(databaseProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final programmingReviewActionRepositoryProvider =
    Provider<ProgrammingReviewActionRepository>((ref) {
  return ProgrammingReviewActionRepository(
    ref.read(databaseProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final productEventRepositoryProvider = Provider<ProductEventRepository>((ref) {
  return ProductEventRepository(ref.read(databaseProvider));
});

final privacyPreferencesStoreProvider =
    Provider<PrivacyPreferencesStore>((ref) {
  return SharedPreferencesPrivacyPreferencesStore();
});

final privacyPreferencesProvider = StateNotifierProvider<
    PrivacyPreferencesNotifier, AsyncValue<PrivacyPreferences>>((ref) {
  return PrivacyPreferencesNotifier(
    store: ref.read(privacyPreferencesStoreProvider),
  );
});

final privacyRedactorProvider = Provider<PrivacyRedactor>((ref) {
  return const PrivacyRedactor();
});

final productEventRecorderProvider = Provider<ProductEventRecorder>((ref) {
  return ProductEventRecorder(
    repository: ref.read(productEventRepositoryProvider),
    preferencesStore: ref.read(privacyPreferencesStoreProvider),
  );
});

final productEventListProvider = FutureProvider<List<ProductEvent>>((ref) {
  return ref.read(productEventRepositoryProvider).getEvents(limit: 100);
});

final firstRunProgressStoreProvider = Provider<FirstRunProgressStore>((ref) {
  return SharedPreferencesFirstRunProgressStore();
});

final firstRunBootstrapServiceProvider =
    Provider<FirstRunBootstrapService>((ref) {
  return FirstRunBootstrapService(
    sourceRepository: ref.read(sourceRepositoryProvider),
    sourceChunkRepository: ref.read(sourceChunkRepositoryProvider),
    knowledgePointRepository: ref.read(knowledgePointRepositoryProvider),
    deckRepository: ref.read(deckRepositoryProvider),
    questionRepository: ref.read(questionRepositoryProvider),
    learningSessionRepository: ref.read(learningSessionRepositoryProvider),
    databaseHelper: ref.read(databaseProvider),
  );
});

final firstRunProgressProvider = StateNotifierProvider<FirstRunProgressNotifier,
    AsyncValue<FirstRunProgress>>((ref) {
  return FirstRunProgressNotifier(
    store: ref.read(firstRunProgressStoreProvider),
    bootstrapService: ref.read(firstRunBootstrapServiceProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final aiModelAcceptanceStoreProvider = Provider<AiModelAcceptanceStore>((ref) {
  return SharedPreferencesAiModelAcceptanceStore();
});

final openaiServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService(
    acceptanceStore: ref.read(aiModelAcceptanceStoreProvider),
    enforceModelAcceptance: true,
  );
});

final supportBundleServiceProvider = Provider<SupportBundleService>((ref) {
  return SupportBundleService(
    databaseHelper: ref.read(databaseProvider),
    productEventRepository: ref.read(productEventRepositoryProvider),
    privacyPreferencesStore: ref.read(privacyPreferencesStoreProvider),
    acceptanceStore: ref.read(aiModelAcceptanceStoreProvider),
    firstRunProgressStore: ref.read(firstRunProgressStoreProvider),
    openAIService: ref.read(openaiServiceProvider),
    redactor: ref.read(privacyRedactorProvider),
  );
});

final alphaFeedbackServiceProvider = Provider<AlphaFeedbackService>((ref) {
  return AlphaFeedbackService(
    databaseSchemaVersion: DatabaseHelper.schemaVersion,
    supportBundleBuilder: (diagnosticLines) {
      return ref.read(supportBundleServiceProvider).buildSupportBundle(
            diagnosticLines: diagnosticLines,
          );
    },
    eventRecorder: (draft) async {
      await ref.read(productEventRecorderProvider).recordBestEffort(
        ProductEventName.feedbackSubmitted,
        flowId: draft.screenId,
        properties: {
          'category': draft.category.value,
          'severity': draft.severity.value,
          'diagnostic_consent': draft.diagnosticConsent,
        },
      );
    },
    redactor: ref.read(privacyRedactorProvider),
  );
});

final localDataDeletionServiceProvider =
    Provider<LocalDataDeletionService>((ref) {
  return LocalDataDeletionService(
    databaseHelper: ref.read(databaseProvider),
    openAIService: ref.read(openaiServiceProvider),
    firstRunProgressStore: ref.read(firstRunProgressStoreProvider),
    privacyPreferencesStore: ref.read(privacyPreferencesStoreProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final localDataBackupServiceProvider = Provider<LocalDataBackupService>((ref) {
  return LocalDataBackupService(databaseHelper: ref.read(databaseProvider));
});

final aiModelAcceptanceRunnerProvider =
    Provider<AiModelAcceptanceRunner>((ref) {
  return AiModelAcceptanceRunner(
    client: ref.read(openaiServiceProvider),
    store: ref.read(aiModelAcceptanceStoreProvider),
  );
});

final firstRunModelReadinessServiceProvider =
    Provider<FirstRunModelReadinessService>((ref) {
  return FirstRunModelReadinessService(
    openAIService: ref.read(openaiServiceProvider),
    acceptanceStore: ref.read(aiModelAcceptanceStoreProvider),
  );
});

final firstRunModelReadinessProvider =
    FutureProvider<FirstRunModelReadiness>((ref) {
  return ref.read(firstRunModelReadinessServiceProvider).load();
});

final contentAnalyzerProvider = Provider<ContentAnalyzer>((ref) {
  return ContentAnalyzer(ref.read(openaiServiceProvider));
});

final knowledgeExtractionTaskProvider =
    Provider<KnowledgeExtractionTask>((ref) {
  return KnowledgeExtractionTask(ref.read(openaiServiceProvider));
});

final projectUnderstandingTaskProvider =
    Provider<ProjectUnderstandingTask>((ref) {
  return ProjectUnderstandingTask(ref.read(openaiServiceProvider));
});

final questionGenerationTaskProvider = Provider<QuestionGenerationTask>((ref) {
  return QuestionGenerationTask(ref.read(openaiServiceProvider));
});

final citationVerificationTaskProvider =
    Provider<CitationVerificationTask>((ref) {
  return CitationVerificationTask(ref.read(openaiServiceProvider));
});

final conceptPrerequisiteTaskProvider =
    Provider<ConceptPrerequisiteTask>((ref) {
  return ConceptPrerequisiteTask(ref.read(openaiServiceProvider));
});

final conceptLearningPathServiceProvider =
    Provider<ConceptLearningPathService>((ref) {
  return const ConceptLearningPathService();
});

final sourceGroundedIngestionServiceProvider =
    Provider<SourceGroundedIngestionService>((ref) {
  return SourceGroundedIngestionService(
    databaseHelper: ref.read(databaseProvider),
    citationVerificationTask: ref.read(citationVerificationTaskProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final projectLearningDraftServiceProvider =
    Provider<ProjectLearningDraftService>((ref) {
  return ProjectLearningDraftService(
    projectUnderstandingTask: ref.read(projectUnderstandingTaskProvider),
    questionGenerationTask: ref.read(questionGenerationTaskProvider),
    sourceGroundedIngestionService:
        ref.read(sourceGroundedIngestionServiceProvider),
  );
});

final projectSourceImportServiceProvider =
    Provider<ProjectSourceImportService>((ref) {
  return const ProjectSourceImportService();
});

final programmingSourceImportServiceProvider =
    Provider<ProgrammingSourceImportService>((ref) {
  return const ProgrammingSourceImportService();
});

final androidProjectDirectoryBridgeProvider =
    Provider<AndroidProjectDirectoryBridge>((ref) {
  return const AndroidProjectDirectoryBridge();
});

final interviewQuestionTaskProvider = Provider<InterviewQuestionTask>((ref) {
  return InterviewQuestionTask(ref.read(openaiServiceProvider));
});

final answerEvaluationTaskProvider = Provider<AnswerEvaluationTask>((ref) {
  return AnswerEvaluationTask(ref.read(openaiServiceProvider));
});

final tutorExplanationTaskProvider = Provider<TutorExplanationTask>((ref) {
  return TutorExplanationTask(ref.read(openaiServiceProvider));
});

final tutorSocraticTaskProvider = Provider<TutorSocraticTask>((ref) {
  return TutorSocraticTask(ref.read(openaiServiceProvider));
});

final programmingExerciseGenerationTaskProvider =
    Provider<ProgrammingExerciseGenerationTask>((ref) {
  return ProgrammingExerciseGenerationTask(ref.read(openaiServiceProvider));
});

final programmingExerciseEvaluationTaskProvider =
    Provider<ProgrammingExerciseEvaluationTask>((ref) {
  return ProgrammingExerciseEvaluationTask(ref.read(openaiServiceProvider));
});

final knowledgeAnswerTaskProvider = Provider<KnowledgeAnswerTask>((ref) {
  return KnowledgeAnswerTask(ref.read(openaiServiceProvider));
});

final interviewerServiceProvider = Provider<InterviewerService>((ref) {
  return InterviewerService(
    questionTask: ref.read(interviewQuestionTaskProvider),
    evaluationTask: ref.read(answerEvaluationTaskProvider),
  );
});

final learningAgentPlannerServiceProvider =
    Provider<LearningAgentPlannerService>((ref) {
  return const LearningAgentPlannerService();
});

final learningAgentCheckpointStoreProvider =
    Provider<LearningAgentCheckpointStore>((ref) {
  return SqliteLearningAgentCheckpointStore(ref.watch(databaseProvider));
});

final learningAgentRuntimeProvider = Provider<LearningAgentRuntime>((ref) {
  return LearningAgentRuntime(
    checkpointStore: ref.watch(learningAgentCheckpointStoreProvider),
  );
});

final learningAgentActiveCheckpointListProvider =
    FutureProvider<List<LearningAgentCheckpoint>>((ref) {
  return ref.watch(learningAgentCheckpointStoreProvider).loadActive();
});

final knowledgeSearchServiceProvider = Provider<KnowledgeSearchService>((ref) {
  return const KnowledgeSearchService();
});

final hybridKnowledgeSearchServiceProvider =
    Provider<HybridKnowledgeSearchService>((ref) {
  return HybridKnowledgeSearchService(
    lexicalSearch: ref.read(knowledgeSearchServiceProvider),
  );
});

final searchPreferencesStoreProvider = Provider<SearchPreferencesStore>((ref) {
  return SharedPreferencesSearchPreferencesStore();
});

final searchPreferencesProvider = StateNotifierProvider<
    SearchPreferencesNotifier, AsyncValue<SearchPreferences>>((ref) {
  return SearchPreferencesNotifier(
    store: ref.read(searchPreferencesStoreProvider),
  );
});

final modelSearchQueryVariantProvider = Provider<SearchQueryVariantProvider>(
  (ref) => ModelSearchQueryVariantProvider(
    client: ref.read(openaiServiceProvider),
    redactor: ref.read(privacyRedactorProvider),
  ),
);

final knowledgeAnswerContextServiceProvider =
    Provider<KnowledgeAnswerContextService>((ref) {
  return const KnowledgeAnswerContextService();
});

final groundedLearningContextServiceProvider =
    Provider<GroundedLearningContextService>((ref) {
  return const GroundedLearningContextService();
});

final learningAgentGoalProvider =
    StateNotifierProvider<LearningAgentGoalNotifier, LearningAgentGoal>((ref) {
  return LearningAgentGoalNotifier();
});

class LearningAgentGoalNotifier extends StateNotifier<LearningAgentGoal> {
  LearningAgentGoalNotifier() : super(LearningAgentGoal.aiInterviewPrep) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('learning_agent_goal') ??
        LearningAgentGoal.aiInterviewPrep.value;
    state = LearningAgentGoal.fromString(value);
  }

  Future<void> setGoal(LearningAgentGoal goal) async {
    state = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning_agent_goal', goal.value);
  }
}

final masteryServiceProvider = Provider<MasteryService>((ref) {
  return MasteryService(ref.read(knowledgePointRepositoryProvider));
});

final programmingReviewClosureServiceProvider =
    Provider<ProgrammingReviewClosureService>((ref) {
  return ProgrammingReviewClosureService(
    knowledgePointRepository: ref.read(knowledgePointRepositoryProvider),
    questionRepository: ref.read(questionRepositoryProvider),
    exerciseRepository: ref.read(programmingExerciseRepositoryProvider),
    actionRepository: ref.read(programmingReviewActionRepositoryProvider),
    databaseHelper: ref.read(databaseProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final interviewReviewClosureServiceProvider =
    Provider<InterviewReviewClosureService>((ref) {
  return InterviewReviewClosureService(
    knowledgePointRepository: ref.read(knowledgePointRepositoryProvider),
    questionRepository: ref.read(questionRepositoryProvider),
    databaseHelper: ref.read(databaseProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final reviewSchedulerServiceProvider = Provider<ReviewSchedulerService>((ref) {
  return ReviewSchedulerService(
    questionRepository: ref.read(questionRepositoryProvider),
    knowledgePointRepository: ref.read(knowledgePointRepositoryProvider),
    eventRecorder: ref.read(productEventRecorderProvider),
  );
});

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(ref.read(databaseProvider));
});

// ============ 数据 Provider ============

/// 所有题包列表
final deckListProvider = FutureProvider<List<Deck>>((ref) async {
  return ref.read(deckRepositoryProvider).getAllDecks();
});

final sourceListProvider = FutureProvider<List<Source>>((ref) {
  return ref.read(sourceRepositoryProvider).getAllSources();
});

final sourceProvider = FutureProvider.family<Source?, String>((ref, sourceId) {
  return ref.read(sourceRepositoryProvider).getSource(sourceId);
});

final knowledgePointListProvider = FutureProvider<List<KnowledgePoint>>((ref) {
  return ref.read(knowledgePointRepositoryProvider).getAllKnowledgePoints();
});

final evidenceBackedKnowledgePointListProvider =
    FutureProvider<List<KnowledgePoint>>((ref) async {
  final points =
      await ref.read(knowledgePointRepositoryProvider).getAllKnowledgePoints();
  final backedPoints = <KnowledgePoint>[];

  for (final point in points) {
    final relations = await ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePointSources(point.id);
    for (final relation in relations) {
      final chunk = await ref
          .read(sourceChunkRepositoryProvider)
          .getSourceChunk(relation.sourceChunkId);
      if (chunk != null) {
        backedPoints.add(point);
        break;
      }
    }
  }

  return backedPoints;
});

final knowledgePointProvider =
    FutureProvider.family<KnowledgePoint?, String>((ref, knowledgePointId) {
  return ref.read(knowledgePointRepositoryProvider).getKnowledgePoint(
        knowledgePointId,
      );
});

final pendingQuestionListProvider = FutureProvider<List<Question>>((ref) async {
  final questions =
      await ref.read(questionRepositoryProvider).getAllQuestions();
  return questions
      .where((question) => question.sourceStatus == SourceStatus.pending)
      .toList();
});

final sourceChunksProvider =
    FutureProvider.family<List<SourceChunk>, String>((ref, sourceId) {
  return ref.read(sourceChunkRepositoryProvider).getSourceChunks(sourceId);
});

final sourceKnowledgePointsProvider =
    FutureProvider.family<List<KnowledgePoint>, String>((ref, sourceId) async {
  final chunks =
      await ref.read(sourceChunkRepositoryProvider).getSourceChunks(sourceId);
  final chunkIds = chunks.map((chunk) => chunk.id).toSet();
  if (chunkIds.isEmpty) return [];

  final points =
      await ref.read(knowledgePointRepositoryProvider).getAllKnowledgePoints();
  final relatedPoints = <KnowledgePoint>[];
  for (final point in points) {
    final relations = await ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePointSources(point.id);
    if (relations
        .any((relation) => chunkIds.contains(relation.sourceChunkId))) {
      relatedPoints.add(point);
    }
  }
  return relatedPoints;
});

final knowledgePointSourcesProvider =
    FutureProvider.family<List<KnowledgePointSource>, String>(
        (ref, knowledgePointId) {
  return ref
      .read(knowledgePointRepositoryProvider)
      .getKnowledgePointSources(knowledgePointId);
});

final knowledgePointEvidenceChunksProvider =
    FutureProvider.family<List<SourceChunk>, String>(
        (ref, knowledgePointId) async {
  final relations = await ref
      .read(knowledgePointRepositoryProvider)
      .getKnowledgePointSources(knowledgePointId);
  final chunks = <SourceChunk>[];
  for (final relation in relations) {
    final chunk = await ref
        .read(sourceChunkRepositoryProvider)
        .getSourceChunk(relation.sourceChunkId);
    if (chunk != null) chunks.add(chunk);
  }
  return chunks;
});

final questionCitationChunksProvider =
    FutureProvider.family<List<SourceChunk>, String>((ref, citationKey) async {
  final ids = citationKey.split('\x00').where((id) => id.isNotEmpty);
  final chunks = <SourceChunk>[];
  for (final id in ids) {
    final chunk =
        await ref.read(sourceChunkRepositoryProvider).getSourceChunk(id);
    if (chunk != null) chunks.add(chunk);
  }
  return chunks;
});

final knowledgePointQuestionsProvider =
    FutureProvider.family<List<Question>, String>(
        (ref, knowledgePointId) async {
  final questions =
      await ref.read(questionRepositoryProvider).getAllQuestions();
  return questions
      .where((question) => question.knowledgePointId == knowledgePointId)
      .toList();
});

final learningSessionListProvider =
    FutureProvider<List<LearningSession>>((ref) {
  return ref.read(learningSessionRepositoryProvider).getLearningSessions();
});

final interviewSessionListProvider =
    FutureProvider<List<LearningSession>>((ref) async {
  final sessions =
      await ref.read(learningSessionRepositoryProvider).getLearningSessions();
  return sessions
      .where((session) => session.mode == LearningSessionMode.interview)
      .toList();
});

final tutorSessionListProvider =
    FutureProvider<List<LearningSession>>((ref) async {
  final sessions =
      await ref.read(learningSessionRepositoryProvider).getLearningSessions();
  return sessions
      .where((session) => session.mode == LearningSessionMode.tutor)
      .toList();
});

final knowledgeAnswerSessionListProvider =
    FutureProvider<List<LearningSession>>((ref) async {
  final sessions =
      await ref.read(learningSessionRepositoryProvider).getLearningSessions();
  return sessions
      .where((session) => session.mode == LearningSessionMode.knowledgeAnswer)
      .toList();
});

final agentSessionListProvider =
    FutureProvider<List<LearningSession>>((ref) async {
  final sessions =
      await ref.read(learningSessionRepositoryProvider).getLearningSessions();
  return sessions
      .where((session) => session.mode == LearningSessionMode.agentSession)
      .toList();
});

final agentSessionMemoryIndexProvider =
    FutureProvider<AgentSessionMemoryIndex>((ref) async {
  final sessions = await ref.watch(agentSessionListProvider.future);
  return AgentSessionMemoryIndex(sessions);
});

final learningAgentMemoryStoreProvider =
    FutureProvider<LearningAgentMemoryStore>((ref) async {
  final memoryIndex = await ref.watch(agentSessionMemoryIndexProvider.future);
  final buildResult =
      await ref.watch(learningAgentMemoryBuildResultProvider.future);
  return LearningAgentMemoryStore(
    memoryIndex,
    records: buildResult.records,
    reviewSchedules: buildResult.reviewSchedules,
  );
});

final learningAgentMemoryBuildResultProvider =
    FutureProvider<LearningAgentMemoryBuildResult>((ref) async {
  final sessionsFuture = ref.watch(learningSessionListProvider.future);
  final pointsFuture = ref.watch(knowledgePointListProvider.future);
  final pointSourcesFuture = ref.watch(allKnowledgePointSourcesProvider.future);
  final questionsFuture = ref.watch(allQuestionsProvider.future);
  final interviewTurnsFuture = ref.watch(allInterviewTurnsProvider.future);
  final tutorTurnsFuture = ref.watch(allTutorTurnsProvider.future);
  final exercisesFuture = ref.watch(allProgrammingExercisesProvider.future);
  final attemptsFuture =
      ref.watch(allProgrammingExerciseAttemptsProvider.future);
  final reviewActionsFuture =
      ref.watch(allProgrammingReviewActionsProvider.future);

  return const LearningAgentMemoryTimelineBuilder().build(
    sessions: await sessionsFuture,
    knowledgePoints: await pointsFuture,
    knowledgePointSources: await pointSourcesFuture,
    questions: await questionsFuture,
    interviewTurns: await interviewTurnsFuture,
    tutorTurns: await tutorTurnsFuture,
    programmingExercises: await exercisesFuture,
    programmingAttempts: await attemptsFuture,
    reviewActions: await reviewActionsFuture,
  );
});

final learningTargetMemoryProvider =
    FutureProvider.family<LearningAgentMemorySnapshot, String>(
  (ref, targetId) async {
    final store = await ref.watch(learningAgentMemoryStoreProvider.future);
    return store.query(targetId: targetId);
  },
);

final learningAgentWorkspaceServiceProvider =
    Provider<LearningAgentWorkspaceService>((ref) {
  return const LearningAgentWorkspaceService();
});

void invalidateAgentLearningRecordProviders(WidgetRef ref) {
  ref.invalidate(learningSessionListProvider);
  ref.invalidate(interviewSessionListProvider);
  ref.invalidate(tutorSessionListProvider);
  ref.invalidate(knowledgeAnswerSessionListProvider);
  ref.invalidate(agentSessionListProvider);
  ref.invalidate(agentSessionMemoryIndexProvider);
  ref.invalidate(allInterviewTurnsProvider);
  ref.invalidate(allTutorTurnsProvider);
  ref.invalidate(allProgrammingExerciseAttemptsProvider);
  ref.invalidate(allProgrammingReviewActionsProvider);
  ref.invalidate(allKnowledgePointSourcesProvider);
  ref.invalidate(learningAgentMemoryBuildResultProvider);
  ref.invalidate(learningAgentMemoryStoreProvider);
  ref.invalidate(projectInterviewOutcomeProvider);
}

void invalidateDatabaseBackedProviders(WidgetRef ref) {
  ref.invalidate(productEventListProvider);
  ref.invalidate(deckListProvider);
  ref.invalidate(sourceListProvider);
  ref.invalidate(sourceProvider);
  ref.invalidate(knowledgePointListProvider);
  ref.invalidate(evidenceBackedKnowledgePointListProvider);
  ref.invalidate(knowledgePointProvider);
  ref.invalidate(pendingQuestionListProvider);
  ref.invalidate(sourceChunksProvider);
  ref.invalidate(sourceKnowledgePointsProvider);
  ref.invalidate(knowledgePointSourcesProvider);
  ref.invalidate(knowledgePointEvidenceChunksProvider);
  ref.invalidate(questionCitationChunksProvider);
  ref.invalidate(knowledgePointQuestionsProvider);
  ref.invalidate(interviewTurnsProvider);
  ref.invalidate(tutorTurnsProvider);
  ref.invalidate(programmingExercisesProvider);
  ref.invalidate(programmingExerciseAttemptsProvider);
  ref.invalidate(programmingReviewQueueProvider);
  ref.invalidate(userStatsProvider);
  ref.invalidate(deckQuestionsProvider);
  ref.invalidate(verifiedDeckQuestionsProvider);
  ref.invalidate(studyRecordProvider);
  ref.invalidate(allQuestionsProvider);
  ref.invalidate(verifiedQuestionsProvider);
  ref.invalidate(verifiedPracticeTargetsProvider);
  ref.invalidate(practiceableKnowledgePointListProvider);
  ref.invalidate(knowledgeSearchCorpusProvider);
  ref.invalidate(knowledgeSearchResultsProvider);
  ref.invalidate(knowledgeAnswerGroundedContextProvider);
  ref.invalidate(knowledgeAnswerContextChunksProvider);
  ref.invalidate(learningAgentActiveCheckpointListProvider);
  ref.invalidate(learningAgentPlanProvider);
  ref.invalidate(learningAgentWorkspaceProvider);
  ref.invalidate(todayReviewQueueProvider);
  ref.invalidate(monthlyCheckInProvider);
  ref.invalidate(earnedMedalsProvider);
  ref.invalidate(totalCorrectProvider);
  ref.invalidate(perfectCountProvider);
  invalidateAgentLearningRecordProviders(ref);
}

void invalidateLearningAgentPlanInputProviders(
  WidgetRef ref,
  LearningAgentGoal goal,
) {
  ref.invalidate(evidenceBackedKnowledgePointListProvider);
  ref.invalidate(practiceableKnowledgePointListProvider);
  ref.invalidate(verifiedQuestionsProvider);
  ref.invalidate(allProgrammingExercisesProvider);
  ref.invalidate(verifiedPracticeTargetsProvider);
  ref.invalidate(pendingQuestionListProvider);
  ref.invalidate(todayReviewQueueProvider);
  ref.invalidate(learningAgentActiveCheckpointListProvider);
  ref.invalidate(learningAgentPlanProvider(goal));
}

final interviewTurnsProvider =
    FutureProvider.family<List<InterviewTurn>, String>((ref, sessionId) {
  return ref
      .read(learningSessionRepositoryProvider)
      .getInterviewTurns(sessionId);
});

final tutorTurnsProvider =
    FutureProvider.family<List<TutorTurn>, String>((ref, sessionId) {
  return ref.read(learningSessionRepositoryProvider).getTutorTurns(sessionId);
});

final allInterviewTurnsProvider = FutureProvider<List<InterviewTurn>>((ref) {
  return ref.read(learningSessionRepositoryProvider).getAllInterviewTurns();
});

final allTutorTurnsProvider = FutureProvider<List<TutorTurn>>((ref) {
  return ref.read(learningSessionRepositoryProvider).getAllTutorTurns();
});

final allKnowledgePointSourcesProvider =
    FutureProvider<List<KnowledgePointSource>>((ref) {
  return ref
      .read(knowledgePointRepositoryProvider)
      .getAllKnowledgePointSources();
});

final programmingExercisesProvider =
    FutureProvider.family<List<ProgrammingExercise>, String>(
        (ref, knowledgePointId) {
  return ref
      .read(programmingExerciseRepositoryProvider)
      .getExercisesForKnowledgePoint(knowledgePointId);
});

final allProgrammingExercisesProvider =
    FutureProvider<List<ProgrammingExercise>>((ref) {
  return ref.read(programmingExerciseRepositoryProvider).getAllExercises();
});

final programmingExerciseAttemptsProvider =
    FutureProvider.family<List<ProgrammingExerciseAttempt>, String>(
        (ref, exerciseId) {
  return ref
      .read(programmingExerciseRepositoryProvider)
      .getAttemptsForExercise(exerciseId);
});

final allProgrammingExerciseAttemptsProvider =
    FutureProvider<List<ProgrammingExerciseAttempt>>((ref) {
  return ref.read(programmingExerciseRepositoryProvider).getAllAttempts();
});

final allProgrammingReviewActionsProvider =
    FutureProvider<List<ProgrammingReviewAction>>((ref) {
  return ref.read(programmingReviewActionRepositoryProvider).getAllActions();
});

final projectInterviewOutcomeServiceProvider =
    Provider<ProjectInterviewOutcomeService>((ref) {
  return const ProjectInterviewOutcomeService();
});

final projectInterviewOutcomeProvider =
    FutureProvider<ProjectInterviewOutcome>((ref) async {
  final corpusFuture = ref.watch(knowledgeSearchCorpusProvider.future);
  final relationsFuture = ref.watch(allKnowledgePointSourcesProvider.future);
  final interviewTurnsFuture = ref.watch(allInterviewTurnsProvider.future);
  final tutorTurnsFuture = ref.watch(allTutorTurnsProvider.future);
  final attemptsFuture =
      ref.watch(allProgrammingExerciseAttemptsProvider.future);
  final reviewActionsFuture =
      ref.watch(allProgrammingReviewActionsProvider.future);
  final memoryStoreFuture = ref.watch(learningAgentMemoryStoreProvider.future);
  final corpus = await corpusFuture;

  return ref.read(projectInterviewOutcomeServiceProvider).build(
        knowledgePoints: corpus.knowledgePoints,
        knowledgePointSources: await relationsFuture,
        sources: corpus.sources,
        sourceChunks: corpus.sourceChunks,
        interviewTurns: await interviewTurnsFuture,
        tutorTurns: await tutorTurnsFuture,
        questions: corpus.questions,
        programmingAttempts: await attemptsFuture,
        reviewActions: await reviewActionsFuture,
        memoryStore: await memoryStoreFuture,
      );
});

final programmingReviewQueueProvider =
    FutureProvider<List<ProgrammingReviewQueueItem>>((ref) {
  return ref.read(programmingReviewClosureServiceProvider).getOpenQueue();
});

/// 用户统计
final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStats>>((ref) {
  return UserStatsNotifier(ref.read(gamificationServiceProvider));
});

class UserStatsNotifier extends StateNotifier<AsyncValue<UserStats>> {
  final GamificationService _service;

  UserStatsNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await _service.getStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> onCorrect() async {
    final stats = await _service.onCorrectAnswer();
    state = AsyncValue.data(stats);
  }

  Future<void> onWrong() async {
    final stats = await _service.onWrongAnswer();
    state = AsyncValue.data(stats);
  }

  Future<void> onDeckComplete({required bool allCorrect}) async {
    final stats = await _service.onDeckComplete(allCorrect: allCorrect);
    state = AsyncValue.data(stats);
  }

  /// 完美完成答题，恢复一颗心
  Future<void> onPerfectQuiz() async {
    final stats = await _service.onPerfectQuiz();
    state = AsyncValue.data(stats);
  }

  Future<void> setDailyGoal(int goal) async {
    await _service.setDailyGoal(goal);
    await _load();
  }

  Future<void> refresh() async {
    await _load();
  }
}

/// 某题包的题目列表
final deckQuestionsProvider =
    FutureProvider.family<List<Question>, String>((ref, deckId) async {
  return ref.read(questionRepositoryProvider).getQuestionsByDeck(deckId);
});

final verifiedDeckQuestionsProvider =
    FutureProvider.family<List<Question>, String>((ref, deckId) async {
  final questions =
      await ref.read(questionRepositoryProvider).getQuestionsByDeck(deckId);
  return _verifiedQuestions(questions);
});

/// 某题包的学习记录
final studyRecordProvider =
    FutureProvider.family<StudyRecord?, String>((ref, deckId) async {
  return ref.read(studyRecordRepositoryProvider).getStudyRecord(deckId);
});

// ============ 操作 Provider ============

/// 题包操作
final deckOperationsProvider = Provider<DeckOperations>((ref) {
  return DeckOperations(ref);
});

class DeckOperations {
  final Ref _ref;
  DeckOperations(this._ref);

  /// 保存分析结果为题包
  Future<String> saveAnalysisResult(
    AnalysisResult result, {
    String? sourceText,
    String? sourceImage,
  }) async {
    final deckRepository = _ref.read(deckRepositoryProvider);
    final questionRepository = _ref.read(questionRepositoryProvider);
    final now = DateTime.now();
    final deckId = now.microsecondsSinceEpoch.toString();

    final deck = Deck(
      id: deckId,
      title: result.title,
      sourceText: sourceText,
      sourceImage: sourceImage,
      questionCount: result.questions.length,
      createdAt: now,
      updatedAt: now,
    );
    await deckRepository.insertDeck(deck);

    for (final question in result.questions) {
      await questionRepository.insertQuestion(Question(
        id: '',
        deckId: deckId,
        knowledgePointId: null,
        type: question.type,
        content: question.content,
        options: question.options,
        answer: question.answer,
        explanation: question.explanation,
        sourceStatus: SourceStatus.noSource,
        citationIds: const [],
        matchLeft: question.matchLeft,
        matchRight: question.matchRight,
      ));
    }

    // 刷新题包列表
    _ref.invalidate(deckListProvider);
    _ref.invalidate(allQuestionsProvider);
    _ref.invalidate(verifiedQuestionsProvider);
    _ref.invalidate(practiceableKnowledgePointListProvider);
    _ref.invalidate(deckQuestionsProvider(deckId));
    _ref.invalidate(verifiedDeckQuestionsProvider(deckId));

    return deckId;
  }

  /// 删除题包
  Future<void> deleteDeck(String deckId) async {
    await _ref.read(deckRepositoryProvider).deleteDeck(deckId);
    _ref.invalidate(deckListProvider);
    _ref.invalidate(allQuestionsProvider);
    _ref.invalidate(verifiedQuestionsProvider);
    _ref.invalidate(practiceableKnowledgePointListProvider);
    _ref.invalidate(todayReviewQueueProvider);
    _ref.invalidate(deckQuestionsProvider(deckId));
    _ref.invalidate(verifiedDeckQuestionsProvider(deckId));
  }

  /// 更新题包掌握度
  Future<void> updateMastery(String deckId, int masteryLevel) async {
    final deckRepository = _ref.read(deckRepositoryProvider);
    final deck = await deckRepository.getDeck(deckId);
    if (deck != null) {
      await deckRepository.updateDeck(
        deck.copyWith(masteryLevel: masteryLevel, updatedAt: DateTime.now()),
      );
      _ref.invalidate(deckListProvider);
    }
  }

  /// 保存学习记录
  Future<void> saveStudyRecord(
      String deckId, int correctCount, int totalCount) async {
    final record = StudyRecord(
      id: '${deckId}_record',
      deckId: deckId,
      correctCount: correctCount,
      totalCount: totalCount,
      lastStudiedAt: DateTime.now(),
    );
    await _ref.read(studyRecordRepositoryProvider).upsertStudyRecord(record);

    // 更新掌握度
    final gamification = _ref.read(gamificationServiceProvider);
    final mastery =
        gamification.calculateMasteryLevel(correctCount, totalCount);
    await updateMastery(deckId, mastery);
  }
}

// ============ 学习模式 ============

/// 学习模式
enum LearningMode { random, knowledgePoint }

/// 学习模式 Provider（持久化到 SharedPreferences）
final learningModeProvider =
    StateNotifierProvider<LearningModeNotifier, LearningMode>((ref) {
  return LearningModeNotifier();
});

class LearningModeNotifier extends StateNotifier<LearningMode> {
  LearningModeNotifier() : super(LearningMode.random) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('learning_mode') ?? 0;
    state = LearningMode.values[index];
  }

  Future<void> setMode(LearningMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('learning_mode', mode.index);
  }
}

// ============ 随机关卡进度 ============

/// 随机模式已通关数（持久化）
final randomLevelProgressProvider =
    StateNotifierProvider<RandomLevelNotifier, int>((ref) {
  return RandomLevelNotifier();
});

class RandomLevelNotifier extends StateNotifier<int> {
  RandomLevelNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('random_level_progress') ?? 0;
  }

  /// 标记某关为已完成（只增不减）
  Future<void> completeLevel(int level) async {
    if (level > state) {
      state = level;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('random_level_progress', level);
    }
  }
}

// ============ 题目集合 ============

final allQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  return ref.read(questionRepositoryProvider).getAllQuestions();
});

final verifiedQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final questions =
      await ref.read(questionRepositoryProvider).getAllQuestions();
  return _verifiedQuestions(questions);
});

final verifiedPracticeTargetsProvider =
    FutureProvider<List<LearningAgentPracticeTarget>>((ref) async {
  final questions = await ref.watch(verifiedQuestionsProvider.future);
  final exercises = await ref.watch(allProgrammingExercisesProvider.future);
  return [
    ...questions.map(LearningAgentPracticeTarget.fromQuestion),
    ...exercises.map(LearningAgentPracticeTarget.fromProgrammingExercise),
  ].where((target) => target.isExecutable).toList(growable: false);
});

final practiceableKnowledgePointListProvider =
    FutureProvider<List<KnowledgePoint>>((ref) async {
  final points =
      await ref.read(knowledgePointRepositoryProvider).getAllKnowledgePoints();
  final targets = await ref.watch(verifiedPracticeTargetsProvider.future);
  final practiceablePointIds =
      targets.map((target) => target.knowledgePointId).toSet();

  return points
      .where((point) => practiceablePointIds.contains(point.id))
      .toList();
});

final knowledgeSearchCorpusProvider =
    FutureProvider<KnowledgeSearchCorpus>((ref) async {
  final sources = await ref.watch(sourceListProvider.future);
  final knowledgePoints = await ref.watch(knowledgePointListProvider.future);
  final questions = await ref.watch(allQuestionsProvider.future);
  final sourceChunks = <SourceChunk>[];

  for (final source in sources) {
    final chunks = await ref
        .read(sourceChunkRepositoryProvider)
        .getSourceChunks(source.id);
    sourceChunks.addAll(chunks);
  }

  return KnowledgeSearchCorpus(
    sources: sources,
    sourceChunks: sourceChunks,
    knowledgePoints: knowledgePoints,
    questions: questions,
  );
});

final knowledgeSearchResultsProvider =
    FutureProvider.family<List<KnowledgeSearchResult>, String>(
  (ref, query) async {
    final corpus = await ref.watch(knowledgeSearchCorpusProvider.future);
    return ref.read(knowledgeSearchServiceProvider).search(
          query: query,
          corpus: corpus,
        );
  },
);

final knowledgeHybridSearchReportProvider =
    FutureProvider.family<HybridKnowledgeSearchReport, String>(
  (ref, query) async {
    final corpus = await ref.watch(knowledgeSearchCorpusProvider.future);
    final preferencesAsync = ref.watch(searchPreferencesProvider);
    final preferences = preferencesAsync.maybeWhen(
          data: (value) => value,
          orElse: () => null,
        ) ??
        await ref.read(searchPreferencesStoreProvider).read();
    return ref.read(hybridKnowledgeSearchServiceProvider).search(
          query: query,
          corpus: corpus,
          variantProvider: preferences.modelAssistedSearchEnabled
              ? ref.read(modelSearchQueryVariantProvider)
              : null,
        );
  },
);

final knowledgeAnswerGroundedContextProvider =
    FutureProvider.family<GroundedLearningContext, String>((ref, query) async {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) {
    return ref.read(groundedLearningContextServiceProvider).select(
      targetId: normalizedQuery,
      surface: GroundedLearningSurface.knowledgeAnswer,
      candidates: const [],
      sources: const [],
    );
  }

  final results = await ref.watch(knowledgeSearchResultsProvider(query).future);
  final corpus = await ref.watch(knowledgeSearchCorpusProvider.future);
  final selection = ref.read(knowledgeAnswerContextServiceProvider).select(
        results: results,
        sourceChunks: corpus.sourceChunks,
      );
  KnowledgePoint? knowledgePoint;
  for (final result in results) {
    final pointId = result.knowledgePointId;
    if (pointId == null) continue;
    for (final point in corpus.knowledgePoints) {
      if (point.id == pointId) {
        knowledgePoint = point;
        break;
      }
    }
    if (knowledgePoint != null) break;
  }
  return ref.read(groundedLearningContextServiceProvider).select(
        targetId: normalizedQuery,
        knowledgePoint: knowledgePoint,
        surface: GroundedLearningSurface.knowledgeAnswer,
        candidates: selection.candidates
            .map(
              (candidate) => GroundedLearningContextCandidate(
                chunk: candidate.chunk,
                reasons: [
                  switch (candidate.reason) {
                    KnowledgeAnswerContextReason.questionCitation =>
                      GroundedLearningContextReason.questionCitation,
                    KnowledgeAnswerContextReason.directChunk ||
                    KnowledgeAnswerContextReason.matchedSourceChunk =>
                      GroundedLearningContextReason.knowledgeSearch,
                  },
                ],
              ),
            )
            .toList(growable: false),
        sources: corpus.sources,
        limit: 8,
      );
});

final knowledgeAnswerContextChunksProvider =
    FutureProvider.family<List<SourceChunk>, String>((ref, query) async {
  final context =
      await ref.watch(knowledgeAnswerGroundedContextProvider(query).future);
  return context.chunks;
});

final learningAgentPlanProvider =
    FutureProvider.family<LearningAgentPlan, LearningAgentGoal>(
  (ref, goal) async {
    final plannedAt = DateTime.now();
    final knowledgePointsFuture = ref.watch(knowledgePointListProvider.future);
    final evidenceBackedPointsFuture =
        ref.watch(evidenceBackedKnowledgePointListProvider.future);
    final practiceablePointsFuture =
        ref.watch(practiceableKnowledgePointListProvider.future);
    final practiceTargetsFuture =
        ref.watch(verifiedPracticeTargetsProvider.future);
    final programmingExercisesFuture =
        ref.watch(allProgrammingExercisesProvider.future);
    final pendingQuestionsFuture =
        ref.watch(pendingQuestionListProvider.future);
    final agentMemoryFuture =
        ref.watch(learningAgentMemoryStoreProvider.future);
    final checkpointsFuture =
        ref.watch(learningAgentActiveCheckpointListProvider.future);

    final knowledgePoints = await knowledgePointsFuture;
    final evidenceBackedPoints = await evidenceBackedPointsFuture;
    final practiceablePoints = await practiceablePointsFuture;
    final practiceTargets = await practiceTargetsFuture;
    final programmingExercises = await programmingExercisesFuture;
    final pendingQuestions = await pendingQuestionsFuture;
    final agentMemory = await agentMemoryFuture;
    final checkpoints = await checkpointsFuture;
    final goalMemory = agentMemory.memoryForGoal(goal);
    final plannerMemory = goalMemory.toPlannerMemoryState();
    final memorySnapshot = agentMemory.query(goal: goal);
    final pointsById = {
      for (final point in knowledgePoints) point.id: point,
    };
    final evidenceBackedPointIds =
        evidenceBackedPoints.map((point) => point.id).toSet();
    final practiceablePointIds =
        practiceablePoints.map((point) => point.id).toSet();
    final nextActionCandidates = <LearningAgentNextActionCandidate>[];
    final runtime = ref.read(learningAgentRuntimeProvider);

    for (final checkpoint in checkpoints) {
      if (checkpoint.state.goal != goal) continue;
      final readiness = runtime.evaluateResumeCheckpoint(checkpoint);
      final originalSummary = checkpoint.plan?.sessionSummary;
      nextActionCandidates.add(
        LearningAgentNextActionCandidate.unfinishedCheckpoint(
          sessionId: checkpoint.sessionId,
          title: readiness.requiresUserDecision
              ? '处理未完成会话决策'
              : '继续未完成 Agent Session',
          reason: readiness.message,
          updatedAt: checkpoint.state.updatedAt,
          targetId: checkpoint.state.targetId,
          targetLabel:
              originalSummary?.targetLabel ?? checkpoint.state.targetId,
          stepTypeName: originalSummary?.nextStep?.type.name,
          toolId: checkpoint.state.selectedToolId,
          executable: readiness.canResume,
          blockerCode: readiness.canResume ? null : readiness.status.value,
          blockerMessage: readiness.canResume ? null : readiness.message,
        ),
      );
    }

    for (final followUp in memorySnapshot.openFollowUps) {
      nextActionCandidates.add(
        LearningAgentNextActionCandidate.openFollowUp(
          id: followUp.id,
          question: followUp.question,
          createdAt: followUp.createdAt,
          targetId: followUp.targetId,
          targetLabel: pointsById[followUp.targetId]?.title,
        ),
      );
    }

    final inspectedEvidenceTargets = <String>{};
    for (final record in memorySnapshot.records) {
      final targetId = record.targetId;
      if (targetId == null || !inspectedEvidenceTargets.add(targetId)) {
        continue;
      }
      if (record.evidenceSufficient) continue;
      nextActionCandidates.add(
        LearningAgentNextActionCandidate.evidenceGap(
          id: 'memory:${record.id}',
          targetId: targetId,
          targetLabel: record.targetLabel ?? pointsById[targetId]?.title,
          occurredAt: record.occurredAt,
          reason: '最近的${record.type.label}记录未通过来源门禁，需要先补齐可核验证据。',
        ),
      );
    }

    for (final prerequisite in memorySnapshot.weakPrerequisites) {
      final point = pointsById[prerequisite.targetId];
      final inScope = point != null && goal.knowledgeScope.includesPoint(point);
      final hasEvidence =
          point != null && evidenceBackedPointIds.contains(point.id);
      final executable = point != null && inScope && hasEvidence;
      final blockerMessage = point == null
          ? '薄弱先修知识点已不存在，无法安全启动导师工具。'
          : !inScope
              ? '薄弱先修不在当前目标的知识范围内，请先切换学习目标。'
              : !hasEvidence
                  ? '薄弱先修缺少来源证据，需先补齐来源。'
                  : null;
      nextActionCandidates.add(
        LearningAgentNextActionCandidate.weakPrerequisite(
          id: prerequisite.targetId,
          targetId: prerequisite.targetId,
          targetLabel: prerequisite.targetLabel,
          occurredAt: prerequisite.latestAt,
          reason: '“${prerequisite.targetLabel}”作为薄弱先修出现 '
              '${prerequisite.occurrenceCount} 次，应先补齐再继续上层任务。',
          executable: executable,
          blockerCode: executable ? null : 'weak_prerequisite_unavailable',
          blockerMessage: blockerMessage,
        ),
      );
    }

    for (final review in memorySnapshot.pendingReviews) {
      if (review.dueAt.isAfter(plannedAt)) continue;
      final point = pointsById[review.targetId];
      final inScope = point != null && goal.knowledgeScope.includesPoint(point);
      final hasMaterials = practiceablePointIds.contains(review.targetId);
      final executable = point != null && inScope && hasMaterials;
      final blockerMessage = point == null
          ? '到期复习目标已不存在，无法安全启动复习工具。'
          : !inScope
              ? '到期复习目标不在当前知识范围内，请先切换学习目标。'
              : !hasMaterials
                  ? '复习已经到期，但当前没有可执行的已核验复习材料。'
                  : null;
      nextActionCandidates.add(
        LearningAgentNextActionCandidate.dueReview(
          id: review.id,
          targetId: review.targetId,
          targetLabel: point?.title,
          dueAt: review.dueAt,
          reason: '“${point?.title ?? review.targetId}”的复习时间已到，应先处理再开始新学习。',
          executable: executable,
          blockerCode: executable ? null : 'due_review_unavailable',
          blockerMessage: blockerMessage,
        ),
      );
    }

    final practiceTargetCountByPointId = <String, int>{};
    final programmingExerciseCountByPointId = <String, int>{};
    for (final target in practiceTargets) {
      final pointId = target.knowledgePointId;
      practiceTargetCountByPointId[pointId] =
          (practiceTargetCountByPointId[pointId] ?? 0) + 1;
      if (target.type == LearningAgentPracticeTargetType.programmingExercise) {
        programmingExerciseCountByPointId[pointId] =
            (programmingExerciseCountByPointId[pointId] ?? 0) + 1;
      }
    }
    final evidenceChunkCountByPointId = <String, int>{};
    for (final point in evidenceBackedPoints) {
      final relations = await ref
          .read(knowledgePointRepositoryProvider)
          .getKnowledgePointSources(point.id);
      var count = 0;
      for (final relation in relations) {
        final chunk = await ref
            .read(sourceChunkRepositoryProvider)
            .getSourceChunk(relation.sourceChunkId);
        if (chunk != null) count++;
      }
      evidenceChunkCountByPointId[point.id] = count;
    }

    return ref.read(learningAgentPlannerServiceProvider).buildPlan(
          goal: goal,
          knowledgePoints: knowledgePoints,
          evidenceBackedPoints: evidenceBackedPoints,
          practiceablePoints: practiceablePoints,
          practiceTargets: practiceTargets,
          pendingQuestions: pendingQuestions,
          pendingProgrammingExercises: programmingExercises
              .where(
                (exercise) => exercise.sourceStatus == SourceStatus.pending,
              )
              .toList(growable: false),
          nextActionCandidates: nextActionCandidates,
          plannedAt: plannedAt,
          evidenceChunkCountByPointId: evidenceChunkCountByPointId,
          practiceTargetCountByPointId: practiceTargetCountByPointId,
          programmingExerciseCountByPointId: programmingExerciseCountByPointId,
          goalSessionCount: plannerMemory.goalSessionCount,
          goalOpenFollowUpCount: plannerMemory.goalOpenFollowUpCount,
          latestGoalSessionTitle: plannerMemory.latestGoalSessionTitle,
          latestGoalSessionTarget: plannerMemory.latestGoalSessionTarget,
          latestGoalSessionStartedAt: plannerMemory.latestGoalSessionStartedAt,
        );
  },
);

final learningAgentWorkspaceProvider =
    FutureProvider.family<LearningAgentWorkspaceSnapshot, LearningAgentGoal>(
        (ref, goal) async {
  final plan = await ref.watch(learningAgentPlanProvider(goal).future);
  final memoryStore = await ref.watch(learningAgentMemoryStoreProvider.future);
  return ref.read(learningAgentWorkspaceServiceProvider).build(
        plan: plan,
        memory: memoryStore.query(goal: goal),
      );
});

List<Question> _verifiedQuestions(List<Question> questions) {
  return questions
      .where((question) => question.sourceStatus == SourceStatus.verified)
      .toList();
}

final todayReviewQueueProvider = FutureProvider<List<ReviewQueueItem>>((ref) {
  return ref.read(reviewSchedulerServiceProvider).getTodayReviewQueue();
});

// ============ 月度打卡 & 答题统计 ============

/// 当月打卡日期列表（key 格式: "2026_6"）
final monthlyCheckInProvider =
    FutureProvider.family<List<String>, String>((ref, yearMonth) async {
  final parts = yearMonth.split('_');
  return ref
      .read(gamificationServiceProvider)
      .getMonthlyCheckInDates(int.parse(parts[0]), int.parse(parts[1]));
});

/// 已获得的月度勋章
final earnedMedalsProvider =
    FutureProvider<List<({int year, int month})>>((ref) async {
  return ref.read(gamificationServiceProvider).getEarnedMedals();
});

/// 总答对题数
final totalCorrectProvider = FutureProvider<int>((ref) async {
  return ref.read(gamificationServiceProvider).getTotalCorrect();
});

/// 完美通关次数
final perfectCountProvider = FutureProvider<int>((ref) async {
  return ref.read(gamificationServiceProvider).getPerfectCount();
});
