import 'dart:async';
import 'dart:convert';

import 'package:anchor_learning/services/ai/ai_api_protocol.dart';
import 'package:anchor_learning/services/ai/ai_api_credential_store.dart';
import 'package:anchor_learning/services/ai/ai_completion_result.dart';
import 'package:anchor_learning/services/ai/ai_model_acceptance.dart';
import 'package:anchor_learning/services/ai/ai_provider_diagnostics.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runs five real-task contracts and persists an approved profile',
      () async {
    final store = _MemoryAcceptanceStore();
    final client = _QueuedCompletionClient([
      '{"topic":"binary_search","requires_sorted_input":true,'
          '"complexity":"O(log n)"}',
      '{"title":"山窗读雨","lines":["雨洗青山书气新",'
          '"松风翻页入窗频","石径归来寻字句","云开一卷见精神"]}',
      jsonEncode({
        'language': 'dart',
        'code': 'int sumEven(List<int> values) => values'
            '.where((value) => value.isEven).fold(0, (sum, value) => sum + value);',
        'examples': [
          {
            'input': [1, 2, 3, 4],
            'output': 6,
          },
          {
            'input': [-2, 3, 10],
            'output': 8,
          },
        ],
      }),
      jsonEncode({
        'status': 'answered',
        'claims': [
          {
            'text': '输入必须有序',
            'citation_id': 'S1',
            'quote': '二分查找要求输入序列已经按比较规则有序。',
          },
          {
            'text': '每轮排除一半区间',
            'citation_id': 'S1',
            'quote': '每轮会排除当前搜索区间的一半。',
          },
        ],
      }),
      '{"status":"refused","claims":[]}',
    ]);
    final configuration = AiModelConfiguration(
      providerId: 'openai',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-5.6-terra',
      protocol: AiApiProtocol.responses,
    );

    final report = await AiModelAcceptanceRunner(
      client: client,
      store: store,
      clock: () => DateTime.utc(2026, 7, 15),
    ).run(configuration);

    expect(report.passed, isTrue);
    expect(report.passedCount, 5);
    expect(report.totalTokens, 750);
    expect(report.totalLatencyMs, 250);
    expect(report.estimatedCostUsd, closeTo(0.005, 0.000001));
    expect(report.pricingSource, AiModelPricingCatalog.openAiPricingSource);
    expect(await store.isAccepted(configuration), isTrue);
    expect(client.calls, 5);
  });

  test('gives the Dart case its extended reasoning budget', () async {
    final store = _MemoryAcceptanceStore();
    final client = _DelayedCompletionClient();
    final configuration = AiModelConfiguration(
      providerId: 'custom',
      baseUrl: 'https://provider.example/v1',
      model: 'reasoning-model',
      protocol: AiApiProtocol.responses,
    );

    final report = await AiModelAcceptanceRunner(
      client: client,
      store: store,
      caseTimeout: const Duration(milliseconds: 10),
      dartCodingCaseTimeout: const Duration(milliseconds: 30),
      runTimeout: const Duration(milliseconds: 200),
    ).run(configuration);

    expect(report.passed, isTrue);
    expect(report.passedCount, 5);
    expect(client.calls, 5);
  });

  test('client restriction stops later tasks and remains actionable', () async {
    final store = _MemoryAcceptanceStore();
    final configuration = AiModelConfiguration(
      providerId: 'custom',
      baseUrl: 'https://relay.example/v1?api_key=must-not-persist',
      model: 'gpt-5.6-sol',
      protocol: AiApiProtocol.responses,
    );
    final runner = AiModelAcceptanceRunner(
      client: _BlockedCompletionClient(),
      store: store,
    );

    final report = await runner.run(configuration);

    expect(report.passed, isFalse);
    expect(report.blockingFailure, AiProviderFailureKind.clientRestricted);
    expect(report.cases.first.status, AiAcceptanceCaseStatus.failed);
    expect(report.cases.first.latencyMs, greaterThanOrEqualTo(1));
    expect(
      report.cases.skip(1).every(
            (result) => result.status == AiAcceptanceCaseStatus.skipped,
          ),
      isTrue,
    );
    expect(report.estimatedCostUsd, isNull);
    final persisted = jsonEncode(report.toJson());
    expect(persisted, isNot(contains('must-not-persist')));
    expect(persisted, isNot(contains('api_key')));
  });

  test('formal calls reject a configuration without a passing report',
      () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'candidate-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'): 'responses',
    });
    final credentials = _MemoryCredentialStore()..values['custom'] = 'test-key';
    final transport = _RecordingTransport();
    final service = OpenAIService(
      credentialStore: credentials,
      acceptanceStore: _MemoryAcceptanceStore(),
      transport: transport,
      enforceModelAcceptance: true,
    );

    try {
      await service.chatCompletion(systemPrompt: 'system', userContent: 'user');
      fail('Expected the acceptance gate to reject the model.');
    } on AiProviderException catch (error) {
      expect(error.kind, AiProviderFailureKind.modelNotAccepted);
      expect(transport.calls, 0);
    }
  });

  test('stalled provider times out and persists an actionable report',
      () async {
    final store = _MemoryAcceptanceStore();
    final configuration = AiModelConfiguration(
      providerId: 'custom',
      baseUrl: 'https://slow.example/v1',
      model: 'slow-model',
      protocol: AiApiProtocol.chatCompletions,
    );

    final report = await AiModelAcceptanceRunner(
      client: _NeverCompletesClient(),
      store: store,
      caseTimeout: const Duration(milliseconds: 10),
      runTimeout: const Duration(milliseconds: 50),
    ).run(configuration);

    expect(report.passed, isFalse);
    expect(report.blockingFailure, AiProviderFailureKind.timeout);
    expect(report.cases.first.status, AiAcceptanceCaseStatus.failed);
    expect(report.cases.first.detail, contains('请求超时'));
    expect(report.cases.first.detail, contains('迟到响应不计为通过'));
    expect(report.cases.first.latencyMs, greaterThanOrEqualTo(1));
    expect(
      report.cases.skip(1).every(
            (result) => result.status == AiAcceptanceCaseStatus.skipped,
          ),
      isTrue,
    );
    expect(
      (await store.latestFor(configuration))?.blockingFailure,
      AiProviderFailureKind.timeout,
    );
  });
}

