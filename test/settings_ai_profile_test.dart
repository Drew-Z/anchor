import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/user_stats.dart';
import 'package:dlg_q/features/settings/settings_screen.dart';
import 'package:dlg_q/services/ai/ai_api_credential_store.dart';
import 'package:dlg_q/services/ai/ai_api_protocol.dart';
import 'package:dlg_q/services/gamification_service.dart';
import 'package:dlg_q/services/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('switching named providers restores each saved AI profile',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': AIProviders.grokPrimaryId,
      OpenAIService.profilePreferenceKey(
        AIProviders.grokPrimaryId,
        'base_url',
      ): 'https://grok-profile.example/v1',
      OpenAIService.profilePreferenceKey(
        AIProviders.grokPrimaryId,
        'model',
      ): 'grok-4.5',
      OpenAIService.profilePreferenceKey(
        AIProviders.grokPrimaryId,
        'protocol',
      ): AiApiProtocol.responses.value,
      OpenAIService.profilePreferenceKey(
        AIProviders.mimoFallbackId,
        'base_url',
      ): 'https://mimo-profile.example/v1',
      OpenAIService.profilePreferenceKey(
        AIProviders.mimoFallbackId,
        'model',
      ): 'mimo-v2',
      OpenAIService.profilePreferenceKey(
        AIProviders.mimoFallbackId,
        'protocol',
      ): AiApiProtocol.chatCompletions.value,
    });
    final service = OpenAIService(
      credentialStore: _MemoryCredentialStore(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openaiServiceProvider.overrideWithValue(service),
          gamificationServiceProvider.overrideWithValue(
            _FakeGamificationService(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    _expectVisibleProfile(
      tester,
      baseUrl: 'https://grok-profile.example/v1',
      model: 'grok-4.5',
      protocol: AiApiProtocol.responses,
    );

    await _selectProvider(tester, 'Mimo 通道（备）');
    _expectVisibleProfile(
      tester,
      baseUrl: 'https://mimo-profile.example/v1',
      model: 'mimo-v2',
      protocol: AiApiProtocol.chatCompletions,
    );

    await _selectProvider(tester, 'Grok 4.5 通道（主）');
    _expectVisibleProfile(
      tester,
      baseUrl: 'https://grok-profile.example/v1',
      model: 'grok-4.5',
      protocol: AiApiProtocol.responses,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectProvider(WidgetTester tester, String providerName) async {
  await tester.tap(find.byType(DropdownButton<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(providerName).last);
  await tester.pumpAndSettle();
}

void _expectVisibleProfile(
  WidgetTester tester, {
  required String baseUrl,
  required String model,
  required AiApiProtocol protocol,
}) {
  final baseUrlField = tester.widget<TextField>(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'https://api.example.com/v1',
    ),
  );
  final modelField = tester.widget<TextField>(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '输入模型名称',
    ),
  );
  final protocolControl = tester.widget<SegmentedButton<AiApiProtocol>>(
    find.byWidgetPredicate(
      (widget) => widget is SegmentedButton<AiApiProtocol>,
    ),
  );

  expect(baseUrlField.controller?.text, baseUrl);
  expect(modelField.controller?.text, model);
  expect(protocolControl.selected, {protocol});
}

class _MemoryCredentialStore implements AiApiCredentialStore {
  final Map<String, String> _values = {};

  @override
  Future<void> deleteApiKey(String providerId) async {
    _values.remove(providerId);
  }

  @override
  Future<String?> readApiKey(String providerId) async => _values[providerId];

  @override
  Future<void> writeApiKey(String providerId, String apiKey) async {
    _values[providerId] = apiKey;
  }
}

class _FakeGamificationService extends GamificationService {
  _FakeGamificationService() : super(DatabaseHelper());

  @override
  Future<UserStats> getStats() async {
    return UserStats(lastStudyDate: DateTime(2026, 7, 16));
  }

  @override
  Future<void> setDailyGoal(int goal) async {}
}
