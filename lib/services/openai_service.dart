import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/ai_api_credential_store.dart';
import 'ai/ai_api_protocol.dart';
import 'ai/ai_completion_result.dart';
import 'ai/ai_model_acceptance.dart';
import 'ai/ai_provider_diagnostics.dart';

/// AI 厂商预设
class AIProviderPreset {
  final String id;
  final String name;
  final String baseUrl;
  final List<String> models;
  final List<AiApiProtocol> protocols;
  final AiApiProtocol defaultProtocol;
  final String keyHelpUrl;
  final String keyHint;

  const AIProviderPreset({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.models,
    this.protocols = const [AiApiProtocol.chatCompletions],
    this.defaultProtocol = AiApiProtocol.chatCompletions,
    required this.keyHelpUrl,
    required this.keyHint,
  });
}

/// 内置 AI 厂商列表
class AIProviders {
  static const String grokPrimaryId = 'custom_grok_primary';
  static const String mimoFallbackId = 'custom_mimo_fallback';

  static const List<AIProviderPreset> builtin = [
    AIProviderPreset(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      models: [
        'gpt-5.6-terra',
        'gpt-5.6-sol',
        'gpt-5.6-luna',
        'gpt-5.5',
      ],
      protocols: [
        AiApiProtocol.responses,
        AiApiProtocol.chatCompletions,
      ],
      defaultProtocol: AiApiProtocol.responses,
      keyHelpUrl: 'https://platform.openai.com/api-keys',
      keyHint: 'sk-...',
    ),
    AIProviderPreset(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      models: ['deepseek-chat', 'deepseek-reasoner'],
      keyHelpUrl: 'https://platform.deepseek.com/api_keys',
      keyHint: 'sk-...',
    ),
    AIProviderPreset(
      id: 'qwen',
      name: '通义千问 (百炼)',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      models: ['qwen-turbo', 'qwen-plus', 'qwen-max'],
      keyHelpUrl: 'https://bailian.console.aliyun.com/?apiKey=1',
      keyHint: 'sk-...',
    ),
    AIProviderPreset(
      id: 'moonshot',
      name: '月之暗面 (Kimi)',
      baseUrl: 'https://api.moonshot.cn/v1',
      models: ['moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'],
      keyHelpUrl: 'https://platform.moonshot.cn/console/api-keys',
      keyHint: 'sk-...',
    ),
    AIProviderPreset(
      id: 'zhipu',
      name: '智谱 AI',
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      models: ['glm-4-flash', 'glm-4-air', 'glm-4-plus', 'glm-4v-plus'],
      keyHelpUrl: 'https://open.bigmodel.cn/usercenter/apikeys',
      keyHint: '...',
    ),
    AIProviderPreset(
      id: 'gemini',
      name: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      models: ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'],
      keyHelpUrl: 'https://aistudio.google.com/apikey',
      keyHint: 'AIza...',
    ),
    AIProviderPreset(
      id: grokPrimaryId,
      name: 'Grok 4.5 通道（主）',
      baseUrl: '',
      models: [],
      protocols: [
        AiApiProtocol.responses,
        AiApiProtocol.chatCompletions,
      ],
      defaultProtocol: AiApiProtocol.responses,
      keyHelpUrl: '',
      keyHint: '',
    ),
    AIProviderPreset(
      id: mimoFallbackId,
      name: 'Mimo 通道（备）',
      baseUrl: '',
      models: [],
      protocols: [
        AiApiProtocol.responses,
        AiApiProtocol.chatCompletions,
      ],
      defaultProtocol: AiApiProtocol.responses,
      keyHelpUrl: '',
      keyHint: '',
    ),
    AIProviderPreset(
      id: 'custom',
      name: '自定义',
      baseUrl: '',
      models: [],
      protocols: [
        AiApiProtocol.responses,
        AiApiProtocol.chatCompletions,
      ],
      keyHelpUrl: '',
      keyHint: '',
    ),
  ];

