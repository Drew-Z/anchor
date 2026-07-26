import 'learning_agent_planner_service.dart';

enum LearningAgentMemoryRecordType {
  knowledgeAnswer('knowledge_answer', '知识库回答'),
  tutor('tutor', '导师'),
  interview('interview', '面试'),
  programmingExercise('programming_exercise', '编程练习'),
  agentReflection('agent_reflection', 'Agent 复盘'),
  reviewAction('review_action', '复习动作');

  final String value;
  final String label;

  const LearningAgentMemoryRecordType(this.value, this.label);
}

enum LearningAgentMemoryTargetResolution {
  direct('direct', '目标直连'),
  childRecord('child_record', '回合直连'),
  practiceRouting('practice_routing', '练习路由解析'),
  sourceCitation('source_citation', '按历史引用归属'),
  sessionScope('session_scope', '按历史会话范围归属'),
  unresolved('unresolved', '未精确归属');

  final String value;
  final String label;

  const LearningAgentMemoryTargetResolution(this.value, this.label);
}

class LearningAgentMemoryMisconception {
  final String key;
  final String label;

  const LearningAgentMemoryMisconception({
    required this.key,
    required this.label,
  });
}

class LearningAgentMemoryWeakDimension {
  final String key;
  final String label;
  final String evidenceId;

  const LearningAgentMemoryWeakDimension({
    required this.key,
    required this.label,
    required this.evidenceId,
  });
}

class LearningAgentMemoryWeakPrerequisite {
  final String targetId;
  final String targetLabel;

  const LearningAgentMemoryWeakPrerequisite({
    required this.targetId,
    required this.targetLabel,
  });
}

class LearningAgentMemoryRecord {
  final String id;
  final LearningAgentMemoryRecordType type;
  final String sourceId;
  final String? sessionId;
  final String? targetId;
  final String? targetLabel;
  final LearningAgentMemoryTargetResolution targetResolution;
  final Set<LearningAgentGoal> goals;
  final DateTime occurredAt;
  final String title;
  final String summary;
  final List<String> handledPrompts;
  final List<String> followUpQuestions;
  final List<LearningAgentMemoryMisconception> misconceptions;
  final List<LearningAgentMemoryWeakDimension> weakDimensions;
  final List<LearningAgentMemoryWeakPrerequisite> weakPrerequisites;
  final DateTime? reviewDueAt;
  final DateTime? reviewCompletedAt;
  final List<String> citationIds;
  final bool evidenceSufficient;

  const LearningAgentMemoryRecord({
    required this.id,
    required this.type,
    required this.sourceId,
    this.sessionId,
    this.targetId,
    this.targetLabel,
    this.targetResolution = LearningAgentMemoryTargetResolution.unresolved,
    this.goals = const <LearningAgentGoal>{},
    required this.occurredAt,
    required this.title,
    required this.summary,
    this.handledPrompts = const [],
    this.followUpQuestions = const [],
    this.misconceptions = const [],
    this.weakDimensions = const [],
    this.weakPrerequisites = const [],
    this.reviewDueAt,
    this.reviewCompletedAt,
    this.citationIds = const [],
    this.evidenceSufficient = true,
  });

  bool get hasTarget => targetId != null && targetId!.isNotEmpty;
  bool get hasOpenReview => reviewDueAt != null && reviewCompletedAt == null;
  bool get usesLegacyTargetInference =>
      targetResolution == LearningAgentMemoryTargetResolution.sourceCitation ||
      targetResolution == LearningAgentMemoryTargetResolution.sessionScope;
}

class LearningAgentMemoryReviewSchedule {
  final String id;
  final String targetId;
  final Set<LearningAgentGoal> goals;
  final DateTime dueAt;

  const LearningAgentMemoryReviewSchedule({
    required this.id,
    required this.targetId,
    this.goals = const <LearningAgentGoal>{},
    required this.dueAt,
  });
}

class LearningAgentMemoryBuildResult {
  final List<LearningAgentMemoryRecord> records;
  final List<LearningAgentMemoryReviewSchedule> reviewSchedules;

  const LearningAgentMemoryBuildResult({
    required this.records,
    this.reviewSchedules = const [],
  });
}

class LearningAgentOpenFollowUp {
  final String id;
  final String recordId;
  final LearningAgentMemoryRecordType recordType;
  final String? targetId;
  final String question;
  final DateTime createdAt;

  const LearningAgentOpenFollowUp({
    required this.id,
    required this.recordId,
    required this.recordType,
    required this.targetId,
    required this.question,
    required this.createdAt,
  });
}

class LearningAgentStableMisconception {
  final String key;
  final String label;
  final int occurrenceCount;
  final DateTime latestAt;

  const LearningAgentStableMisconception({
    required this.key,
    required this.label,
    required this.occurrenceCount,
    required this.latestAt,
  });
}

class LearningAgentWeakDimensionSummary {
  final String key;
  final String label;
  final int occurrenceCount;
  final DateTime latestAt;

  const LearningAgentWeakDimensionSummary({
    required this.key,
    required this.label,
    required this.occurrenceCount,
    required this.latestAt,
  });
}

class LearningAgentWeakPrerequisiteSummary {
  final String targetId;
  final String targetLabel;
  final int occurrenceCount;
  final DateTime latestAt;

  const LearningAgentWeakPrerequisiteSummary({
    required this.targetId,
    required this.targetLabel,
    required this.occurrenceCount,
    required this.latestAt,
  });
}

class LearningAgentPendingReview {
  final String id;
  final String targetId;
  final DateTime dueAt;
  final LearningAgentMemoryRecordType recordType;

  const LearningAgentPendingReview({
    required this.id,
    required this.targetId,
    required this.dueAt,
    required this.recordType,
  });
}

class LearningAgentMemorySnapshot {
  final List<LearningAgentMemoryRecord> records;
  final List<LearningAgentMemoryRecord> recentRecords;
  final List<LearningAgentOpenFollowUp> openFollowUps;
  final List<LearningAgentStableMisconception> stableMisconceptions;
  final List<LearningAgentWeakDimensionSummary> weakDimensions;
  final List<LearningAgentWeakPrerequisiteSummary> weakPrerequisites;
  final List<LearningAgentPendingReview> pendingReviews;
  final DateTime? nextReviewAt;

  const LearningAgentMemorySnapshot({
    this.records = const [],
    this.recentRecords = const [],
    this.openFollowUps = const [],
    this.stableMisconceptions = const [],
    this.weakDimensions = const [],
    this.weakPrerequisites = const [],
    this.pendingReviews = const [],
    this.nextReviewAt,
  });

  bool get isEmpty => records.isEmpty;
  int get recordCount => records.length;
  String? get latestOpenFollowUpQuestion =>
      openFollowUps.isEmpty ? null : openFollowUps.first.question;
}
