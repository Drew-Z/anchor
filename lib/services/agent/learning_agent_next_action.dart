enum LearningAgentNextActionPriority {
  unfinishedCheckpoint(
    'unfinished_checkpoint',
    '未完成会话',
    0,
  ),
  openFollowUp(
    'open_follow_up',
    '开放追问',
    1,
  ),
  evidenceGap(
    'evidence_gap',
    '证据缺口',
    2,
  ),
  pendingVerification(
    'pending_verification',
    '待核验内容',
    3,
  ),
  weakPrerequisite(
    'weak_prerequisite',
    '薄弱先修',
    4,
  ),
  dueReview(
    'due_review',
    '到期复习',
    5,
  ),
  newLearning(
    'new_learning',
    '新学习',
    6,
  ),
  none(
    'none',
    '无可执行动作',
    7,
  );

  final String value;
  final String label;
  final int order;

  const LearningAgentNextActionPriority(this.value, this.label, this.order);

  static LearningAgentNextActionPriority fromString(String value) {
    return LearningAgentNextActionPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => LearningAgentNextActionPriority.none,
    );
  }
}

abstract final class LearningAgentToolRouteIds {
  static const importSources = 'import_sources';
  static const verifyPendingQuestions = 'verify_pending_questions';
  static const handleFollowUps = 'handle_follow_ups';
  static const searchKnowledgeBase = 'search_knowledge_base';
  static const openTutorSession = 'open_tutor_session';
  static const openInterviewSession = 'open_interview_session';
  static const startVerifiedPractice = 'start_verified_practice';
  static const startReviewSession = 'start_review_session';
  static const saveAgentReflection = 'save_agent_reflection';
}

abstract final class LearningAgentStepRouteNames {
  static const importSources = 'importSources';
  static const verifyQuestions = 'verifyQuestions';
  static const handleFollowUps = 'handleFollowUps';
  static const tutor = 'tutor';
  static const interview = 'interview';
  static const practice = 'practice';
  static const review = 'review';
}

String? learningAgentToolIdForStepName(String? stepTypeName) {
  switch (stepTypeName) {
    case LearningAgentStepRouteNames.importSources:
      return LearningAgentToolRouteIds.importSources;
    case LearningAgentStepRouteNames.verifyQuestions:
      return LearningAgentToolRouteIds.verifyPendingQuestions;
    case LearningAgentStepRouteNames.handleFollowUps:
      return LearningAgentToolRouteIds.handleFollowUps;
    case LearningAgentStepRouteNames.tutor:
      return LearningAgentToolRouteIds.openTutorSession;
    case LearningAgentStepRouteNames.interview:
      return LearningAgentToolRouteIds.openInterviewSession;
    case LearningAgentStepRouteNames.practice:
      return LearningAgentToolRouteIds.startVerifiedPractice;
    case LearningAgentStepRouteNames.review:
      return LearningAgentToolRouteIds.startReviewSession;
    default:
      return null;
  }
}

class LearningAgentNextActionCandidate {
  final String id;
  final LearningAgentNextActionPriority priority;
  final String title;
  final String reason;
  final String? targetId;
  final String? targetLabel;
  final String? stepTypeName;
  final String? toolId;
  final String? checkpointSessionId;
  final DateTime? occurredAt;
  final int rank;
  final bool executable;
  final String? blockerCode;
  final String? blockerMessage;

  LearningAgentNextActionCandidate({
    required String id,
    required this.priority,
    required String title,
    required String reason,
    this.targetId,
    this.targetLabel,
    this.stepTypeName,
    this.toolId,
    this.checkpointSessionId,
    this.occurredAt,
    this.rank = 0,
    this.executable = true,
    this.blockerCode,
    this.blockerMessage,
  })  : id = _requiredText(id, 'id'),
        title = _requiredText(title, 'title'),
        reason = _requiredText(reason, 'reason') {
    if (rank < 0) {
      throw ArgumentError.value(
          rank, 'rank', 'Candidate rank cannot be negative.');
    }
    if (!executable && _normalizedNullable(blockerMessage) == null) {
      throw ArgumentError(
        'A non-executable next-action candidate requires a blocker message.',
      );
    }
  }

