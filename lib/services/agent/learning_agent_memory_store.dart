import '../../data/models/learning_session.dart';
import 'agent_session_memory_index.dart';
import 'agent_session_target_id.dart';
import 'learning_agent_memory_record.dart';
import 'learning_agent_planner_service.dart';

class LearningAgentGoalMemory {
  final LearningAgentGoal goal;
  final int sessionCount;
  final int openFollowUpCount;
  final LearningSession? latestSession;
  final AgentSessionLatestRecord? latestRecord;
  final int recordCount;
  final LearningAgentMemoryRecord? latestMemoryRecord;
  final List<LearningAgentOpenFollowUp> openFollowUps;
  final List<LearningAgentStableMisconception> stableMisconceptions;
  final List<LearningAgentWeakDimensionSummary> weakDimensions;
  final List<LearningAgentWeakPrerequisiteSummary> weakPrerequisites;
  final List<LearningAgentPendingReview> pendingReviews;
  final DateTime? nextReviewAt;

  const LearningAgentGoalMemory({
    required this.goal,
    required this.sessionCount,
    required this.openFollowUpCount,
    this.latestSession,
    this.latestRecord,
    this.recordCount = 0,
    this.latestMemoryRecord,
    this.openFollowUps = const [],
    this.stableMisconceptions = const [],
    this.weakDimensions = const [],
    this.weakPrerequisites = const [],
    this.pendingReviews = const [],
    this.nextReviewAt,
  });

  bool get hasSessions => sessionCount > 0;
  bool get hasOpenFollowUps => openFollowUpCount > 0;
  bool get hasLatestSession => latestSession != null;

  LearningAgentMemoryState toPlannerMemoryState() {
    return LearningAgentMemoryState(
      goalSessionCount: sessionCount,
      goalOpenFollowUpCount: openFollowUpCount,
      latestGoalSessionTitle: latestRecord?.title,
      latestGoalSessionTarget: latestRecord?.target,
      latestGoalSessionStartedAt: latestRecord?.startedAt,
    );
  }
}

class LearningAgentTargetMemory {
  final String? targetId;
  final String? targetLabel;
  final int sessionCount;
  final int recordCount;
  final int openFollowUpCount;
  final String? latestOpenFollowUpQuestion;
  final List<LearningAgentMemoryRecord> recentRecords;
  final List<LearningAgentOpenFollowUp> openFollowUps;
  final List<LearningAgentStableMisconception> stableMisconceptions;
  final List<LearningAgentWeakDimensionSummary> weakDimensions;
  final List<LearningAgentWeakPrerequisiteSummary> weakPrerequisites;
  final List<LearningAgentPendingReview> pendingReviews;
  final DateTime? nextReviewAt;

  const LearningAgentTargetMemory({
    required this.targetId,
    this.targetLabel,
    required this.sessionCount,
    this.recordCount = 0,
    required this.openFollowUpCount,
    this.latestOpenFollowUpQuestion,
    this.recentRecords = const [],
    this.openFollowUps = const [],
    this.stableMisconceptions = const [],
    this.weakDimensions = const [],
    this.weakPrerequisites = const [],
    this.pendingReviews = const [],
    this.nextReviewAt,
  });

  bool get hasTarget => targetId != null;
  bool get hasSessions => sessionCount > 0;
  bool get hasRecords => recordCount > 0;
  bool get hasOpenFollowUps => openFollowUpCount > 0;
}

class LearningAgentMemoryStore {
  final AgentSessionMemoryIndex index;
  final List<LearningAgentMemoryRecord> records;
  final List<LearningAgentMemoryReviewSchedule> reviewSchedules;

  LearningAgentMemoryStore(
    this.index, {
    List<LearningAgentMemoryRecord> records = const [],
    List<LearningAgentMemoryReviewSchedule> reviewSchedules = const [],
  })  : records = List.unmodifiable(
          <LearningAgentMemoryRecord>[...records]
            ..sort(_compareRecordsNewestFirst),
        ),
        reviewSchedules = List.unmodifiable(reviewSchedules);

  int get totalSessionCount => index.totalCount;
  int get openFollowUpCount =>
      records.isEmpty ? index.openFollowUpCount : _allOpenFollowUps().length;
  List<LearningSession> get sessions => index.sessions;

