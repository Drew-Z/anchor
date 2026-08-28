import 'dart:math';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/deck.dart';
import 'package:anchor_learning/data/models/product_event.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/repositories/product_event_repository.dart';
import 'package:anchor_learning/services/ai/ai_api_protocol.dart';
import 'package:anchor_learning/services/ai/ai_model_acceptance.dart';
import 'package:anchor_learning/services/onboarding/first_run_progress.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:anchor_learning/services/privacy/local_data_deletion_service.dart';
import 'package:anchor_learning/services/privacy/privacy_preferences.dart';
import 'package:anchor_learning/services/privacy/privacy_redactor.dart';
import 'package:anchor_learning/services/privacy/product_event_recorder.dart';
import 'package:anchor_learning/services/privacy/support_bundle_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('redactor removes credentials, private paths and URL queries', () {
    const redactor = PrivacyRedactor();
    final redacted = redactor.redact(
      'Authorization: test-token-123456 '
      r'C:\Users\zhang\project\main.dart '
      'https://relay.example/v1?api_key=secret',
    );

    expect(redacted, isNot(contains('test-token-123456')));
    expect(redacted, isNot(contains(r'C:\Users\zhang')));
    expect(redacted, isNot(contains('api_key=secret')));
    expect(redacted, contains('[redacted_secret]'));
    expect(redacted, contains('[private_path]'));
    expect(redacted, contains('https://relay.example/v1'));

    final diagnostic = redactor.redactDiagnostic('''
问题: 我的私有实现细节
来源片段摘要:
- class SecretImplementation {}
错误: timeout
''');
    expect(diagnostic, isNot(contains('我的私有实现细节')));
    expect(diagnostic, isNot(contains('SecretImplementation')));
    expect(diagnostic, contains('[omitted_private_content]'));
    expect(diagnostic, contains('错误: timeout'));
  });

  test('support bundle contains only counts and redacted diagnostics',
      () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final now = DateTime.utc(2026, 7, 16, 13);
    await helper.insertSource(
      Source(
        id: 'source-private',
        title: 'Private source title',
        type: SourceType.project,
        trustLevel: SourceTrustLevel.sourceCode,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(9),
    );
    final repository = ProductEventRepository(helper);
    final recorder = ProductEventRecorder(
      repository: repository,
      preferencesStore: preferences,
      clock: () => now,
      random: Random(10),
      platform: 'test',
    );
    await recorder.record(
      ProductEventName.onboardingStarted,
      properties: const {'entry_point': 'clean_install'},
    );
    final service = SupportBundleService(
      databaseHelper: helper,
      productEventRepository: repository,
      privacyPreferencesStore: preferences,
      acceptanceStore: _MemoryAcceptanceStore(),
      firstRunProgressStore: _MemoryFirstRunProgressStore(),
      openAIService: _FakeOpenAIService(),
      clock: () => now,
    );

    final artifact = await service.buildSupportBundle(
      diagnosticLines: const [
        'key=sk-secret123456',
        r'path=C:\Users\zhang\private\main.dart',
        'endpoint=https://relay.example/v1?token=secret',
      ],
    );

    expect(artifact.content, contains('"sources": 1'));
    expect(artifact.content, isNot(contains('Private source title')));
    expect(artifact.content, isNot(contains('sk-secret123456')));
    expect(artifact.content, isNot(contains(r'C:\Users\zhang')));
    expect(artifact.content, isNot(contains('token=secret')));
    expect(artifact.content, contains('[redacted_api_key]'));
  });

  test('scoped deletion preserves content when only history is selected',
      () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final now = DateTime.utc(2026, 7, 16, 14);
    await helper.insertDeck(
      Deck(
        id: 'deck-keep',
        title: 'Keep content',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(11),
    );
    final repository = ProductEventRepository(helper);
    final recorder = ProductEventRecorder(
      repository: repository,
      preferencesStore: preferences,
      clock: () => now,
      random: Random(12),
      platform: 'test',
    );
    await recorder.record(
      ProductEventName.onboardingStarted,
      properties: const {'entry_point': 'clean_install'},
    );
    final service = LocalDataDeletionService(
      databaseHelper: helper,
      openAIService: _FakeOpenAIService(),
      firstRunProgressStore: _MemoryFirstRunProgressStore(),
      privacyPreferencesStore: preferences,
      eventRecorder: recorder,
    );

    await service.delete({LocalDataScope.learningHistory});
    expect((await helper.getAllDecks()).single.id, 'deck-keep');
    expect(
      (await repository.getEvents()).map((event) => event.name),
      contains(ProductEventName.dataDeleted),
    );

    await service.delete({LocalDataScope.productEvents});
    final remaining = await repository.getEvents();
    expect(remaining, hasLength(1));
    expect(remaining.single.name, ProductEventName.dataDeleted);
  });

  test('model configuration deletion clears every named profile', () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': AIProviders.grokPrimaryId,
      OpenAIService.profilePreferenceKey(
        AIProviders.grokPrimaryId,
        'base_url',
      ): 'https://grok.example/v1',
      OpenAIService.profilePreferenceKey(
        AIProviders.grokPrimaryId,
        'model',
      ): 'grok-model',
      OpenAIService.profilePreferenceKey(
        AIProviders.grokPrimaryId,
        'protocol',
      ): 'responses',
      OpenAIService.profilePreferenceKey(
        AIProviders.mimoFallbackId,
        'base_url',
      ): 'https://mimo.example/v1',
      OpenAIService.profilePreferenceKey(
        AIProviders.mimoFallbackId,
        'model',
      ): 'mimo-model',
      OpenAIService.profilePreferenceKey(
        AIProviders.mimoFallbackId,
        'protocol',
      ): 'chat_completions',
      'ai_model_acceptance_reports_v1': '[]',
    });
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(helper.close);
    final preferences = SharedPreferencesPrivacyPreferencesStore(
      random: Random(13),
    );
    final repository = ProductEventRepository(helper);
    final recorder = ProductEventRecorder(
      repository: repository,
      preferencesStore: preferences,
      clock: () => DateTime.utc(2026, 7, 16, 15),
      random: Random(14),
      platform: 'test',
    );
    final openAIService = _FakeOpenAIService();
    final service = LocalDataDeletionService(
      databaseHelper: helper,
      openAIService: openAIService,
      firstRunProgressStore: _MemoryFirstRunProgressStore(),
      privacyPreferencesStore: preferences,
      eventRecorder: recorder,
    );

    await service.delete({LocalDataScope.modelConfiguration});

    final stored = await SharedPreferences.getInstance();
    expect(
      stored.getKeys().where(
            (key) => key.startsWith(OpenAIService.profilePreferencePrefix),
          ),
      isEmpty,
    );
    expect(stored.getString('ai_provider_id'), isNull);
    expect(stored.getString('ai_model_acceptance_reports_v1'), isNull);
    expect(
      openAIService.clearedProviderIds.toSet(),
      containsAll(AIProviders.builtin.map((provider) => provider.id)),
    );
  });
}

class _FakeOpenAIService extends OpenAIService {
  final List<String> clearedProviderIds = [];

  @override
  Future<String> getProviderId() async => 'custom';

  @override
  Future<String> getBaseUrl() async =>
      'https://relay.example/v1?api_key=must-not-export';

  @override
  Future<String> getModel() async => 'test-model';

  @override
  Future<AiApiProtocol> getApiProtocol() async => AiApiProtocol.responses;

  @override
  Future<bool> hasApiKey({String? providerId}) async => true;

  @override
  Future<void> clearApiKey({String? providerId}) async {
    clearedProviderIds.add(providerId ?? 'custom');
  }
}

class _MemoryAcceptanceStore implements AiModelAcceptanceStore {
  @override
  Future<bool> isAccepted(AiModelConfiguration configuration) async => false;

  @override
  Future<AiModelAcceptanceReport?> latestFor(
    AiModelConfiguration configuration,
  ) async =>
      null;

  @override
  Future<List<AiModelAcceptanceReport>> readAll() async => const [];

  @override
  Future<void> save(AiModelAcceptanceReport report) async {}
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
