import 'ai_api_protocol.dart';

class AiTokenUsage {
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;

  const AiTokenUsage({
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
  });

  bool get isEmpty =>
      inputTokens == null && outputTokens == null && totalTokens == null;

  int? get effectiveTotalTokens {
    if (totalTokens != null) return totalTokens;
    if (inputTokens == null && outputTokens == null) return null;
    return (inputTokens ?? 0) + (outputTokens ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'total_tokens': totalTokens,
    };
  }

  factory AiTokenUsage.fromJson(Map<String, dynamic> json) {
    return AiTokenUsage(
      inputTokens: _asInt(json['input_tokens']),
      outputTokens: _asInt(json['output_tokens']),
      totalTokens: _asInt(json['total_tokens']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class AiCompletionResult {
  final String text;
  final String requestedModel;
  final String? resolvedModel;
  final AiApiProtocol protocol;
  final Duration latency;
  final AiTokenUsage usage;

  const AiCompletionResult({
    required this.text,
    required this.requestedModel,
    required this.protocol,
    required this.latency,
    this.resolvedModel,
    this.usage = const AiTokenUsage(),
  });
}

abstract class AiCompletionClient {
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  });
}
