enum AiTaskErrorType {
  validation,
  request,
  parse,
  emptyResult,
  unknown,
}

class AiTaskResult<T> {
  final T? data;
  final String? rawResponse;
  final AiTaskErrorType? errorType;
  final String? errorMessage;

  const AiTaskResult._({
    this.data,
    this.rawResponse,
    this.errorType,
    this.errorMessage,
  });

  bool get isSuccess => errorType == null;

  T get requireData {
    final value = data;
    if (value == null) {
      throw StateError(errorMessage ?? 'AI task did not return data');
    }
    return value;
  }

  factory AiTaskResult.success(T data, {String? rawResponse}) {
    return AiTaskResult._(
      data: data,
      rawResponse: rawResponse,
    );
  }

  factory AiTaskResult.failure({
    required AiTaskErrorType type,
    required String message,
    String? rawResponse,
  }) {
    return AiTaskResult._(
      errorType: type,
      errorMessage: message,
      rawResponse: rawResponse,
    );
  }
}
