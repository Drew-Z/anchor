import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/ingestion/project_import_screen.dart';
import 'package:dlg_q/features/onboarding/first_run_screen.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/ai/ai_api_protocol.dart';
import 'package:dlg_q/services/ai/ai_model_acceptance.dart';
import 'package:dlg_q/services/ai/tasks/citation_verification_task.dart';
import 'package:dlg_q/services/ingestion/source_grounded_ingestion_service.dart';
import 'package:dlg_q/services/onboarding/first_run_model_readiness.dart';
import 'package:dlg_q/services/onboarding/first_run_progress.dart';
import 'package:dlg_q/services/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/disabled_privacy_preferences_store.dart';

void main() {
  final now = DateTime.utc(2026, 7, 16, 8);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('missing model is visible but local project import remains open',
      (tester) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            const DisabledPrivacyPreferencesStore(),
          ),
          firstRunModelReadinessProvider.overrideWith(
            (ref) async => _missingModelReadiness(),
          ),
        ],
        child: MaterialApp(
          home: FirstRunScreen(
            progress: FirstRunProgress(
              step: FirstRunStep.modelReadiness,
              selectedGoal: LearningAgentGoal.aiInterviewPrep,
              startedAt: now,
              updatedAt: now,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('当前模型尚未通过验收'), findsOneWidget);
    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '继续导入本地项目'),
    );
    expect(continueButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coverage generation stays blocked until model acceptance passes',
      (tester) async {
    _useMobileViewport(tester);
    final source = _source(now);
    final chunk = _chunk(source.id, now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            const DisabledPrivacyPreferencesStore(),
          ),
          sourceProvider(source.id).overrideWith((ref) async => source),
          sourceChunksProvider(source.id).overrideWith(
            (ref) async => [chunk],
          ),
          firstRunModelReadinessProvider.overrideWith(
            (ref) async => _missingModelReadiness(),
          ),
        ],
        child: MaterialApp(
          home: FirstRunScreen(
            progress: FirstRunProgress(
              step: FirstRunStep.coverageReview,
              selectedGoal: LearningAgentGoal.aiInterviewPrep,
              sourceId: source.id,
              startedAt: now,
              updatedAt: now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI 生成已阻断'), findsOneWidget);
    final generateButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '生成并核验项目学习内容'),
    );
    expect(generateButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('material-only project import succeeds without an API key',
      (tester) async {
    _useMobileViewport(tester);
    final ingestionService = _RecordingIngestionService();
    ProjectImportResult? imported;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            const DisabledPrivacyPreferencesStore(),
          ),
          sourceGroundedIngestionServiceProvider
              .overrideWithValue(ingestionService),
        ],
        child: MaterialApp(
          home: ProjectImportScreen(
            localMaterialOnly: true,
            onMaterialPersisted: (result) async {
              imported = result;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == '例如：Duoduo Learn',
      ),
      'Local project',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == '粘贴 README 或你自己的项目说明',
      ),
      'A local-only source-grounded learning project.',
    );
    await tester.scrollUntilVisible(
      find.text('保存本地项目材料'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('保存本地项目材料'));
    await tester.pump(const Duration(milliseconds: 100));

    final renderedText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' | ');
    expect(imported, isNotNull, reason: renderedText);
    expect(ingestionService.savedSource?.id, imported!.sourceId);
    expect(ingestionService.savedChunks, hasLength(1));
    expect(find.textContaining('API Key'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

FirstRunModelReadiness _missingModelReadiness() {
  return FirstRunModelReadiness(
    configuration: AiModelConfiguration(
      providerId: 'custom',
      baseUrl: 'https://provider.example/v1',
      model: 'candidate-model',
      protocol: AiApiProtocol.responses,
    ),
    hasCredential: false,
    acceptanceReport: null,
  );
}

Source _source(DateTime now) {
  return Source(
    id: 'source-1',
    title: 'Local project',
    type: SourceType.project,
    trustLevel: SourceTrustLevel.sourceCode,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(String sourceId, DateTime now) {
  return SourceChunk(
    id: 'chunk-1',
    sourceId: sourceId,
    chunkIndex: 0,
    content: 'class App {}',
    relativePath: 'lib/app.dart',
    contentHash: 'hash-1',
    createdAt: now,
  );
}

class _RecordingIngestionService extends SourceGroundedIngestionService {
  Source? savedSource;
  List<SourceChunk> savedChunks = const [];

  _RecordingIngestionService()
      : super(
          databaseHelper: DatabaseHelper(),
          citationVerificationTask:
              CitationVerificationTask(_UnusedOpenAIService()),
        );

  @override
  Future<void> saveSourceMaterial({
    required Source source,
    required List<SourceChunk> chunks,
  }) async {
    savedSource = source;
    savedChunks = List.unmodifiable(chunks);
  }
}

class _UnusedOpenAIService extends OpenAIService {
  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) {
    throw UnimplementedError();
  }
}