  factory LearningAgentNextActionCandidate.unfinishedCheckpoint({
    required String sessionId,
    required String title,
    required String reason,
    required DateTime updatedAt,
    String? targetId,
    String? targetLabel,
    String? stepTypeName,
    String? toolId,
    bool executable = true,
    String? blockerCode,
    String? blockerMessage,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'checkpoint:$sessionId',
      priority: LearningAgentNextActionPriority.unfinishedCheckpoint,
      title: title,
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: stepTypeName,
      toolId: toolId,
      checkpointSessionId: sessionId,
      occurredAt: updatedAt,
      executable: executable,
      blockerCode: blockerCode,
      blockerMessage: blockerMessage,
    );
  }

  factory LearningAgentNextActionCandidate.openFollowUp({
    required String id,
    required String question,
    required DateTime createdAt,
    String? targetId,
    String? targetLabel,
    int rank = 0,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'follow-up:$id',
      priority: LearningAgentNextActionPriority.openFollowUp,
      title: '处理开放追问',
      reason: '上一轮留下了未处理追问：“${question.trim()}”。',
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: LearningAgentStepRouteNames.handleFollowUps,
      toolId: LearningAgentToolRouteIds.handleFollowUps,
      occurredAt: createdAt,
      rank: rank,
    );
  }

  factory LearningAgentNextActionCandidate.evidenceGap({
    required String id,
    required String reason,
    String? targetId,
    String? targetLabel,
    DateTime? occurredAt,
    int rank = 0,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'evidence-gap:$id',
      priority: LearningAgentNextActionPriority.evidenceGap,
      title: '补齐来源证据',
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: LearningAgentStepRouteNames.importSources,
      toolId: LearningAgentToolRouteIds.importSources,
      occurredAt: occurredAt,
      rank: rank,
    );
  }

  factory LearningAgentNextActionCandidate.pendingVerification({
    required String id,
    required String reason,
    String? targetId,
    String? targetLabel,
    int rank = 0,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'pending-verification:$id',
      priority: LearningAgentNextActionPriority.pendingVerification,
      title: '核验待确认内容',
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: LearningAgentStepRouteNames.verifyQuestions,
      toolId: LearningAgentToolRouteIds.verifyPendingQuestions,
      rank: rank,
    );
  }

  factory LearningAgentNextActionCandidate.weakPrerequisite({
    required String id,
    required String reason,
    String? targetId,
    String? targetLabel,
    DateTime? occurredAt,
    int rank = 0,
    bool executable = true,
    String? blockerCode,
    String? blockerMessage,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'weak-prerequisite:$id',
      priority: LearningAgentNextActionPriority.weakPrerequisite,
      title: '先补薄弱先修',
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: LearningAgentStepRouteNames.tutor,
      toolId: LearningAgentToolRouteIds.openTutorSession,
      occurredAt: occurredAt,
      rank: rank,
      executable: executable,
      blockerCode: blockerCode,
      blockerMessage: blockerMessage,
    );
  }

  factory LearningAgentNextActionCandidate.dueReview({
    required String id,
    required String reason,
    required DateTime dueAt,
    String? targetId,
    String? targetLabel,
    int rank = 0,
    bool executable = true,
    String? blockerCode,
    String? blockerMessage,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'due-review:$id',
      priority: LearningAgentNextActionPriority.dueReview,
      title: '完成到期复习',
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: LearningAgentStepRouteNames.review,
      toolId: LearningAgentToolRouteIds.startReviewSession,
      occurredAt: dueAt,
      rank: rank,
      executable: executable,
      blockerCode: blockerCode,
      blockerMessage: blockerMessage,
    );
  }

  factory LearningAgentNextActionCandidate.newLearning({
    required String id,
    required String title,
    required String reason,
    required String stepTypeName,
    required String toolId,
    String? targetId,
    String? targetLabel,
    int rank = 0,
  }) {
    return LearningAgentNextActionCandidate(
      id: 'new-learning:$id',
      priority: LearningAgentNextActionPriority.newLearning,
      title: title,
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: stepTypeName,
      toolId: toolId,
      rank: rank,
    );
  }

