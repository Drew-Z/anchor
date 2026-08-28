import 'dart:math';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/product_event.dart';
import 'package:anchor_learning/data/repositories/deck_repository.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/data/repositories/product_event_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/data/repositories/source_repository.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:anchor_learning/services/onboarding/first_run_progress.dart';
import 'package:anchor_learning/services/privacy/privacy_preferences.dart';
import 'package:anchor_learning/services/privacy/product_event_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists immutable allowlisted events and ignores a dedupe replay',
      () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final repository = ProductEventRepository(helper);
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(1),
    );
    final now = DateTime.utc(2026, 7, 16, 11);
    final recorder = ProductEventRecorder(
      repository: repository,
      preferencesStore: preferences,
      clock: () => now,
      random: Random(2),
      platform: 'test',
      appVersionOverride: 'test-version',
    );

    final first = await recorder.record(
      ProductEventName.goalSelected,
      flowId: 'first_run_1',
      goal: 'project_walkthrough',
      properties: const {'goal': 'project_walkthrough'},
      dedupeKey: 'first_run_1:goal_selected',
    );
    final replay = await recorder.record(
      ProductEventName.goalSelected,
      flowId: 'first_run_1',
      goal: 'project_walkthrough',
      properties: const {'goal': 'project_walkthrough'},
      dedupeKey: 'first_run_1:goal_selected',
    );

    expect(first, isTrue);
    expect(replay, isFalse);
    final event = (await repository.getEvents()).single;
    expect(event.schemaVersion, ProductEvent.currentSchemaVersion);
    expect(event.properties, const {'goal': 'project_walkthrough'});
    expect(event.toExportJson().containsKey('dedupe_key'), isFalse);
    expect(event.anonymousInstallId, hasLength(32));
  });

  test('rejects non-allowlisted and private event properties', () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final recorder = ProductEventRecorder(
      repository: ProductEventRepository(helper),
      preferencesStore: SharedPreferencesPrivacyPreferencesStore(
        random: Random(3),
      ),
      random: Random(4),
      platform: 'test',
    );

    expect(
      () => recorder.record(
        ProductEventName.projectImportStarted,
        properties: const {
          'import_type': 'directory',
          'absolute_path': r'C:\Users\private\project',
        },
      ),
      throwsArgumentError,
    );
    expect(
      () => recorder.record(
        ProductEventName.projectImportFailed,
        properties: const {
          'failure_code': 'sk-secret123456',
          'phase': 'scan',
        },
      ),
      throwsArgumentError,
    );
    expect(await ProductEventRepository(helper).count(), 0);
  });

  test('local event preference stops new writes without deleting history',
      () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(5),
    );
    await preferences.write(
      const PrivacyPreferences(localProductEventsEnabled: false),
    );
    final recorder = ProductEventRecorder(
      repository: ProductEventRepository(helper),
      preferencesStore: preferences,
      random: Random(6),
      platform: 'test',
    );

    expect(
      await recorder.record(
        ProductEventName.onboardingStarted,
        properties: const {'entry_point': 'clean_install'},
      ),
      isFalse,
    );
    expect(await ProductEventRepository(helper).count(), 0);
  });

  test('clean first run emits onboarding then goal selection exactly once',
      () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final repository = ProductEventRepository(helper);
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(7),
    );
    var tick = 0;
    final startedAt = DateTime.utc(2026, 7, 16, 12);
    final recorder = ProductEventRecorder(
      repository: repository,
      preferencesStore: preferences,
      clock: () => startedAt.add(Duration(milliseconds: tick++)),
      random: Random(8),
      platform: 'test',
    );
    final store = _MemoryFirstRunProgressStore();
    await store.write(FirstRunProgress.initial(now: startedAt));
    final notifier = FirstRunProgressNotifier(
      store: store,
      bootstrapService: FirstRunBootstrapService(
        sourceRepository: SourceRepository(helper),
        sourceChunkRepository: SourceChunkRepository(helper),
        knowledgePointRepository: KnowledgePointRepository(helper),
        deckRepository: DeckRepository(helper),
        questionRepository: QuestionRepository(helper),
        learningSessionRepository: LearningSessionRepository(helper),
        databaseHelper: helper,
      ),
      eventRecorder: recorder,
      clock: () => startedAt,
      autoLoad: false,
    );

    await notifier.load();
    await notifier.confirmGoal(LearningAgentGoal.projectWalkthrough);
    await notifier.confirmGoal(LearningAgentGoal.projectWalkthrough);

    final events = (await repository.getEvents()).reversed.toList();
    expect(
      events.map((event) => event.name),
      [ProductEventName.onboardingStarted, ProductEventName.goalSelected],
    );
    expect(events.first.flowId, events.last.flowId);
  });

  test('private-alpha grounded path has a fixed local event sequence',
      () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final repository = ProductEventRepository(helper);
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(13),
    );
    var tick = 0;
    final recorder = ProductEventRecorder(
      repository: repository,
      preferencesStore: preferences,
      clock: () =>
          DateTime.utc(2026, 7, 16, 15).add(Duration(milliseconds: tick++)),
      random: Random(14),
      platform: 'test',
    );
    const flowId = 'first_run_grounded_path';
    const goal = 'ai_interview_prep';
    final events = <(ProductEventName, Map<String, Object?>)>[
      (
        ProductEventName.onboardingStarted,
        const {'entry_point': 'clean_install'},
      ),
      (ProductEventName.goalSelected, const {'goal': goal}),
      (
        ProductEventName.modelReadinessViewed,
        const {
          'provider_configured': true,
          'protocol_configured': true,
        },
      ),
      (
        ProductEventName.modelAcceptanceCompleted,
        const {
          'passed': true,
          'failure_category': 'none',
          'case_count': 5,
          'latency_bucket': '15_to_60s',
        },
      ),
      (
        ProductEventName.projectImportStarted,
        const {'import_type': 'directory'},
      ),
      (
        ProductEventName.projectScanCompleted,
        const {
          'selected_count': 12,
          'excluded_count': 4,
          'total_bytes_bucket': '64_to_256kb',
          'duration_bucket': '1_to_5s',
        },
      ),
      (
        ProductEventName.verifiedContentSaved,
        const {
          'source_count': 1,
          'point_count': 4,
          'question_count': 6,
          'exercise_count': 1,
        },
      ),
      (
        ProductEventName.coverageReviewCompleted,
        const {
          'included_count': 10,
          'excluded_count': 2,
          'locator_coverage': 'complete',
        },
      ),
      (
        ProductEventName.agentWorkspaceViewed,
        const {
          'scope': 'mixed',
          'next_action_type': 'new_learning',
          'blocker_code': 'none',
        },
      ),
      (
        ProductEventName.groundedTurnCompleted,
        const {
          'surface': 'interview',
          'disposition': 'grounded',
          'citation_count': 2,
          'duration_bucket': '15_to_60s',
        },
      ),
      (
        ProductEventName.reviewScheduled,
        const {
          'target_type': 'knowledge_point',
          'due_bucket': 'due_now',
        },
      ),
      (
        ProductEventName.followUpCompleted,
        const {
          'action_type': 'question_review',
          'target_type': 'question',
        },
      ),
      (
        ProductEventName.outcomeViewed,
        const {
          'ready_count': 1,
          'weak_count': 2,
          'gap_count': 0,
          'unassessed_count': 1,
        },
      ),
      (
        ProductEventName.outcomeExported,
        const {
          'format': 'markdown',
          'included_citation_count': 4,
        },
      ),
      (
        ProductEventName.feedbackSubmitted,
        const {
          'category': 'feature_request',
          'severity': 'medium',
          'diagnostic_consent': false,
        },
      ),
    ];

    for (final entry in events) {
      await recorder.record(
        entry.$1,
        flowId: flowId,
        goal: goal,
        properties: entry.$2,
      );
    }

    final stored = (await repository.getEvents()).reversed.toList();
    expect(stored.map((event) => event.name), events.map((entry) => entry.$1));
    final encoded = stored.map((event) => event.toExportJson()).toString();
    expect(encoded, isNot(contains('api_key')));
    expect(encoded, isNot(contains('source body')));
    expect(encoded, isNot(contains('user_answer')));
    expect(encoded, isNot(contains('model_output')));
    expect(encoded, isNot(contains(r'C:\Users\')));
  });

  test('outcome events reject answers, source text and model output', () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final recorder = ProductEventRecorder(
      repository: ProductEventRepository(helper),
      preferencesStore: SharedPreferencesPrivacyPreferencesStore(
        random: Random(15),
      ),
      random: Random(16),
      platform: 'test',
    );

    for (final property in const [
      'user_answer',
      'source_text',
      'model_output'
    ]) {
      expect(
        () => recorder.record(
          ProductEventName.outcomeViewed,
          properties: {
            'ready_count': 1,
            'weak_count': 0,
            'gap_count': 0,
            'unassessed_count': 0,
            property: 'private content',
          },
        ),
        throwsArgumentError,
      );
    }
    expect(await ProductEventRepository(helper).count(), 0);
  });
}

class _MemoryFirstRunProgressStore implements FirstRunProgressStore {
  FirstRunProgress? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<FirstRunProgress?> read() async => value;

  @override
  Future<void> write(FirstRunProgress progress) async => value = progress;
}