  LearningAgentGoalMemory memoryForGoal(LearningAgentGoal goal) {
    final snapshot = query(goal: goal);
    final unifiedOpenCount = records.isEmpty
        ? index.openFollowUpCountForGoal(goal)
        : snapshot.openFollowUps.length;
    return LearningAgentGoalMemory(
      goal: goal,
      sessionCount: index.countForGoal(goal),
      openFollowUpCount: unifiedOpenCount,
      latestSession: index.latestSessionForGoal(goal),
      latestRecord: index.latestRecordForGoal(goal),
      recordCount: snapshot.recordCount,
      latestMemoryRecord:
          snapshot.records.isEmpty ? null : snapshot.records.first,
      openFollowUps: snapshot.openFollowUps,
      stableMisconceptions: snapshot.stableMisconceptions,
      weakDimensions: snapshot.weakDimensions,
      weakPrerequisites: snapshot.weakPrerequisites,
      pendingReviews: snapshot.pendingReviews,
      nextReviewAt: snapshot.nextReviewAt,
    );
  }

  LearningAgentTargetMemory memoryForTarget(
    String? targetId, {
    String? targetLabel,
  }) {
    final normalizedTargetId = normalizeAgentSessionTargetId(targetId);
    final snapshot = query(targetId: normalizedTargetId);
    final unifiedOpenCount = records.isEmpty
        ? index.openFollowUpCountForTarget(normalizedTargetId)
        : snapshot.openFollowUps.length;
    final latestOpenQuestion = records.isEmpty
        ? index.latestOpenFollowUpQuestionForTarget(normalizedTargetId)
        : snapshot.latestOpenFollowUpQuestion;
    return LearningAgentTargetMemory(
      targetId: normalizedTargetId,
      targetLabel: targetLabel,
      sessionCount: index.countForTarget(normalizedTargetId),
      recordCount: snapshot.recordCount,
      openFollowUpCount: unifiedOpenCount,
      latestOpenFollowUpQuestion: latestOpenQuestion,
      recentRecords: snapshot.recentRecords,
      openFollowUps: snapshot.openFollowUps,
      stableMisconceptions: snapshot.stableMisconceptions,
      weakDimensions: snapshot.weakDimensions,
      weakPrerequisites: snapshot.weakPrerequisites,
      pendingReviews: snapshot.pendingReviews,
      nextReviewAt: snapshot.nextReviewAt,
    );
  }

  LearningAgentMemorySnapshot query({
    LearningAgentGoal? goal,
    String? targetId,
    Set<LearningAgentMemoryRecordType>? recordTypes,
    int recentLimit = 6,
  }) {
    final normalizedTargetId = normalizeAgentSessionTargetId(targetId);
    final filteredRecords = records
        .where(
          (record) => _matchesRecord(
            record,
            goal: goal,
            targetId: normalizedTargetId,
            recordTypes: recordTypes,
          ),
        )
        .toList(growable: false);
    final filteredRecordIds =
        filteredRecords.map((record) => record.id).toSet();
    final openFollowUps = _allOpenFollowUps()
        .where((followUp) => filteredRecordIds.contains(followUp.recordId))
        .toList(growable: false);
    final safeRecentLimit = recentLimit < 0 ? 0 : recentLimit;
    final recentRecords =
        filteredRecords.take(safeRecentLimit).toList(growable: false);
    final pendingReviews = _pendingReviews(
      records: filteredRecords,
      openFollowUps: openFollowUps,
      goal: goal,
      targetId: normalizedTargetId,
      recordTypes: recordTypes,
    );

    return LearningAgentMemorySnapshot(
      records: filteredRecords,
      recentRecords: recentRecords,
      openFollowUps: openFollowUps,
      stableMisconceptions: _stableMisconceptions(filteredRecords),
      weakDimensions: _weakDimensions(filteredRecords),
      weakPrerequisites: _weakPrerequisites(filteredRecords),
      pendingReviews: pendingReviews,
      nextReviewAt: pendingReviews.isEmpty ? null : pendingReviews.first.dueAt,
    );
  }

  List<LearningAgentMemoryRecord> recordsForType(
    LearningAgentMemoryRecordType type, {
    LearningAgentGoal? goal,
    String? targetId,
  }) {
    return query(
      goal: goal,
      targetId: targetId,
      recordTypes: {type},
      recentLimit: 0,
    ).records;
  }

  bool hasOpenFollowUp(LearningSession session) {
    return index.hasOpenFollowUp(session);
  }

