import 'learning_agent_planner_service.dart';
import 'learning_agent_state.dart';
import 'learning_agent_tool_input_snapshot.dart';
import 'learning_agent_user_decision.dart';

const learningAgentTraceHeader = 'Agent Trace:';
const learningAgentTraceLinePrefix = 'Trace:';
const _listSeparator = '\x00';
const _traceTextSeparator = ' · ';
var _traceEventSequence = 0;

enum LearningAgentTraceEventType {
  planCreated('plan_created', '生成计划'),
  policyChecked('policy_checked', '检查策略'),
  toolSelected('tool_selected', '选择工具'),
  toolInputRejected('tool_input_rejected', '拒绝工具输入'),
  toolStarted('tool_started', '开始工具'),
  toolCompleted('tool_completed', '完成工具'),
  toolFailed('tool_failed', '工具失败'),
  evidenceAttached('evidence_attached', '绑定证据'),
  userInterrupted('user_interrupted', '用户中断'),
  userDecisionRequested('user_decision_requested', '请求用户决策'),
  userDecisionResolved('user_decision_resolved', '完成用户决策'),
  sessionResumed('session_resumed', '恢复会话'),
  reflectionSaved('reflection_saved', '保存复盘');

  final String value;
  final String label;
  const LearningAgentTraceEventType(this.value, this.label);

  static LearningAgentTraceEventType fromString(String value) {
    return LearningAgentTraceEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LearningAgentTraceEventType.planCreated,
    );
  }
}

enum LearningAgentTraceLevel {
  info('info', '信息'),
  warning('warning', '警告'),
  error('error', '错误');

  final String value;
  final String label;
  const LearningAgentTraceLevel(this.value, this.label);

  static LearningAgentTraceLevel fromString(String value) {
    return LearningAgentTraceLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => LearningAgentTraceLevel.info,
    );
  }
}

class LearningAgentTraceEvent {
  final String id;
  final String sessionId;
  final LearningAgentGoal goal;
  final LearningAgentTraceEventType type;
  final LearningAgentTraceLevel level;
  final DateTime occurredAt;
  final LearningAgentPhase? phase;
  final String? targetId;
  final String? targetLabel;
  final String? toolId;
  final String summary;
  final String? detail;
  final List<String> evidenceChunkIds;
  final List<String> policyIssueCodes;

  LearningAgentTraceEvent({
    required this.id,
    required this.sessionId,
    required this.goal,
    required this.type,
    this.level = LearningAgentTraceLevel.info,
    required this.occurredAt,
    this.phase,
    this.targetId,
    this.targetLabel,
    this.toolId,
    required this.summary,
    this.detail,
    this.evidenceChunkIds = const [],
    this.policyIssueCodes = const [],
  });

  factory LearningAgentTraceEvent.now({
    required String sessionId,
    required LearningAgentGoal goal,
    required LearningAgentTraceEventType type,
    required String summary,
    LearningAgentTraceLevel level = LearningAgentTraceLevel.info,
    LearningAgentPhase? phase,
    String? targetId,
    String? targetLabel,
    String? toolId,
    String? detail,
    List<String> evidenceChunkIds = const [],
    List<String> policyIssueCodes = const [],
  }) {
    final occurredAt = DateTime.now();
    return LearningAgentTraceEvent(
      id: _eventId(occurredAt, type),
      sessionId: sessionId,
      goal: goal,
      type: type,
      level: level,
      occurredAt: occurredAt,
      phase: phase,
      targetId: targetId,
      targetLabel: targetLabel,
      toolId: toolId,
      summary: summary,
      detail: detail,
      evidenceChunkIds: evidenceChunkIds,
      policyIssueCodes: policyIssueCodes,
    );
  }

  factory LearningAgentTraceEvent.fromState({
    required LearningAgentState state,
    required LearningAgentTraceEventType type,
    required String summary,
    LearningAgentTraceLevel level = LearningAgentTraceLevel.info,
    String? targetLabel,
    String? detail,
    List<String>? evidenceChunkIds,
    List<String> policyIssueCodes = const [],
  }) {
    return LearningAgentTraceEvent.now(
      sessionId: state.sessionId,
      goal: state.goal,
      type: type,
      level: level,
      phase: state.phase,
      targetId: state.targetId,
      targetLabel: targetLabel,
      toolId: state.selectedToolId,
      summary: summary,
      detail: detail,
      evidenceChunkIds: evidenceChunkIds ?? state.evidenceChunkIds,
      policyIssueCodes: policyIssueCodes,
    );
  }

  bool get isFailure {
    return level == LearningAgentTraceLevel.error ||
        type == LearningAgentTraceEventType.toolFailed;
  }

  bool get hasEvidence => evidenceChunkIds.isNotEmpty;
  bool get hasPolicyIssues => policyIssueCodes.isNotEmpty;

  LearningAgentTraceEvent copyWith({
    String? id,
    String? sessionId,
    LearningAgentGoal? goal,
    LearningAgentTraceEventType? type,
    LearningAgentTraceLevel? level,
    DateTime? occurredAt,
    LearningAgentPhase? phase,
    String? targetId,
    String? targetLabel,
    String? toolId,
    String? summary,
    String? detail,
    List<String>? evidenceChunkIds,
    List<String>? policyIssueCodes,
  }) {
    return LearningAgentTraceEvent(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      goal: goal ?? this.goal,
      type: type ?? this.type,
      level: level ?? this.level,
      occurredAt: occurredAt ?? this.occurredAt,
      phase: phase ?? this.phase,
      targetId: targetId ?? this.targetId,
      targetLabel: targetLabel ?? this.targetLabel,
      toolId: toolId ?? this.toolId,
      summary: summary ?? this.summary,
      detail: detail ?? this.detail,
      evidenceChunkIds: evidenceChunkIds ?? this.evidenceChunkIds,
      policyIssueCodes: policyIssueCodes ?? this.policyIssueCodes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'goal': goal.value,
      'type': type.value,
      'level': level.value,
      'occurred_at': occurredAt.millisecondsSinceEpoch,
      'phase': phase?.value,
      'target_id': targetId,
      'target_label': targetLabel,
      'tool_id': toolId,
      'summary': summary,
      'detail': detail,
      'evidence_chunk_ids': _joinList(evidenceChunkIds),
      'policy_issue_codes': _joinList(policyIssueCodes),
    };
  }

