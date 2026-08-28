import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/learning_session.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/knowledge_point_repository.dart';
import '../../data/repositories/learning_session_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/seeders/demo_data_seeder.dart';
import '../../data/repositories/source_chunk_repository.dart';
import '../../data/repositories/source_repository.dart';
import '../agent/learning_agent_planner_service.dart';
import '../privacy/product_event_recorder.dart';
import '../../data/models/product_event.dart';

enum FirstRunStep {
  goal('goal'),
  modelReadiness('model_readiness'),
  projectImport('project_import'),
  coverageReview('coverage_review'),
  firstSession('first_session'),
  outcomePreview('outcome_preview'),
  completed('completed');

  final String value;

  const FirstRunStep(this.value);

  static FirstRunStep fromString(String? value) {
    return FirstRunStep.values.firstWhere(
      (step) => step.value == value,
      orElse: () => FirstRunStep.goal,
    );
  }
}

class FirstRunProgress {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final FirstRunStep step;
  final LearningAgentGoal selectedGoal;
  final String? sourceId;
  final String? sessionId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool legacyUser;

  const FirstRunProgress({
    required this.step,
    required this.selectedGoal,
    required this.startedAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
    this.sourceId,
    this.sessionId,
    this.completedAt,
    this.legacyUser = false,
  });

  factory FirstRunProgress.initial({DateTime? now}) {
    final createdAt = now ?? DateTime.now();
    return FirstRunProgress(
      step: FirstRunStep.goal,
      selectedGoal: LearningAgentGoal.aiInterviewPrep,
      startedAt: createdAt,
      updatedAt: createdAt,
    );
  }

  bool get isCompleted => step == FirstRunStep.completed;

  String get flowId => 'first_run_${startedAt.toUtc().microsecondsSinceEpoch}';

  FirstRunProgress copyWith({
    FirstRunStep? step,
    LearningAgentGoal? selectedGoal,
    String? sourceId,
    String? sessionId,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? legacyUser,
    bool clearSourceId = false,
    bool clearSessionId = false,
    bool clearCompletedAt = false,
  }) {
    return FirstRunProgress(
      schemaVersion: currentSchemaVersion,
      step: step ?? this.step,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      sourceId: clearSourceId ? null : sourceId ?? this.sourceId,
      sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      legacyUser: legacyUser ?? this.legacyUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'step': step.value,
      'selected_goal': selectedGoal.value,
      'source_id': sourceId,
      'session_id': sessionId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'legacy_user': legacyUser,
    };
  }

  factory FirstRunProgress.fromJson(Map<String, dynamic> json) {
    final fallbackTime = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final startedAt =
        DateTime.tryParse(json['started_at']?.toString() ?? '') ?? fallbackTime;
    return FirstRunProgress(
      schemaVersion:
          int.tryParse(json['schema_version']?.toString() ?? '') ?? 1,
      step: FirstRunStep.fromString(json['step']?.toString()),
      selectedGoal: LearningAgentGoal.fromString(
        json['selected_goal']?.toString() ??
            LearningAgentGoal.aiInterviewPrep.value,
      ),
      sourceId: _nonEmpty(json['source_id']),
      sessionId: _nonEmpty(json['session_id']),
      startedAt: startedAt,
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? startedAt,
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      legacyUser: json['legacy_user'] == true,
    );
  }

  static String? _nonEmpty(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  bool operator ==(Object other) {
    return other is FirstRunProgress &&
        other.schemaVersion == schemaVersion &&
        other.step == step &&
        other.selectedGoal == selectedGoal &&
        other.sourceId == sourceId &&
        other.sessionId == sessionId &&
        other.startedAt == startedAt &&
        other.updatedAt == updatedAt &&
        other.completedAt == completedAt &&
        other.legacyUser == legacyUser;
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        step,
        selectedGoal,
        sourceId,
        sessionId,
        startedAt,
        updatedAt,
        completedAt,
        legacyUser,
      );
}

abstract class FirstRunProgressStore {
  Future<FirstRunProgress?> read();

  Future<void> write(FirstRunProgress progress);

  Future<void> clear();
}

class SharedPreferencesFirstRunProgressStore implements FirstRunProgressStore {
  static const String storageKey = 'first_run_progress_v1';

  final Future<SharedPreferences> Function() _preferencesLoader;