  LearningAgentNextActionCandidate blocked({
    required String code,
    required String message,
  }) {
    return LearningAgentNextActionCandidate(
      id: id,
      priority: priority,
      title: title,
      reason: reason,
      targetId: targetId,
      targetLabel: targetLabel,
      stepTypeName: stepTypeName,
      toolId: toolId,
      checkpointSessionId: checkpointSessionId,
      occurredAt: occurredAt,
      rank: rank,
      executable: false,
      blockerCode: code,
      blockerMessage: message,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'priority': priority.value,
      'title': title,
      'reason': reason,
      'target_id': targetId,
      'target_label': targetLabel,
      'step_type_name': stepTypeName,
      'tool_id': toolId,
      'checkpoint_session_id': checkpointSessionId,
      'occurred_at': occurredAt?.millisecondsSinceEpoch,
      'rank': rank,
      'executable': executable,
      'blocker_code': blockerCode,
      'blocker_message': blockerMessage,
    };
  }

  factory LearningAgentNextActionCandidate.fromMap(
    Map<String, dynamic> map,
  ) {
    final occurredAt = map['occurred_at'] as int?;
    return LearningAgentNextActionCandidate(
      id: map['id'] as String,
      priority: LearningAgentNextActionPriority.fromString(
        map['priority'] as String,
      ),
      title: map['title'] as String,
      reason: map['reason'] as String,
      targetId: map['target_id'] as String?,
      targetLabel: map['target_label'] as String?,
      stepTypeName: map['step_type_name'] as String?,
      toolId: map['tool_id'] as String?,
      checkpointSessionId: map['checkpoint_session_id'] as String?,
      occurredAt: occurredAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(occurredAt),
      rank: map['rank'] as int? ?? 0,
      executable: map['executable'] as bool? ?? true,
      blockerCode: map['blocker_code'] as String?,
      blockerMessage: map['blocker_message'] as String?,
    );
  }

  String get canonicalKey {
    return [
      priority.order.toString().padLeft(2, '0'),
      rank.toString().padLeft(10, '0'),
      id,
      targetId ?? '',
      stepTypeName ?? '',
      toolId ?? '',
      reason,
      executable ? '1' : '0',
      blockerCode ?? '',
      blockerMessage ?? '',
    ].join('\x00');
  }
}

class LearningAgentNextActionInputSnapshot {
  static const int currentVersion = 1;

  final String goalValue;
  final DateTime plannedAt;
  final List<LearningAgentNextActionCandidate> candidates;

  LearningAgentNextActionInputSnapshot({
    required String goalValue,
    required this.plannedAt,
    required List<LearningAgentNextActionCandidate> candidates,
  })  : goalValue = _requiredText(goalValue, 'goalValue'),
        candidates = List.unmodifiable(candidates);

