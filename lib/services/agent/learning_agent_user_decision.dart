import 'dart:convert';

const _learningAgentUserDecisionVersion = 3;
const _previousLearningAgentUserDecisionVersion = 2;
const _legacyLearningAgentUserDecisionVersion = 1;

enum LearningAgentUserDecisionReason {
  toolInterrupted('tool_interrupted', '工具执行中断'),
  toolOutcomeUnknown('tool_outcome_unknown', '工具结果未知'),
  legacyCheckpoint('legacy_checkpoint', '旧版 checkpoint');

  final String value;
  final String label;
  const LearningAgentUserDecisionReason(this.value, this.label);

  static LearningAgentUserDecisionReason fromString(String value) {
    return LearningAgentUserDecisionReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => LearningAgentUserDecisionReason.legacyCheckpoint,
    );
  }
}

enum LearningAgentUserDecisionAction {
  continueSession('continue_session', '继续执行'),
  confirmToolCompleted('confirm_tool_completed', '确认工具已完成'),
  cancelSession('cancel_session', '结束会话');

  final String value;
  final String label;
  const LearningAgentUserDecisionAction(this.value, this.label);
}

class LearningAgentUserDecisionRequest {
  final String id;
  final String prompt;
  final DateTime requestedAt;
  final String? toolId;
  final String? operationId;
  final String? attemptId;
  final LearningAgentUserDecisionReason reason;

  const LearningAgentUserDecisionRequest({
    required this.id,
    required this.prompt,
    required this.requestedAt,
    this.toolId,
    this.operationId,
    this.attemptId,
    required this.reason,
  });

  factory LearningAgentUserDecisionRequest.toolInterrupted({
    required String sessionId,
    required String toolTitle,
    String? toolId,
    String? operationId,
    DateTime? requestedAt,
  }) {
    final requested = requestedAt ?? DateTime.now();
    return LearningAgentUserDecisionRequest(
      id: '${sessionId}_${requested.microsecondsSinceEpoch}_tool_interrupted',
      prompt: '“$toolTitle”执行被中断。是否继续并重新执行该工具？',
      requestedAt: requested,
      toolId: toolId,
      operationId: operationId,
      reason: LearningAgentUserDecisionReason.toolInterrupted,
    );
  }

  factory LearningAgentUserDecisionRequest.toolOutcomeUnknown({
    required String sessionId,
    required String toolTitle,
    required String operationId,
    required String attemptId,
    String? toolId,
    DateTime? requestedAt,
  }) {
    final requested = requestedAt ?? DateTime.now();
    return LearningAgentUserDecisionRequest(
      id: '${sessionId}_${requested.microsecondsSinceEpoch}_tool_outcome_unknown',
      prompt: '“$toolTitle”已经开始执行，但最终结果尚未保存。请确认是否重新执行、按已完成处理或结束会话。',
      requestedAt: requested,
      toolId: toolId,
      operationId: operationId,
      attemptId: attemptId,
      reason: LearningAgentUserDecisionReason.toolOutcomeUnknown,
    );
  }

  String toStorageValue() {
    return jsonEncode({
      'version': _learningAgentUserDecisionVersion,
      'id': id,
      'prompt': prompt,
      'requested_at': requestedAt.millisecondsSinceEpoch,
      'tool_id': toolId,
      'operation_id': operationId,
      'attempt_id': attemptId,
      'reason': reason.value,
    });
  }

  static LearningAgentUserDecisionRequest? fromStorageValue(
    String? value, {
    DateTime? fallbackRequestedAt,
    String? fallbackToolId,
  }) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return _legacyRequest(
        trimmed,
        fallbackRequestedAt: fallbackRequestedAt,
        fallbackToolId: fallbackToolId,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return _legacyRequest(
        decoded is String ? decoded : trimmed,
        fallbackRequestedAt: fallbackRequestedAt,
        fallbackToolId: fallbackToolId,
      );
    }

    final version = decoded['version'];
    if (version != _learningAgentUserDecisionVersion &&
        version != _previousLearningAgentUserDecisionVersion &&
        version != _legacyLearningAgentUserDecisionVersion) {
      throw FormatException('Unsupported user decision version: $version');
    }
    final id = decoded['id'];
    final prompt = decoded['prompt'];
    final requestedAt = decoded['requested_at'];
    final reason = decoded['reason'];
    if (id is! String ||
        id.trim().isEmpty ||
        prompt is! String ||
        prompt.trim().isEmpty ||
        requestedAt is! int ||
        reason is! String) {
      throw const FormatException('Invalid user decision request');
    }
    final toolId = decoded['tool_id'];
    if (toolId != null && toolId is! String) {
      throw const FormatException('Invalid user decision tool id');
    }
    final operationId = decoded['operation_id'];
    if (operationId != null && operationId is! String) {
      throw const FormatException('Invalid user decision operation id');
    }
    final attemptId = decoded['attempt_id'];
    if (attemptId != null && attemptId is! String) {
      throw const FormatException('Invalid user decision attempt id');
    }
    return LearningAgentUserDecisionRequest(
      id: id,
      prompt: prompt,
      requestedAt: DateTime.fromMillisecondsSinceEpoch(requestedAt),
      toolId: toolId as String?,
      operationId: operationId as String?,
      attemptId: attemptId as String?,
      reason: LearningAgentUserDecisionReason.fromString(reason),
    );
  }

  static LearningAgentUserDecisionRequest _legacyRequest(
    String prompt, {
    DateTime? fallbackRequestedAt,
    String? fallbackToolId,
  }) {
    final requested =
        fallbackRequestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return LearningAgentUserDecisionRequest(
      id: 'legacy_${requested.microsecondsSinceEpoch}',
      prompt: prompt,
      requestedAt: requested,
      toolId: fallbackToolId,
      reason: LearningAgentUserDecisionReason.legacyCheckpoint,
    );
  }
}