  static AIProviderPreset? getById(String id) {
    for (final p in builtin) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class AiHttpResponse {
  final int? statusCode;
  final dynamic data;

  const AiHttpResponse({required this.statusCode, required this.data});
}

abstract class AiHttpTransport {
  Future<AiHttpResponse> post({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  });
}

class DioAiHttpTransport implements AiHttpTransport {
  /// Some reasoning models need longer than a conventional HTTP request to
  /// produce a complete, non-streaming JSON response.
  static const Duration defaultReceiveTimeout = Duration(minutes: 5);

  final Dio _dio;

  DioAiHttpTransport({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: defaultReceiveTimeout,
              ),
            );

  @override
  Future<AiHttpResponse> post({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
        ),
        data: jsonEncode(body),
      );
      return AiHttpResponse(
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (error) {
      return AiHttpResponse(
        statusCode: error.response?.statusCode,
        data: error.response?.data ??
            {
              'error': {
                'code': error.type == DioExceptionType.connectionTimeout ||
                        error.type == DioExceptionType.receiveTimeout ||
                        error.type == DioExceptionType.sendTimeout
                    ? 'timeout'
                    : 'network_error',
                'message': error.message ?? 'Network request failed.',
              },
            },
      );
    }
  }
}

class AiProviderException implements AiProviderDiagnostic {
  final int? statusCode;
  final String? code;
  @override
  final String message;

  const AiProviderException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  AiProviderFailureKind get kind => classifyAiProviderFailure(
        statusCode: statusCode,
        code: code,
        message: message,
      );

  bool get requiresCredentialReview => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class _ProviderResponseError {
  final String? code;
  final String message;

  const _ProviderResponseError({required this.code, required this.message});
}

Future<SharedPreferences> _defaultPreferencesLoader() {
  return SharedPreferences.getInstance();
}

/// AI 服务（兼容 OpenAI 接口格式）
class OpenAIService implements AiCompletionClient {
  static const String profilePreferencePrefix = 'ai_profile.';
  static const String _providerIdKey = 'ai_provider_id';

  final AiHttpTransport _transport;
  final AiApiCredentialStore _credentialStore;
  final AiModelAcceptanceStore _acceptanceStore;
  final Future<SharedPreferences> Function() _preferencesLoader;
  final bool _enforceModelAcceptance;

  OpenAIService({
    AiHttpTransport? transport,
    AiApiCredentialStore? credentialStore,
    AiModelAcceptanceStore? acceptanceStore,
    Future<SharedPreferences> Function()? preferencesLoader,
    bool enforceModelAcceptance = false,
  })  : _transport = transport ?? DioAiHttpTransport(),
        _credentialStore =
            credentialStore ?? const SecureAiApiCredentialStore(),
        _acceptanceStore =
            acceptanceStore ?? SharedPreferencesAiModelAcceptanceStore(),
        _preferencesLoader = preferencesLoader ?? _defaultPreferencesLoader,
        _enforceModelAcceptance = enforceModelAcceptance;

  Future<String?> getApiKey({String? providerId}) async {
    final resolvedProviderId = providerId ?? await getProviderId();
    return _credentialStore.readApiKey(resolvedProviderId);
  }

  Future<void> setApiKey(String key, {String? providerId}) async {
    final resolvedProviderId = providerId ?? await getProviderId();
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _credentialStore.deleteApiKey(resolvedProviderId);
    } else {
      await _credentialStore.writeApiKey(resolvedProviderId, trimmed);
    }
  }

  Future<void> clearApiKey({String? providerId}) async {
    final resolvedProviderId = providerId ?? await getProviderId();
    await _credentialStore.deleteApiKey(resolvedProviderId);
  }

  static String profilePreferenceKey(String providerId, String field) {
    final normalized = providerId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return '$profilePreferencePrefix${normalized.isEmpty ? 'custom' : normalized}.$field';
  }

  Future<String> getModel() async {
    return getModelForProvider(await getProviderId());
  }

  Future<String> getModelForProvider(String providerId) async {
    final stored = await _readProfileValue(
      providerId: providerId,
      field: 'model',
    );
    if (stored != null) return stored;
    final provider = AIProviders.getById(providerId);
    if (provider != null && provider.models.isNotEmpty) {
      return provider.models.first;
    }
    return providerId == 'custom' ? 'gpt-5.6-terra' : '';
  }

  Future<void> setModel(String model) async {
    await setModelForProvider(await getProviderId(), model);
  }

  Future<void> setModelForProvider(String providerId, String model) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(
      profilePreferenceKey(providerId, 'model'),
      model.trim(),
    );
  }

  Future<String> getBaseUrl() async {
    return getBaseUrlForProvider(await getProviderId());
  }

  Future<String> getBaseUrlForProvider(String providerId) async {
    final stored = await _readProfileValue(
      providerId: providerId,
      field: 'base_url',
    );
    if (stored != null) return stored;
    final provider = AIProviders.getById(providerId);
    return provider?.baseUrl ?? 'https://api.openai.com/v1';
  }

  Future<void> setBaseUrl(String url) async {
    await setBaseUrlForProvider(await getProviderId(), url);
  }

  Future<void> setBaseUrlForProvider(String providerId, String url) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(
      profilePreferenceKey(providerId, 'base_url'),
      url.trim(),
    );
  }

