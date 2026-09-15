import 'package:anchor_learning/services/ai/ai_api_credential_store.dart';
import 'package:anchor_learning/services/ai/ai_api_protocol.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lists Grok as the primary named channel before Mimo fallback', () {
    final grokIndex = AIProviders.builtin.indexWhere(
      (provider) => provider.id == AIProviders.grokPrimaryId,
    );
    final mimoIndex = AIProviders.builtin.indexWhere(
      (provider) => provider.id == AIProviders.mimoFallbackId,
    );

    expect(grokIndex, greaterThanOrEqualTo(0));
    expect(mimoIndex, greaterThan(grokIndex));
    expect(
      AIProviders.getById(AIProviders.grokPrimaryId)?.defaultProtocol,
      AiApiProtocol.responses,
    );
    expect(
      AIProviders.getById(AIProviders.mimoFallbackId)?.defaultProtocol,
      AiApiProtocol.responses,
    );
  });

  test('keeps Grok and Mimo profile configuration and credentials isolated',
      () async {
    SharedPreferences.setMockInitialValues({});
    final credentials = _MemoryCredentialStore();
    final service = OpenAIService(credentialStore: credentials);

    await service.setBaseUrlForProvider(
      AIProviders.grokPrimaryId,
      'https://grok-profile.example/v1',
    );
    await service.setModelForProvider(
      AIProviders.grokPrimaryId,
      'grok-profile-model',
    );
    await service.setApiProtocolForProvider(
      AIProviders.grokPrimaryId,
      AiApiProtocol.responses,
    );
    await service.setApiKey(
      'grok-secure-key',
      providerId: AIProviders.grokPrimaryId,
    );

    await service.setBaseUrlForProvider(
      AIProviders.mimoFallbackId,
      'https://mimo-profile.example/v1',
    );
    await service.setModelForProvider(
      AIProviders.mimoFallbackId,
      'mimo-profile-model',
    );
    await service.setApiProtocolForProvider(
      AIProviders.mimoFallbackId,
      AiApiProtocol.chatCompletions,
    );
    await service.setApiKey(
      'mimo-secure-key',
      providerId: AIProviders.mimoFallbackId,
    );

    expect(
      await service.getBaseUrlForProvider(AIProviders.grokPrimaryId),
      'https://grok-profile.example/v1',
    );
    expect(
      await service.getModelForProvider(AIProviders.grokPrimaryId),
      'grok-profile-model',
    );
    expect(
      await service.getApiProtocolForProvider(AIProviders.grokPrimaryId),
      AiApiProtocol.responses,
    );
    expect(
      await service.getBaseUrlForProvider(AIProviders.mimoFallbackId),
      'https://mimo-profile.example/v1',
    );
    expect(
      await service.getModelForProvider(AIProviders.mimoFallbackId),
      'mimo-profile-model',
    );
    expect(
      await service.getApiProtocolForProvider(AIProviders.mimoFallbackId),
      AiApiProtocol.chatCompletions,
    );
    expect(credentials.values, {
      AIProviders.grokPrimaryId: 'grok-secure-key',
      AIProviders.mimoFallbackId: 'mimo-secure-key',
    });
  });

  test('stores and clears credentials without writing SharedPreferences',
      () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
    });
    final credentials = _MemoryCredentialStore();
    final service = OpenAIService(credentialStore: credentials);

    await service.setApiKey(' secure-key ');
    expect(credentials.values['custom'], 'secure-key');

    await service.clearApiKey();
    expect(credentials.values, isEmpty);
    expect(await service.hasApiKey(), isFalse);
  });

  test('routes the task interface through Responses API and extracts text',
      () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'responses-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1/',
      OpenAIService.profilePreferenceKey('custom', 'protocol'): 'responses',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final transport = _RecordingTransport(
      const AiHttpResponse(
        statusCode: 200,
        data: {
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'output_text', 'text': 'responses result'},
              ],
            },
          ],
        },
      ),
    );
    final service = OpenAIService(
      credentialStore: credentials,
      transport: transport,
    );

    final output = await service.chatCompletion(
      systemPrompt: 'system',
      userContent: 'user',
      temperature: 0,
    );

    expect(output, 'responses result');
    expect(transport.url, 'https://provider.example/v1/responses');
    expect(transport.body['model'], 'responses-model');
    expect(transport.body['max_output_tokens'], 4096);
    expect(transport.body['store'], isFalse);
    expect(transport.body['stream'], isFalse);
    expect(transport.body, isNot(contains('temperature')));
    final input = transport.body['input'] as List<dynamic>;
    expect((input.first as Map)['role'], 'system');
    expect((input.last as Map)['role'], 'user');
  });

  test('keeps Chat Completions request and response compatibility', () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'chat-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'):
          'chat_completions',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final transport = _RecordingTransport(
      const AiHttpResponse(
        statusCode: 200,
        data: {
          'choices': [
            {
              'message': {'content': 'chat result'},
            },
          ],
        },
      ),
    );
    final service = OpenAIService(
      credentialStore: credentials,
      transport: transport,
    );

    final output = await service.chatCompletion(
      systemPrompt: 'system',
      userContent: 'user',
      temperature: 0.2,
    );

    expect(output, 'chat result');
    expect(transport.url, 'https://provider.example/v1/chat/completions');
    expect(transport.body['temperature'], 0.2);
    expect(transport.body['max_tokens'], 4096);
    expect(transport.body['stream'], isFalse);
    expect(transport.body, isNot(contains('input')));
  });

  test('uses the acceptance output budget for Responses requests', () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'responses-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'): 'responses',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final transport = _RecordingTransport(
      const AiHttpResponse(
        statusCode: 200,
        data: {
          'output_text': 'acceptance result',
        },
      ),
    );
    final service = OpenAIService(
      credentialStore: credentials,
      transport: transport,
    );

    final result = await service.generateCompletion(
      systemPrompt: 'system',
      userContent: 'user',
      bypassAcceptanceGate: true,
    );

    expect(result.text, 'acceptance result');
    expect(transport.body['max_output_tokens'], 2048);
  });

  test('uses the acceptance output budget for Chat Completions requests',
      () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'chat-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'):
          'chat_completions',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final transport = _RecordingTransport(
      const AiHttpResponse(
        statusCode: 200,
        data: {
          'choices': [
            {
              'message': {'content': 'acceptance result'},
            },
          ],
        },
      ),
    );
    final service = OpenAIService(
      credentialStore: credentials,
      transport: transport,
    );

    final result = await service.generateCompletion(
      systemPrompt: 'system',
      userContent: 'user',
      bypassAcceptanceGate: true,
    );

    expect(result.text, 'acceptance result');
    expect(transport.body['max_tokens'], 2048);
  });

  test('unwraps relay envelopes and nested Chat message text', () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'chat-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'):
          'chat_completions',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final transport = _RecordingTransport(
      const AiHttpResponse(
        statusCode: 200,
        data: {
          'data': {
            'choices': [
              {
                'message': {
                  'content': [
                    {
                      'type': 'text',
                      'text': {'value': 'wrapped result'},
                    },
                  ],
                },
              },
            ],
          },
          'model': 'relay-model',
          'usage': {
            'prompt_tokens': 4,
            'completion_tokens': 2,
            'total_tokens': 6,
          },
        },
      ),
    );
    final service = OpenAIService(
      credentialStore: credentials,
      transport: transport,
    );

    expect(
      await service.chatCompletion(systemPrompt: 'system', userContent: 'user'),
      'wrapped result',
    );
  });

  test('joins a complete SSE response when a relay ignores stream false',
      () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'chat-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'):
          'chat_completions',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final transport = _RecordingTransport(
      const AiHttpResponse(
        statusCode: 200,
        data: 'data: {"choices":[{"delta":{"content":"first"}}]}\n\n'
            'data: {"choices":[{"delta":{"content":" second"}}]}\n\n'
            'data: [DONE]\n\n',
      ),
    );
    final service = OpenAIService(
      credentialStore: credentials,
      transport: transport,
    );

    expect(
      await service.chatCompletion(systemPrompt: 'system', userContent: 'user'),
      'first second',
    );
  });

  test('surfaces an error body even when the relay returns HTTP 2xx', () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'chat-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'):
          'chat_completions',
    });
    final service = OpenAIService(
      credentialStore: _MemoryCredentialStore()
        ..values['custom'] = 'secure-key',
      transport: _RecordingTransport(
        const AiHttpResponse(
          statusCode: 200,
          data: {
            'error': {
              'code': 'upstream_timeout',
              'message': 'upstream completed after client deadline',
            },
          },
        ),
      ),
    );

    expect(
      () => service.chatCompletion(systemPrompt: 'system', userContent: 'user'),
      throwsA(
        isA<AiProviderException>()
            .having((error) => error.code, 'code', 'upstream_timeout')
            .having(
              (error) => error.message,
              'message',
              'upstream completed after client deadline',
            ),
      ),
    );
  });

  test('preserves provider error codes for configuration diagnostics',
      () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'restricted-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'): 'responses',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final service = OpenAIService(
      credentialStore: credentials,
      transport: _RecordingTransport(
        const AiHttpResponse(
          statusCode: 403,
          data: {
            'error': {
              'code': 'channel:client_restricted',
              'message': 'Current client is not allowed.',
            },
          },
        ),
      ),
    );

    try {
      await service.chatCompletion(
        systemPrompt: 'system',
        userContent: 'user',
      );
      fail('Expected an AiProviderException.');
    } on AiProviderException catch (error) {
      expect(error.statusCode, 403);
      expect(error.code, 'channel:client_restricted');
      expect(error.requiresCredentialReview, isTrue);
      expect(error.kind.name, 'clientRestricted');
    }
  });

  test('captures resolved model, latency and Responses token usage', () async {
    SharedPreferences.setMockInitialValues({
      'ai_provider_id': 'custom',
      OpenAIService.profilePreferenceKey('custom', 'model'): 'requested-model',
      OpenAIService.profilePreferenceKey('custom', 'base_url'):
          'https://provider.example/v1',
      OpenAIService.profilePreferenceKey('custom', 'protocol'): 'responses',
    });
    final credentials = _MemoryCredentialStore()
      ..values['custom'] = 'secure-key';
    final service = OpenAIService(
      credentialStore: credentials,
      transport: _RecordingTransport(
        const AiHttpResponse(
          statusCode: 200,
          data: {
            'model': 'resolved-model-2026-07-15',
            'output_text': 'measured result',
            'usage': {
              'input_tokens': 31,
              'output_tokens': 7,
              'total_tokens': 38,
            },
          },
        ),
      ),
    );

    final result = await service.generateCompletion(
      systemPrompt: 'system',
      userContent: 'user',
    );

    expect(result.text, 'measured result');
    expect(result.requestedModel, 'requested-model');
    expect(result.resolvedModel, 'resolved-model-2026-07-15');
    expect(result.usage.inputTokens, 31);
    expect(result.usage.outputTokens, 7);
    expect(result.usage.totalTokens, 38);
    expect(result.latency.inMicroseconds, greaterThanOrEqualTo(0));
  });
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
  final AiHttpResponse response;
  String? url;
  Map<String, String> headers = {};
  Map<String, dynamic> body = {};

  _RecordingTransport(this.response);

  @override
  Future<AiHttpResponse> post({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    this.url = url;
    this.headers = headers;
    this.body = body;
    return response;
  }
}