  bool _matchesRecord(
    LearningAgentMemoryRecord record, {
    required LearningAgentGoal? goal,
    required String? targetId,
    required Set<LearningAgentMemoryRecordType>? recordTypes,
  }) {
    if (goal != null && !record.goals.contains(goal)) return false;
    if (targetId != null &&
        normalizeAgentSessionTargetId(record.targetId) != targetId) {
      return false;
    }
    if (recordTypes != null && !recordTypes.contains(record.type)) return false;
    return true;
  }

  List<LearningAgentOpenFollowUp> _allOpenFollowUps() {
    final handledQuestionKeys = <String>{};
    final emittedOpenKeys = <String>{};
    final openFollowUps = <LearningAgentOpenFollowUp>[];
    for (final record in records) {
      for (var index = 0; index < record.followUpQuestions.length; index += 1) {
        final question = record.followUpQuestions[index].trim();
        if (question.isEmpty) continue;
        final key = _questionKey(record.targetId, question);
        if (handledQuestionKeys.contains(key) || !emittedOpenKeys.add(key)) {
          continue;
        }
        openFollowUps.add(
          LearningAgentOpenFollowUp(
            id: '${record.id}:follow-up:$index',
            recordId: record.id,
            recordType: record.type,
            targetId: record.targetId,
            question: question,
            createdAt: record.occurredAt,
          ),
        );
      }
      for (final prompt in record.handledPrompts) {
        final normalized = prompt.trim();
        if (normalized.isEmpty) continue;
        handledQuestionKeys.add(_questionKey(record.targetId, normalized));
      }
    }
    return List.unmodifiable(openFollowUps);
  }

  List<LearningAgentStableMisconception> _stableMisconceptions(
    List<LearningAgentMemoryRecord> filteredRecords,
  ) {
    final aggregates = <String, _MisconceptionAggregate>{};
    for (final record in filteredRecords) {
      for (final misconception in record.misconceptions) {
        final aggregate = aggregates.putIfAbsent(
          misconception.key,
          () => _MisconceptionAggregate(
            label: misconception.label,
            latestAt: record.occurredAt,
          ),
        );
        aggregate.recordIds.add(record.id);
        if (record.occurredAt.isAfter(aggregate.latestAt)) {
          aggregate.latestAt = record.occurredAt;
          aggregate.label = misconception.label;
        }
      }
    }
    final stable = aggregates.entries
        .where((entry) => entry.value.recordIds.length >= 2)
        .map(
          (entry) => LearningAgentStableMisconception(
            key: entry.key,
            label: entry.value.label,
            occurrenceCount: entry.value.recordIds.length,
            latestAt: entry.value.latestAt,
          ),
        )
        .toList()
      ..sort((a, b) {
        final count = b.occurrenceCount.compareTo(a.occurrenceCount);
        if (count != 0) return count;
        return b.latestAt.compareTo(a.latestAt);
      });
    return List.unmodifiable(stable);
  }

  List<LearningAgentWeakDimensionSummary> _weakDimensions(
    List<LearningAgentMemoryRecord> filteredRecords,
  ) {
    final aggregates = <String, _WeakDimensionAggregate>{};
    for (final record in filteredRecords) {
      for (final dimension in record.weakDimensions) {
        final aggregate = aggregates.putIfAbsent(
          dimension.key,
          () => _WeakDimensionAggregate(
            label: dimension.label,
            latestAt: record.occurredAt,
          ),
        );
        aggregate.evidenceIds.add(dimension.evidenceId);
        if (record.occurredAt.isAfter(aggregate.latestAt)) {
          aggregate.latestAt = record.occurredAt;
          aggregate.label = dimension.label;
        }
      }
    }
    final dimensions = aggregates.entries
        .where((entry) => entry.value.evidenceIds.isNotEmpty)
        .map(
          (entry) => LearningAgentWeakDimensionSummary(
            key: entry.key,
            label: entry.value.label,
            occurrenceCount: entry.value.evidenceIds.length,
            latestAt: entry.value.latestAt,
          ),
        )
        .toList()
      ..sort((a, b) {
        final count = b.occurrenceCount.compareTo(a.occurrenceCount);
        if (count != 0) return count;
        return b.latestAt.compareTo(a.latestAt);
      });
    return List.unmodifiable(dimensions);
  }