  Future<String> getProviderId() async {
    final prefs = await _preferencesLoader();
    return prefs.getString(_providerIdKey) ?? 'openai';
  }

  Future<void> setProviderId(String id) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(_providerIdKey, id);
  }

  Future<AiApiProtocol> getApiProtocol() async {
    return getApiProtocolForProvider(await getProviderId());
  }

  Future<AiApiProtocol> getApiProtocolForProvider(String providerId) async {
    final stored = await _readProfileValue(
      providerId: providerId,
      field: 'protocol',
    );
    if (stored != null) return AiApiProtocol.fromString(stored);
    final provider = AIProviders.getById(providerId);
    return provider?.defaultProtocol ?? AiApiProtocol.chatCompletions;
  }

  Future<void> setApiProtocol(AiApiProtocol protocol) async {
    await setApiProtocolForProvider(await getProviderId(), protocol);
  }

  Future<void> setApiProtocolForProvider(
    String providerId,
    AiApiProtocol protocol,
  ) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(
      profilePreferenceKey(providerId, 'protocol'),
      protocol.value,
    );
  }

  Future<String?> _readProfileValue({
    required String providerId,
    required String field,
  }) async {
    final prefs = await _preferencesLoader();
    final profileKey = profilePreferenceKey(providerId, field);
    return prefs.getString(profileKey);
  }

  Future<bool> hasApiKey({String? providerId}) async {
    final key = await getApiKey(providerId: providerId);
    return key != null && key.isNotEmpty;
  }

  /// 调用配置的 OpenAI-compatible 文本生成协议。
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    final result = await generateCompletion(
      systemPrompt: systemPrompt,
      userContent: userContent,
      imageBase64: imageBase64,
      temperature: temperature,
    );
    return result.text;
  }

  @override
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiProviderException(
        code: 'missing_api_key',
        message: '未设置 API Key，请先在设置中配置',
      );
    }

    final model = await getModel();
    final baseUrl =
        (await getBaseUrl()).trim().replaceFirst(RegExp(r'/+$'), '');
    final protocol = await getApiProtocol();
    final providerId = await getProviderId();
    final configuration = AiModelConfiguration(
      providerId: providerId,
      baseUrl: baseUrl,
      model: model,
      protocol: protocol,
    );
    if (_enforceModelAcceptance && !bypassAcceptanceGate) {
      final accepted = await _acceptanceStore.isAccepted(configuration);
      if (!accepted) {
        throw const AiProviderException(
          code: 'model_not_accepted',
          message: '当前供应商、模型和协议组合尚未通过固定能力验收',
        );
      }
    }

    final stopwatch = Stopwatch()..start();
    final response = await _transport.post(
      url: '$baseUrl/${protocol.endpoint}',
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: protocol == AiApiProtocol.responses
          ? _responsesRequest(
              model: model,
              systemPrompt: systemPrompt,
              userContent: userContent,
              imageBase64: imageBase64,
              maxOutputTokens: bypassAcceptanceGate ? 2048 : 4096,
            )
          : _chatCompletionsRequest(
              model: model,
              systemPrompt: systemPrompt,
              userContent: userContent,
              imageBase64: imageBase64,
              temperature: temperature,
              maxTokens: bypassAcceptanceGate ? 2048 : 4096,
            ),
    );
    stopwatch.stop();

    final statusCode = response.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw _providerException(response);
    }

    final data = _responseEnvelope(_asMap(response.data));
    final providerError = _responseError(data);
    if (providerError != null) {
      throw AiProviderException(
        statusCode: statusCode,
        code: providerError.code,
        message: providerError.message,
      );
    }
    final content = protocol == AiApiProtocol.responses
        ? _responsesOutputText(data)
        : _chatCompletionsOutputText(data);
    final normalizedContent = content.trim().isNotEmpty
        ? content
        : _streamText(response.data, protocol);
    if (normalizedContent.trim().isEmpty) {
      throw const AiProviderException(
        code: 'empty_response',
        message: 'API 返回空结果或不兼容的响应结构',
      );
    }
    return AiCompletionResult(
      text: normalizedContent,
      requestedModel: model,
      resolvedModel: data['model']?.toString(),
      protocol: protocol,
      latency: stopwatch.elapsed,
      usage: _tokenUsage(data, protocol),
    );
  }

  Map<String, dynamic> _chatCompletionsRequest({
    required String model,
    required String systemPrompt,
    required String userContent,
    required String? imageBase64,
    required double? temperature,
    required int maxTokens,
  }) {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      if (imageBase64 == null)
        {'role': 'user', 'content': userContent}
      else
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userContent},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
            },
          ],
        },
    ];
    return {
      'model': model,
      'messages': messages,
      'temperature': temperature ?? 0.7,
      'max_tokens': maxTokens,
      // Keep compatible relays from switching the client into SSE mode.
      'stream': false,
    };
  }

  Map<String, dynamic> _responsesRequest({
    required String model,
    required String systemPrompt,
    required String userContent,
    required String? imageBase64,
    required int maxOutputTokens,
  }) {
    return {
      'model': model,
      'input': [
        {
          'role': 'system',
          'content': [
            {'type': 'input_text', 'text': systemPrompt},
          ],
        },
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': userContent},
            if (imageBase64 != null)
              {
                'type': 'input_image',
                'image_url': 'data:image/jpeg;base64,$imageBase64',
              },
          ],
        },
      ],
      'max_output_tokens': maxOutputTokens,
      'store': false,
      // The app consumes one complete JSON response rather than a stream.
      'stream': false,
    };
  }

  String _chatCompletionsOutputText(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      return _textFromValue(data['text']);
    }
    final choice = Map<String, dynamic>.from(choices.first as Map);
    final message = choice['message'];
    if (message is Map) {
      final content = _textFromValue(message['content']);
      if (content.isNotEmpty) return content;
    }
    final delta = _textFromValue(choice['delta']);
    if (delta.isNotEmpty) return delta;
    return _textFromValue(choice['text']);
  }

  String _responsesOutputText(Map<String, dynamic> data) {
    final direct = data['output_text'];
    final directText = _textFromValue(direct);
    if (directText.trim().isNotEmpty) return directText;
    final output = data['output'];
    final outputText = _textFromValue(output);
    if (outputText.isNotEmpty) return outputText;
    final deltaText = _textFromValue(data['delta']);
    if (deltaText.isNotEmpty) return deltaText;
    return _textFromValue(data['text']);
  }

  Map<String, dynamic> _responseEnvelope(Map<String, dynamic> data) {
    final nested = data['data'];
    if (nested is! Map ||
        data.containsKey('choices') ||
        data.containsKey('output') ||
        data.containsKey('output_text') ||
        (data.containsKey('error') && data['error'] != null)) {
      return data;
    }
    final unwrapped = Map<String, dynamic>.from(nested);
    // Preserve relay-level metadata used for diagnostics and token accounting.
    for (final key in const ['model', 'usage', 'id']) {
      if (!unwrapped.containsKey(key) && data.containsKey(key)) {
        unwrapped[key] = data[key];
      }
    }
    return unwrapped;
  }

  _ProviderResponseError? _responseError(Map<String, dynamic> data) {
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) {
      return _ProviderResponseError(code: null, message: error.trim());
    }
    if (error is Map) {
      final errorMap = Map<String, dynamic>.from(error);
      final message = errorMap['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return _ProviderResponseError(
          code: errorMap['code']?.toString(),
          message: message,
        );
      }
    }
    return null;
  }

  String _streamText(dynamic raw, AiApiProtocol protocol) {
    if (raw is! String || !raw.contains('data:')) return '';
    final texts = <String>[];
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring('data:'.length).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map) continue;
        final data = _responseEnvelope(Map<String, dynamic>.from(decoded));
        final text = protocol == AiApiProtocol.responses
            ? _responsesOutputText(data)
            : _chatCompletionsOutputText(data);
        if (text.isNotEmpty) texts.add(text);
      } catch (_) {
        // Ignore keep-alive/comment lines and malformed partial events.
      }
    }
    return texts.join();
  }

  String _textFromValue(dynamic value) {
    if (value is String) return value;
    if (value is List) {
      return value
          .map(_textFromValue)
          .where((text) => text.isNotEmpty)
          .join('\n');
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in const ['text', 'value', 'content', 'delta']) {
        final text = _textFromValue(map[key]);
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  AiTokenUsage _tokenUsage(
    Map<String, dynamic> data,
    AiApiProtocol protocol,
  ) {
    final usage = data['usage'];
    if (usage is! Map) return const AiTokenUsage();
    int? read(String key) {
      final value = usage[key];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    }

    return AiTokenUsage(
      inputTokens: read(
        protocol == AiApiProtocol.responses ? 'input_tokens' : 'prompt_tokens',
      ),
      outputTokens: read(
        protocol == AiApiProtocol.responses
            ? 'output_tokens'
            : 'completion_tokens',
      ),
      totalTokens: read('total_tokens'),
    );
  }

  AiProviderException _providerException(AiHttpResponse response) {
    final data = _asMap(response.data);
    final error = data['error'];
    final errorMap = error is Map ? Map<String, dynamic>.from(error) : data;
    final code = errorMap['code']?.toString();
    final providerMessage = errorMap['message']?.toString().trim();
    final statusCode = response.statusCode;
    final message = providerMessage == null || providerMessage.isEmpty
        ? 'API 请求失败: ${statusCode ?? 'unknown'}'
        : providerMessage;
    return AiProviderException(
      statusCode: statusCode,
      code: code,
      message: message,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return {'message': value};
      }
    }
    return const {};
  }

  /// AI 判断填空题答案是否正确
  ///
  /// 当用户答案与标准答案不完全匹配时，调用大模型判断语义是否等价。
  /// 返回 true 表示正确，false 表示错误。
  Future<bool> judgeFillBlankAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
  }) async {
    final systemPrompt = '你是一个判题助手。你的任务是判断用户的填空题答案是否与标准答案在语义上等价。'
        '允许的情况包括但不限于：同义词、近义词、不同的表述方式、大小写差异、标点差异、简称与全称。'
        '你只需要回答 JSON 格式：{"correct": true} 或 {"correct": false}，不要输出其他内容。';

    final userContent = '题目：$question\n'
        '标准答案：$correctAnswer\n'
        '用户答案：$userAnswer\n'
        '请判断用户答案是否正确。';

    try {
      final result = await chatCompletion(
        systemPrompt: systemPrompt,
        userContent: userContent,
        temperature: 0.0,
      );

      // 解析 JSON 结果
      final cleaned = result.trim();
      // 尝试提取 JSON
      final jsonMatch = RegExp(r'\{[^}]*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return json['correct'] == true;
      }
      // 如果不是 JSON，尝试直接匹配 true/false
      return cleaned.toLowerCase().contains('true');
    } catch (e) {
      // AI 判题失败时，回退到不通过
      return false;
    }
  }
}