  factory LearningAgentTraceEvent.fromMap(Map<String, dynamic> map) {
    final phaseValue = map['phase'] as String?;
    return LearningAgentTraceEvent(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      goal: LearningAgentGoal.fromString(map['goal'] as String),
      type: LearningAgentTraceEventType.fromString(map['type'] as String),
      level: LearningAgentTraceLevel.fromString(
        (map['level'] as String?) ?? LearningAgentTraceLevel.info.value,
      ),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        map['occurred_at'] as int,
      ),
      phase: phaseValue == null || phaseValue.isEmpty
          ? null
          : LearningAgentPhase.fromString(phaseValue),
      targetId: map['target_id'] as String?,
      targetLabel: map['target_label'] as String?,
      toolId: map['tool_id'] as String?,
      summary: map['summary'] as String,
      detail: map['detail'] as String?,
      evidenceChunkIds: _splitList(map['evidence_chunk_ids'] as String?),
      policyIssueCodes: _splitList(map['policy_issue_codes'] as String?),
    );
  }
}

class LearningAgentTraceRecorder {
  final List<LearningAgentTraceEvent> _events;
  LearningAgentState? _state;

  LearningAgentTraceRecorder({
    List<LearningAgentTraceEvent> initialEvents = const [],
    LearningAgentState? initialState,
  })  : _events = List<LearningAgentTraceEvent>.from(initialEvents),
        _state = initialState == null
            ? null
            : initialState.copyWith(
                traceEventIds: _mergedTraceEventIds(
                  initialState.traceEventIds,
                  initialEvents,
                ),
              );

  List<LearningAgentTraceEvent> get events {
    return List<LearningAgentTraceEvent>.unmodifiable(_events);
  }

  LearningAgentState? get state => _state;

  LearningAgentTraceEvent record(
    LearningAgentTraceEvent event, {
    LearningAgentPhase? phase,
    List<String>? evidenceChunkIds,
    String? activeToolOperationId,
    LearningAgentToolInputSnapshot? activeToolInputSnapshot,
    bool clearActiveToolOperation = false,
    LearningAgentUserDecisionRequest? pendingUserDecision,
    bool clearPendingUserDecision = false,
    List<String>? policyWarnings,
  }) {
    _events.add(event);
    final currentState = _state;
    if (currentState != null) {
      final nextEvidenceChunkIds = evidenceChunkIds ??
          (event.evidenceChunkIds.isEmpty ? null : event.evidenceChunkIds);
      _state = currentState.transitionTo(
        phase ?? event.phase ?? currentState.phase,
        evidenceChunkIds: nextEvidenceChunkIds,
        activeToolOperationId: activeToolOperationId,
        activeToolInputSnapshot: activeToolInputSnapshot,
        clearActiveToolOperation: clearActiveToolOperation,
        pendingUserDecision: pendingUserDecision,
        clearPendingUserDecision: clearPendingUserDecision,
        policyWarnings: policyWarnings,
        traceEventIds: _eventIds(_events),
      );
    }
    return event;
  }
}

List<String> learningAgentTraceSummaryLines(
  List<LearningAgentTraceEvent> events,
) {
  if (events.isEmpty) return const [];
  return [
    learningAgentTraceHeader,
    ...events.map(learningAgentTraceLine),
  ];
}

String learningAgentTraceLine(LearningAgentTraceEvent event) {
  final parts = <String>[
    learningAgentTraceDateTimeText(event.occurredAt),
    event.type.label,
  ];
  if (event.level != LearningAgentTraceLevel.info) {
    parts.add(event.level.label);
  }
  parts.add(learningAgentTraceSingleLineText(event.summary));
  if (event.evidenceChunkIds.isNotEmpty) {
    parts.add('证据 ${event.evidenceChunkIds.length}');
  }
  if (event.policyIssueCodes.isNotEmpty) {
    parts.add('策略问题 ${event.policyIssueCodes.length}');
  }
  return '$learningAgentTraceLinePrefix ${parts.join(_traceTextSeparator)}';
}

String learningAgentTraceDateTimeText(DateTime value) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String learningAgentTraceSingleLineText(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _mergedTraceEventIds(
  List<String> existingIds,
  List<LearningAgentTraceEvent> events,
) {
  return [
    ...{
      ...existingIds.where((id) => id.isNotEmpty),
      ...events.map((event) => event.id).where((id) => id.isNotEmpty),
    },
  ];
}

List<String> _eventIds(List<LearningAgentTraceEvent> events) {
  return events.map((event) => event.id).where((id) => id.isNotEmpty).toList();
}

String _eventId(
  DateTime occurredAt,
  LearningAgentTraceEventType type,
) {
  final sequence = _traceEventSequence++;
  return '${occurredAt.microsecondsSinceEpoch}_${sequence}_${type.value}';
}

String _joinList(List<String> values) {
  return values.where((value) => value.isNotEmpty).join(_listSeparator);
}

List<String> _splitList(String? value) {
  if (value == null || value.isEmpty) return const [];
  return value.split(_listSeparator).where((item) => item.isNotEmpty).toList();
}
