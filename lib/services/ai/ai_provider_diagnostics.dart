enum AiProviderFailureKind {
  missingCredential,
  invalidCredential,
  clientRestricted,
  forbidden,
  modelNotAccepted,
  modelUnsupported,
  protocolUnsupported,
  rateLimited,
  timeout,
  unavailable,
  malformedResponse,
  network,
  unknown,
}

extension AiProviderFailureKindDetails on AiProviderFailureKind {
  String get label {
    switch (this) {
      case AiProviderFailureKind.missingCredential:
        return '未配置 API Key';
      case AiProviderFailureKind.invalidCredential:
        return 'API Key 无效';
      case AiProviderFailureKind.clientRestricted:
        return '网关限制当前 App 客户端';
      case AiProviderFailureKind.forbidden:
        return '网关拒绝访问';
      case AiProviderFailureKind.modelNotAccepted:
        return '模型尚未通过验收';
      case AiProviderFailureKind.modelUnsupported:
        return '模型不受支持';
      case AiProviderFailureKind.protocolUnsupported:
        return '协议不受支持';
      case AiProviderFailureKind.rateLimited:
        return '请求频率或额度受限';
      case AiProviderFailureKind.timeout:
        return '请求超时';
      case AiProviderFailureKind.unavailable:
        return '上游模型暂不可用';
      case AiProviderFailureKind.malformedResponse:
        return '响应格式无效';
      case AiProviderFailureKind.network:
        return '网络连接失败';
      case AiProviderFailureKind.unknown:
        return '未知供应商错误';
    }
  }

  String get action {
    switch (this) {
      case AiProviderFailureKind.clientRestricted:
        return '请让网关开放 Dart/Dio 客户端；不要伪装其他客户端绕过限制。';
      case AiProviderFailureKind.modelNotAccepted:
        return '请先在设置中运行固定模型验收。';
      case AiProviderFailureKind.modelUnsupported:
        return '请从网关模型列表选择可用模型后重新验收。';
      case AiProviderFailureKind.protocolUnsupported:
        return '请切换 Chat Completions 或 Responses 后重新验收。';
      case AiProviderFailureKind.missingCredential:
      case AiProviderFailureKind.invalidCredential:
      case AiProviderFailureKind.forbidden:
        return '请检查该供应商对应的 API Key 和访问权限。';
      case AiProviderFailureKind.rateLimited:
        return '请等待额度恢复，或使用另一个开发模型。';
      case AiProviderFailureKind.timeout:
      case AiProviderFailureKind.unavailable:
      case AiProviderFailureKind.network:
        return '请稍后重试，并检查网络和上游服务状态。';
      case AiProviderFailureKind.malformedResponse:
        return '该网关返回了不兼容的响应结构，请检查协议实现。';
      case AiProviderFailureKind.unknown:
        return '请保留错误码并联系供应商排查。';
    }
  }
}

AiProviderFailureKind classifyAiProviderFailure({
  int? statusCode,
  String? code,
  required String message,
}) {
  final normalizedCode = code?.trim().toLowerCase() ?? '';
  final normalizedMessage = message.trim().toLowerCase();
  final combined = '$normalizedCode $normalizedMessage';

  if (combined.contains('missing_api_key')) {
    return AiProviderFailureKind.missingCredential;
  }
  if (combined.contains('model_not_accepted')) {
    return AiProviderFailureKind.modelNotAccepted;
  }
  if (combined.contains('client_restricted')) {
    return AiProviderFailureKind.clientRestricted;
  }
  if (combined.contains('model_not_found') ||
      combined.contains('unsupported_model') ||
      combined.contains('model unsupported') ||
      combined.contains('does not support this model')) {
    return AiProviderFailureKind.modelUnsupported;
  }
  if (combined.contains('unsupported_protocol') ||
      combined.contains('unsupported endpoint') ||
      combined.contains('method not allowed')) {
    return AiProviderFailureKind.protocolUnsupported;
  }
  if (combined.contains('timeout') || statusCode == 408) {
    return AiProviderFailureKind.timeout;
  }
  if (combined.contains('malformed_response') ||
      combined.contains('empty_response')) {
    return AiProviderFailureKind.malformedResponse;
  }
  if (combined.contains('network_error')) {
    return AiProviderFailureKind.network;
  }
  if (statusCode == 401) return AiProviderFailureKind.invalidCredential;
  if (statusCode == 403) return AiProviderFailureKind.forbidden;
  if (statusCode == 404) {
    return combined.contains('model')
        ? AiProviderFailureKind.modelUnsupported
        : AiProviderFailureKind.protocolUnsupported;
  }
  if (statusCode == 405) return AiProviderFailureKind.protocolUnsupported;
  if (statusCode == 429) return AiProviderFailureKind.rateLimited;
  if (statusCode != null && statusCode >= 500) {
    return AiProviderFailureKind.unavailable;
  }
  if (statusCode == null) return AiProviderFailureKind.network;
  return AiProviderFailureKind.unknown;
}
