String? normalizeAgentSessionTargetId(String? targetId) {
  final value = targetId?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