  Map<String, int> get candidateCountByPriority {
    final counts = <String, int>{};
    for (final candidate in candidates) {
      counts[candidate.priority.value] =
          (counts[candidate.priority.value] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, dynamic> toMap() {
    return {
      'version': currentVersion,
      'goal': goalValue,
      'planned_at': plannedAt.millisecondsSinceEpoch,
      'candidates': candidates.map((candidate) => candidate.toMap()).toList(),
    };
  }

  factory LearningAgentNextActionInputSnapshot.fromMap(
    Map<String, dynamic> map,
  ) {
    final version = map['version'] as int?;
    if (version != currentVersion) {
      throw FormatException(
        'Unsupported next-action input snapshot version: $version',
      );
    }
    return LearningAgentNextActionInputSnapshot(
      goalValue: map['goal'] as String,
      plannedAt: DateTime.fromMillisecondsSinceEpoch(map['planned_at'] as int),
      candidates: (map['candidates'] as List<dynamic>? ?? const [])
          .map(
            (item) => LearningAgentNextActionCandidate.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class LearningAgentNextAction {
  final LearningAgentNextActionCandidate selectedCandidate;
  final LearningAgentNextActionInputSnapshot inputSnapshot;

  const LearningAgentNextAction({
    required this.selectedCandidate,
    required this.inputSnapshot,
  });

  LearningAgentNextActionPriority get priority => selectedCandidate.priority;
  String get id => selectedCandidate.id;
  String get title => selectedCandidate.title;
  String get reason => selectedCandidate.reason;
  String? get targetId => selectedCandidate.targetId;
  String? get targetLabel => selectedCandidate.targetLabel;
  String? get stepTypeName => selectedCandidate.stepTypeName;
  String? get toolId => selectedCandidate.toolId;
  String? get checkpointSessionId => selectedCandidate.checkpointSessionId;
  bool get executable => selectedCandidate.executable;
  String? get blockerCode => selectedCandidate.blockerCode;
  String? get blockerMessage => selectedCandidate.blockerMessage;
  bool get resumesCheckpoint =>
      priority == LearningAgentNextActionPriority.unfinishedCheckpoint &&
      checkpointSessionId != null;

  Map<String, dynamic> toMap() {
    return {
      'selected_candidate': selectedCandidate.toMap(),
      'input_snapshot': inputSnapshot.toMap(),
    };
  }

  factory LearningAgentNextAction.fromMap(Map<String, dynamic> map) {
    return LearningAgentNextAction(
      selectedCandidate: LearningAgentNextActionCandidate.fromMap(
        Map<String, dynamic>.from(map['selected_candidate'] as Map),
      ),
      inputSnapshot: LearningAgentNextActionInputSnapshot.fromMap(
        Map<String, dynamic>.from(map['input_snapshot'] as Map),
      ),
    );
  }

  List<String> diagnosticLines() {
    final counts = inputSnapshot.candidateCountByPriority;
    final countSummary = LearningAgentNextActionPriority.values
        .where((priority) => priority != LearningAgentNextActionPriority.none)
        .map((priority) => '${priority.label} ${counts[priority.value] ?? 0}')
        .join(' · ');
    return [
      'Next action 优先级: ${priority.label}',
      'Next action 候选: $id',
      'Next action 原因: $reason',
      'Next action 工具: ${toolId ?? '无'}',
      'Next action 输入: $countSummary',
      'Next action 计划时间: ${inputSnapshot.plannedAt.toIso8601String()}',
      if (!executable) 'Next action blocker: ${blockerMessage ?? '未知阻断'}',
    ];
  }
}

class LearningAgentNextActionPolicy {
  const LearningAgentNextActionPolicy();

  LearningAgentNextAction choose({
    required String goalValue,
    required DateTime plannedAt,
    required Iterable<LearningAgentNextActionCandidate> candidates,
  }) {
    final ordered = candidates.toList(growable: false)
      ..sort(_compareCandidates);
    final snapshot = LearningAgentNextActionInputSnapshot(
      goalValue: goalValue,
      plannedAt: plannedAt,
      candidates: ordered,
    );
    if (ordered.isEmpty) {
      return LearningAgentNextAction(
        selectedCandidate: LearningAgentNextActionCandidate(
          id: 'no-action',
          priority: LearningAgentNextActionPriority.none,
          title: '暂无可执行动作',
          reason: '当前输入没有形成任何可执行学习候选。',
          executable: false,
          blockerCode: 'next_action_missing',
          blockerMessage: '当前没有可执行动作，请补充来源或检查学习数据。',
        ),
        inputSnapshot: snapshot,
      );
    }
    return LearningAgentNextAction(
      selectedCandidate: ordered.first,
      inputSnapshot: snapshot,
    );
  }

  int _compareCandidates(
    LearningAgentNextActionCandidate a,
    LearningAgentNextActionCandidate b,
  ) {
    final priority = a.priority.order.compareTo(b.priority.order);
    if (priority != 0) return priority;
    final rank = a.rank.compareTo(b.rank);
    if (rank != 0) return rank;

    final aTime = a.occurredAt;
    final bTime = b.occurredAt;
    if (aTime != null || bTime != null) {
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final time = a.priority == LearningAgentNextActionPriority.dueReview
          ? aTime.compareTo(bTime)
          : bTime.compareTo(aTime);
      if (time != 0) return time;
    }
    return a.canonicalKey.compareTo(b.canonicalKey);
  }
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '$name cannot be empty.');
  }
  return normalized;
}

String? _normalizedNullable(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