  SharedPreferencesFirstRunProgressStore({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  @override
  Future<FirstRunProgress?> read() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return FirstRunProgress.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(FirstRunProgress progress) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(storageKey, jsonEncode(progress.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferencesLoader();
    await preferences.remove(storageKey);
  }
}

class FirstRunBootstrapService {
  static const Set<String> _existingPreferenceKeys = {
    'learning_agent_goal',
    'ai_provider_id',
    'ai_model_acceptance_reports_v1',
  };

  final SourceRepository _sourceRepository;
  final SourceChunkRepository _sourceChunkRepository;
  final KnowledgePointRepository _knowledgePointRepository;
  final DeckRepository _deckRepository;
  final QuestionRepository _questionRepository;
  final LearningSessionRepository _learningSessionRepository;
  final DatabaseHelper? _databaseHelper;
  final Future<void> Function()? _demoDataSeeder;
  final Future<SharedPreferences> Function() _preferencesLoader;

  FirstRunBootstrapService({
    required SourceRepository sourceRepository,
    required SourceChunkRepository sourceChunkRepository,
    required KnowledgePointRepository knowledgePointRepository,
    required DeckRepository deckRepository,
    required QuestionRepository questionRepository,
    required LearningSessionRepository learningSessionRepository,
    DatabaseHelper? databaseHelper,
    Future<void> Function()? demoDataSeeder,
    Future<SharedPreferences> Function()? preferencesLoader,
  })  : _sourceRepository = sourceRepository,
        _sourceChunkRepository = sourceChunkRepository,
        _knowledgePointRepository = knowledgePointRepository,
        _deckRepository = deckRepository,
        _questionRepository = questionRepository,
        _learningSessionRepository = learningSessionRepository,
        _databaseHelper = databaseHelper,
        _demoDataSeeder = demoDataSeeder,
        _preferencesLoader =
            preferencesLoader ?? SharedPreferences.getInstance {
    if (databaseHelper == null && demoDataSeeder == null) {
      throw ArgumentError(
        'Provide databaseHelper or demoDataSeeder for first-run demo data.',
      );
    }
  }

  /// 导入 Demo 数据(Vue.js 响应式系统)
  Future<void> seedDemoData() async {
    final demoDataSeeder = _demoDataSeeder;
    if (demoDataSeeder != null) {
      await demoDataSeeder();
      return;
    }
    final seeder = DemoDataSeeder(_databaseHelper!);
    await seeder.seedVueCoreDemo();
  }

  Future<bool> hasExistingUserData() async {
    final preferences = await _preferencesLoader();
    if (_existingPreferenceKeys.any(preferences.containsKey)) return true;

    final results = await Future.wait<bool>([
      _sourceRepository.getAllSources().then((items) => items.isNotEmpty),
      _deckRepository.getAllDecks().then((items) => items.isNotEmpty),
      _questionRepository.getAllQuestions().then((items) => items.isNotEmpty),
      _learningSessionRepository
          .getLearningSessions()
          .then((items) => items.isNotEmpty),
    ]);
    return results.any((hasItems) => hasItems);
  }

  Future<FirstRunProgress> reconcile(
    FirstRunProgress progress, {
    DateTime? now,
  }) async {
    if (progress.isCompleted) return progress;
    final reconciledAt = now ?? DateTime.now();
    var current = progress;
    final sourceId = current.sourceId;

    if (sourceId != null) {
      final source = await _sourceRepository.getSource(sourceId);
      if (source == null) {
        return current.copyWith(
          step: FirstRunStep.projectImport,
          updatedAt: reconciledAt,
          clearSourceId: true,
          clearSessionId: true,
        );
      }
      if (current.step.index <= FirstRunStep.projectImport.index) {
        current = current.copyWith(
          step: FirstRunStep.coverageReview,
          updatedAt: reconciledAt,
        );
      }
      if (current.step.index <= FirstRunStep.coverageReview.index &&
          await _hasVerifiedContent(sourceId)) {
        current = current.copyWith(
          step: FirstRunStep.firstSession,
          updatedAt: reconciledAt,
        );
      }
    } else if (current.step.index >= FirstRunStep.coverageReview.index) {
      current = current.copyWith(
        step: FirstRunStep.projectImport,
        updatedAt: reconciledAt,
        clearSessionId: true,
      );
    }

    if (current.step.index >= FirstRunStep.firstSession.index &&
        current.step.index < FirstRunStep.completed.index) {
      final completedSession = await latestCompletedAgentSession(current);
      if (completedSession != null &&
          current.step.index <= FirstRunStep.firstSession.index) {
        current = current.copyWith(
          step: FirstRunStep.outcomePreview,
          sessionId: completedSession.id,
          updatedAt: reconciledAt,
        );
      }
    }
    return current;
  }

  Future<LearningSession?> latestCompletedAgentSession(
    FirstRunProgress progress,
  ) async {
    final sessions = await _learningSessionRepository.getLearningSessions();
    final candidates = sessions
        .where((session) =>
            session.mode == LearningSessionMode.agentSession &&
            session.endedAt != null &&
            !session.startedAt.isBefore(progress.startedAt))
        .toList()
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<bool> _hasVerifiedContent(String sourceId) async {
    final chunks = await _sourceChunkRepository.getSourceChunks(sourceId);
    final chunkIds = chunks.map((chunk) => chunk.id).toSet();
    if (chunkIds.isEmpty) return false;
    final relations =
        await _knowledgePointRepository.getAllKnowledgePointSources();
    return relations.any(
      (relation) => chunkIds.contains(relation.sourceChunkId),
    );
  }
}

class FirstRunProgressNotifier
    extends StateNotifier<AsyncValue<FirstRunProgress>> {
  final FirstRunProgressStore _store;
  final FirstRunBootstrapService _bootstrapService;
  final ProductEventRecorder? _eventRecorder;
  final DateTime Function() _clock;

  FirstRunProgressNotifier({
    required FirstRunProgressStore store,
    required FirstRunBootstrapService bootstrapService,
    ProductEventRecorder? eventRecorder,
    DateTime Function()? clock,
    bool autoLoad = true,
  })  : _store = store,
        _bootstrapService = bootstrapService,
        _eventRecorder = eventRecorder,
        _clock = clock ?? DateTime.now,
        super(const AsyncValue.loading()) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      var progress = await _store.read();
      if (progress == null) {
        final now = _clock();
        if (await _bootstrapService.hasExistingUserData()) {
          progress = FirstRunProgress(
            step: FirstRunStep.completed,
            selectedGoal: LearningAgentGoal.aiInterviewPrep,
            startedAt: now,
            updatedAt: now,
            completedAt: now,
            legacyUser: true,
          );
        } else {
          // 新用户:自动导入 Demo 数据并标记为已完成
          await _bootstrapService.seedDemoData();
          progress = FirstRunProgress(
            step: FirstRunStep.completed,
            selectedGoal: LearningAgentGoal.programmingFoundations,
            startedAt: now,
            updatedAt: now,
            completedAt: now,
            legacyUser: false,
          );
        }
        await _store.write(progress);
      } else {
        final reconciled = await _bootstrapService.reconcile(
          progress,
          now: _clock(),
        );
        if (reconciled != progress) {
          progress = reconciled;
          await _store.write(progress);
        }
      }
      state = AsyncValue.data(progress);
      if (!progress.legacyUser && progress.step == FirstRunStep.goal) {
        await _eventRecorder?.recordBestEffort(
          ProductEventName.onboardingStarted,
          flowId: progress.flowId,
          goal: progress.selectedGoal.value,
          properties: const {'entry_point': 'clean_install'},
          dedupeKey: '${progress.flowId}:onboarding_started',
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> confirmGoal(LearningAgentGoal goal) async {
    await _update((current, now) => current.copyWith(
          step: FirstRunStep.modelReadiness,
          selectedGoal: goal,
          updatedAt: now,
        ));
    final progress = state.valueOrNull;
    if (progress == null) return;
    await _eventRecorder?.recordBestEffort(
      ProductEventName.goalSelected,
      flowId: progress.flowId,
      goal: goal.value,
      properties: {'goal': goal.value},
      dedupeKey: '${progress.flowId}:goal_selected',
    );
  }

  Future<void> continueToProjectImport() {
    return _update((current, now) => current.copyWith(
          step: FirstRunStep.projectImport,
          updatedAt: now,
        ));
  }

  Future<void> recordImportedSource(String sourceId) {
    return _update((current, now) => current.copyWith(
          step: FirstRunStep.coverageReview,
          sourceId: sourceId,
          updatedAt: now,
          clearSessionId: true,
        ));
  }

  Future<void> recordCoverageReviewed() {
    return _update((current, now) => current.copyWith(
          step: FirstRunStep.firstSession,
          updatedAt: now,
        ));
  }

  Future<void> recordCompletedSession(String sessionId) {
    return _update((current, now) => current.copyWith(
          step: FirstRunStep.outcomePreview,
          sessionId: sessionId,
          updatedAt: now,
        ));
  }

  Future<void> refreshDerivedProgress() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final reconciled = await _bootstrapService.reconcile(
        current,
        now: _clock(),
      );
      if (reconciled != current) await _store.write(reconciled);
      state = AsyncValue.data(reconciled);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> complete() {
    return _update((current, now) => current.copyWith(
          step: FirstRunStep.completed,
          updatedAt: now,
          completedAt: now,
        ));
  }

  Future<void> _update(
    FirstRunProgress Function(FirstRunProgress current, DateTime now) transform,
  ) async {
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('First-run progress is not loaded.');
    }
    final updated = transform(current, _clock());
    try {
      await _store.write(updated);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