class _QueuedCompletionClient implements AiCompletionClient {
  final List<String> outputs;
  int calls = 0;

  _QueuedCompletionClient(this.outputs);

  @override
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  }) async {
    final output = outputs[calls++];
    return AiCompletionResult(
      text: output,
      requestedModel: 'gpt-5.6-terra',
      resolvedModel: 'gpt-5.6-terra-2026-07-01',
      protocol: AiApiProtocol.responses,
      latency: const Duration(milliseconds: 50),
      usage: const AiTokenUsage(
        inputTokens: 100,
        outputTokens: 50,
        totalTokens: 150,
      ),
    );
  }
}

class _DelayedCompletionClient implements AiCompletionClient {
  int calls = 0;

  @override
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  }) async {
    final call = calls++;
    if (call == 2) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final outputs = <String>[
      '{"topic":"binary_search","requires_sorted_input":true,'
          '"complexity":"O(log n)"}',
      '{"title":"山窗读雨","lines":["雨洗青山书气新",'
          '"松风翻页入窗频","石径归来寻字句","云开一卷见精神"]}',
      jsonEncode({
        'language': 'dart',
        'code': 'int sumEven(List<int> values) => values'
            '.where((value) => value.isEven).fold(0, (sum, value) => sum + value);',
        'examples': [
          {
            'input': [1, 2, 3, 4],
            'output': 6
          },
          {
            'input': [-2, 3, 10],
            'output': 8
          },
        ],
      }),
      jsonEncode({
        'status': 'answered',
        'claims': [
          {
            'text': '输入必须有序',
            'citation_id': 'S1',
            'quote': '二分查找要求输入序列已经按比较规则有序。',
          },
        ],
      }),
      '{"status":"refused","claims":[]}',
    ];
    return AiCompletionResult(
      text: outputs[call],
      requestedModel: 'reasoning-model',
      resolvedModel: 'reasoning-model',
      protocol: AiApiProtocol.responses,
      latency: const Duration(milliseconds: 1),
    );
  }
}

class _BlockedCompletionClient implements AiCompletionClient {
  @override
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    throw const AiProviderException(
      statusCode: 403,
      code: 'channel:client_restricted',
      message: 'Current client is not allowed.',
    );
  }
}

class _NeverCompletesClient implements AiCompletionClient {
  @override
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  }) {
    return Completer<AiCompletionResult>().future;
  }
}

class _MemoryAcceptanceStore implements AiModelAcceptanceStore {
  final List<AiModelAcceptanceReport> reports = [];

  @override
  Future<bool> isAccepted(AiModelConfiguration configuration) async {
    return (await latestFor(configuration))?.passed == true;
  }

  @override
  Future<AiModelAcceptanceReport?> latestFor(
    AiModelConfiguration configuration,
  ) async {
    for (final report in reports) {
      if (report.configuration.signature == configuration.signature) {
        return report;
      }
    }
    return null;
  }

  @override
  Future<List<AiModelAcceptanceReport>> readAll() async => List.of(reports);

  @override
  Future<void> save(AiModelAcceptanceReport report) async {
    reports.removeWhere((item) =>
        item.configuration.signature == report.configuration.signature);
    reports.insert(0, report);
  }
}

class _MemoryCredentialStore implements AiApiCredentialStore {
  final Map<String, String> values = {};

  @override
  Future<void> deleteApiKey(String providerId) async {
    values.remove(providerId);
  }

  @override
  Future<String?> readApiKey(String providerId) async => values[providerId];

  @override
  Future<void> writeApiKey(String providerId, String apiKey) async {
    values[providerId] = apiKey;
  }
}

class _RecordingTransport implements AiHttpTransport {
  int calls = 0;

  @override
  Future<AiHttpResponse> post({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    calls++;
    return const AiHttpResponse(
      statusCode: 200,
      data: {'output_text': 'unused'},
    );
  }
}
