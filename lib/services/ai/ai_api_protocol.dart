enum AiApiProtocol {
  chatCompletions(
    value: 'chat_completions',
    label: 'Chat Completions',
    endpoint: 'chat/completions',
  ),
  responses(
    value: 'responses',
    label: 'Responses',
    endpoint: 'responses',
  );

  final String value;
  final String label;
  final String endpoint;

  const AiApiProtocol({
    required this.value,
    required this.label,
    required this.endpoint,
  });

  static AiApiProtocol fromString(String? value) {
    return AiApiProtocol.values.firstWhere(
      (protocol) => protocol.value == value,
      orElse: () => AiApiProtocol.chatCompletions,
    );
  }
}
