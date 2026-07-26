import 'dart:convert';

const _learningAgentToolInputSnapshotVersion = 1;

class LearningAgentToolInputSnapshot {
  final String toolId;
  final String? targetId;
  final String? focusPointId;
  final List<String> evidenceChunkIds;

  LearningAgentToolInputSnapshot._({
    required this.toolId,
    required this.targetId,
    required this.focusPointId,
    required this.evidenceChunkIds,
  });

  factory LearningAgentToolInputSnapshot({
    required String toolId,
    String? targetId,
    String? focusPointId,
    List<String> evidenceChunkIds = const [],
  }) {
    final normalizedToolId = toolId.trim();
    if (normalizedToolId.isEmpty) {
      throw ArgumentError.value(
        toolId,
        'toolId',
        'A tool input snapshot requires a non-empty tool id.',
      );
    }
    return LearningAgentToolInputSnapshot._(
      toolId: normalizedToolId,
      targetId: _normalizedNullable(targetId),
      focusPointId: _normalizedNullable(focusPointId),
      evidenceChunkIds: List.unmodifiable(_normalizedIds(evidenceChunkIds)),
    );
  }

  bool hasSameRoutingInput(LearningAgentToolInputSnapshot other) {
    return toolId == other.toolId &&
        targetId == other.targetId &&
        focusPointId == other.focusPointId &&
        _sameStrings(evidenceChunkIds, other.evidenceChunkIds);
  }

  List<String> mismatchLines(LearningAgentToolInputSnapshot other) {
    return [
      if (toolId != other.toolId) 'tool: $toolId -> ${other.toolId}',
      if (targetId != other.targetId)
        'target: ${targetId ?? 'null'} -> ${other.targetId ?? 'null'}',
      if (focusPointId != other.focusPointId)
        'focus: ${focusPointId ?? 'null'} -> ${other.focusPointId ?? 'null'}',
      if (!_sameStrings(evidenceChunkIds, other.evidenceChunkIds))
        'evidence: ${evidenceChunkIds.join(',')} -> '
            '${other.evidenceChunkIds.join(',')}',
    ];
  }

  String toStorageValue() {
    return jsonEncode({
      'version': _learningAgentToolInputSnapshotVersion,
      'tool_id': toolId,
      'target_id': targetId,
      'focus_point_id': focusPointId,
      'evidence_chunk_ids': evidenceChunkIds,
    });
  }

  static LearningAgentToolInputSnapshot? fromStorageValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      throw const FormatException('Invalid tool input snapshot JSON');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != _learningAgentToolInputSnapshotVersion) {
      throw const FormatException('Unsupported tool input snapshot');
    }
    final toolId = decoded['tool_id'];
    final targetId = decoded['target_id'];
    final focusPointId = decoded['focus_point_id'];
    final evidenceChunkIds = decoded['evidence_chunk_ids'];
    if (toolId is! String ||
        (targetId != null && targetId is! String) ||
        (focusPointId != null && focusPointId is! String) ||
        evidenceChunkIds is! List ||
        evidenceChunkIds.any((value) => value is! String)) {
      throw const FormatException('Invalid tool input snapshot fields');
    }
    return LearningAgentToolInputSnapshot(
      toolId: toolId,
      targetId: targetId as String?,
      focusPointId: focusPointId as String?,
      evidenceChunkIds: evidenceChunkIds.cast<String>(),
    );
  }
}

String? _normalizedNullable(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

List<String> _normalizedIds(Iterable<String> values) {
  final normalized = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
  normalized.sort();
  return normalized;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