  List<LearningAgentWeakPrerequisiteSummary> _weakPrerequisites(
    List<LearningAgentMemoryRecord> filteredRecords,
  ) {
    final aggregates = <String, _WeakPrerequisiteAggregate>{};
    for (final record in filteredRecords) {
      if (!record.hasOpenReview) continue;
      for (final prerequisite in record.weakPrerequisites) {
        final aggregate = aggregates.putIfAbsent(
          prerequisite.targetId,
          () => _WeakPrerequisiteAggregate(
            label: prerequisite.targetLabel,
            latestAt: record.occurredAt,
          ),
        );
        aggregate.recordIds.add(record.id);
        if (record.occurredAt.isAfter(aggregate.latestAt)) {
          aggregate.latestAt = record.occurredAt;
          aggregate.label = prerequisite.targetLabel;
        }
      }
    }
    final prerequisites = aggregates.entries
        .map(
          (entry) => LearningAgentWeakPrerequisiteSummary(
            targetId: entry.key,
            targetLabel: entry.value.label,
            occurrenceCount: entry.value.recordIds.length,
            latestAt: entry.value.latestAt,
          ),
        )
        .toList()
      ..sort((a, b) {
        final count = b.occurrenceCount.compareTo(a.occurrenceCount);
        if (count != 0) return count;
        final latest = b.latestAt.compareTo(a.latestAt);
        if (latest != 0) return latest;
        return a.targetId.compareTo(b.targetId);
      });
    return List.unmodifiable(prerequisites);
  }

  List<LearningAgentPendingReview> _pendingReviews({
    required List<LearningAgentMemoryRecord> records,
    required List<LearningAgentOpenFollowUp> openFollowUps,
    required LearningAgentGoal? goal,
    required String? targetId,
    required Set<LearningAgentMemoryRecordType>? recordTypes,
  }) {
    final openRecordIds = openFollowUps.map((item) => item.recordId).toSet();
    final pending = <LearningAgentPendingReview>[];
    for (final record in records) {
      final dueAt = record.reviewDueAt;
      final normalizedTargetId = normalizeAgentSessionTargetId(record.targetId);
      if (dueAt == null ||
          record.reviewCompletedAt != null ||
          normalizedTargetId == null) {
        continue;
      }
      if (record.followUpQuestions.isNotEmpty &&
          !openRecordIds.contains(record.id)) {
        continue;
      }
      pending.add(
        LearningAgentPendingReview(
          id: 'record:${record.id}',
          targetId: normalizedTargetId,
          dueAt: dueAt,
          recordType: record.type,
        ),
      );
    }
    final includeReviewSchedules = recordTypes == null ||
        recordTypes.contains(LearningAgentMemoryRecordType.reviewAction);
    if (includeReviewSchedules) {
      for (final schedule in reviewSchedules) {
        if (goal != null && !schedule.goals.contains(goal)) continue;
        if (targetId != null && schedule.targetId != targetId) continue;
        pending.add(
          LearningAgentPendingReview(
            id: 'schedule:${schedule.id}',
            targetId: schedule.targetId,
            dueAt: schedule.dueAt,
            recordType: LearningAgentMemoryRecordType.reviewAction,
          ),
        );
      }
    }
    pending.sort((a, b) {
      final due = a.dueAt.compareTo(b.dueAt);
      if (due != 0) return due;
      return a.id.compareTo(b.id);
    });
    return List.unmodifiable(pending);
  }
}

int _compareRecordsNewestFirst(
  LearningAgentMemoryRecord a,
  LearningAgentMemoryRecord b,
) {
  final time = b.occurredAt.compareTo(a.occurredAt);
  if (time != 0) return time;
  return a.id.compareTo(b.id);
}

String _questionKey(String? targetId, String question) {
  final normalizedTargetId = normalizeAgentSessionTargetId(targetId) ?? '';
  final normalizedQuestion =
      question.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  return '$normalizedTargetId\x00$normalizedQuestion';
}

class _MisconceptionAggregate {
  String label;
  DateTime latestAt;
  final Set<String> recordIds = <String>{};

  _MisconceptionAggregate({
    required this.label,
    required this.latestAt,
  });
}

class _WeakDimensionAggregate {
  String label;
  DateTime latestAt;
  final Set<String> evidenceIds = <String>{};

  _WeakDimensionAggregate({
    required this.label,
    required this.latestAt,
  });
}

class _WeakPrerequisiteAggregate {
  String label;
  DateTime latestAt;
  final Set<String> recordIds = <String>{};

  _WeakPrerequisiteAggregate({
    required this.label,
    required this.latestAt,
  });
}
