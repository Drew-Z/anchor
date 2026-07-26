import '../../data/models/learning_session.dart';
import 'agent_learning_session_summary.dart';
import 'agent_session_target_id.dart';
import 'learning_agent_planner_service.dart';
import 'learning_agent_trace.dart';

class AgentSessionSummaryRecord {
  final String title;
  final LearningAgentGoal? goal;
  final String? target;
  final String? criteria;
  final String? confirmedCriteria;
  final String? activeQuestion;
  final String? nextQuestion;
  final String? note;
  final List<String> traceLines;
  final List<String> lines;

  const AgentSessionSummaryRecord({
    required this.title,
    required this.goal,
    required this.target,
    required this.criteria,
    required this.confirmedCriteria,
    required this.activeQuestion,
    required this.nextQuestion,
    required this.note,
    required this.traceLines,
    required this.lines,
  });

  factory AgentSessionSummaryRecord.fromSession(LearningSession session) {
    final lines = (session.summary ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final title = lines.isEmpty ? session.mode.label : lines.first;

    return AgentSessionSummaryRecord(
      title: title,
      goal: _goalFromTitle(title),
      target: _lineValue(lines, '目标:'),
      criteria: _lineValue(lines, '成功标准:'),
      confirmedCriteria: _lineValue(lines, '已确认:'),
      activeQuestion: _multiLineValue(
        lines,
        '本轮追问:',
        stopPrefixes: const ['下次追问:', learningAgentTraceHeader, '复盘:'],
      ),
      nextQuestion: _multiLineValue(
        lines,
        '下次追问:',
        stopPrefixes: const [learningAgentTraceHeader, '复盘:'],
      ),
      note: _multiLineValue(
        lines,
        '复盘:',
        stopPrefixes: const [learningAgentTraceHeader],
      ),
      traceLines: _traceLines(lines),
      lines: lines.isEmpty ? [session.mode.label] : lines,
    );
  }

  static LearningAgentGoal? _goalFromTitle(String title) {
    for (final goal in LearningAgentGoal.values) {
      if (title == goal.label || title.startsWith('${goal.label} ·')) {
        return goal;
      }
    }
    return null;
  }

  static String? _lineValue(List<String> lines, String prefix) {
    for (final line in lines) {
      if (line.startsWith(prefix)) {
        final value = line.substring(prefix.length).trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  static String? _multiLineValue(
    List<String> lines,
    String prefix, {
    List<String> stopPrefixes = const [],
  }) {
    final start = lines.indexWhere((line) => line.startsWith(prefix));
    if (start == -1) return null;

    final values = <String>[lines[start].substring(prefix.length).trim()];
    for (final line in lines.skip(start + 1)) {
      if (stopPrefixes.any((prefix) => line.startsWith(prefix))) break;
      values.add(line);
    }
    final text = values.where((line) => line.isNotEmpty).join('\n');
    return text.isEmpty ? null : text;
  }

  static List<String> _traceLines(List<String> lines) {
    final start = lines.indexWhere(
      (line) => line.startsWith(learningAgentTraceHeader),
    );
    if (start == -1) return const [];

    final traceLines = <String>[];
    final firstLine =
        lines[start].substring(learningAgentTraceHeader.length).trim();
    if (firstLine.isNotEmpty) traceLines.add(firstLine);

    for (final line in lines.skip(start + 1)) {
      if (line.startsWith('复盘:')) break;
      traceLines.add(line);
    }
    return traceLines.where((line) => line.isNotEmpty).toList();
  }
}

class AgentSessionGoalIndex {
  final Map<LearningAgentGoal, int> _countsByGoal;

  AgentSessionGoalIndex(List<LearningSession> sessions)
      : _countsByGoal = _buildCountsByGoal(sessions);

  Map<LearningAgentGoal, int> get countsByGoal {
    return _countsByGoal;
  }

  int countForGoal(LearningAgentGoal goal) {
    return _countsByGoal[goal] ?? 0;
  }

  static Map<LearningAgentGoal, int> _buildCountsByGoal(
    List<LearningSession> sessions,
  ) {
    final counts = <LearningAgentGoal, int>{};
    for (final session in sessions) {
      final goal = AgentSessionSummaryRecord.fromSession(session).goal;
      if (goal == null) continue;
      counts[goal] = (counts[goal] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }
}

class AgentSessionLatestRecord {
  final String sessionId;
  final String title;
  final LearningAgentGoal goal;
  final String? target;
  final DateTime startedAt;

  const AgentSessionLatestRecord({
    required this.sessionId,
    required this.title,
    required this.goal,
    required this.target,
    required this.startedAt,
  });
}

class AgentSessionMemoryIndex {
  final List<LearningSession> sessions;
  final AgentSessionGoalIndex goals;
  final AgentSessionFollowUpIndex followUps;

  AgentSessionMemoryIndex(List<LearningSession> sessions)
      : this._(List.unmodifiable(_sessionsByStartedDesc(sessions)));

  AgentSessionMemoryIndex._(List<LearningSession> sessions)
      : sessions = sessions,
        goals = AgentSessionGoalIndex(sessions),
        followUps = AgentSessionFollowUpIndex(sessions);

  int get totalCount {
    return sessions.length;
  }

  int countForGoal(LearningAgentGoal goal) {
    return goals.countForGoal(goal);
  }

  int countForTarget(String? targetId) {
    final normalizedTargetId = normalizeAgentSessionTargetId(targetId);
    if (normalizedTargetId == null) return 0;
    return sessions.where((session) {
      return normalizeAgentSessionTargetId(session.targetId) ==
          normalizedTargetId;
    }).length;
  }

  int get openFollowUpCount {
    return followUps.openFollowUpCount;
  }

  int openFollowUpCountForGoal(LearningAgentGoal goal) {
    return followUps.openFollowUpCountForGoal(goal);
  }

  int openFollowUpCountForTarget(String? targetId) {
    return followUps.openFollowUpCountForTarget(targetId);
  }

  bool hasOpenFollowUp(LearningSession session) {
    return followUps.hasOpenFollowUp(session);
  }

  LearningSession? latestSessionForGoal(LearningAgentGoal goal) {
    for (final session in sessions) {
      final record = AgentSessionSummaryRecord.fromSession(session);
      if (record.goal != goal) continue;
      return session;
    }
    return null;
  }

  AgentSessionLatestRecord? latestRecordForGoal(LearningAgentGoal goal) {
    final session = latestSessionForGoal(goal);
    if (session == null) return null;

    final record = AgentSessionSummaryRecord.fromSession(session);
    return AgentSessionLatestRecord(
      sessionId: session.id,
      title: record.title,
      goal: goal,
      target: record.target,
      startedAt: session.startedAt,
    );
  }

  String? latestOpenFollowUpQuestionForTarget(String? targetId) {
    final normalizedTargetId = normalizeAgentSessionTargetId(targetId);
    if (normalizedTargetId == null) return null;
    for (final session in sessions) {
      if (normalizeAgentSessionTargetId(session.targetId) !=
          normalizedTargetId) {
        continue;
      }
      if (!hasOpenFollowUp(session)) continue;
      final question =
          AgentSessionSummaryRecord.fromSession(session).nextQuestion?.trim();
      if (question != null && question.isNotEmpty) return question;
    }
    return null;
  }
}

class AgentSessionFollowUpIndex {
  final Map<String, bool> _openBySessionId;
  final int _openFollowUpCount;
  final Map<LearningAgentGoal, int> _openCountByGoal;
  final Map<String, int> _openCountByTarget;

  AgentSessionFollowUpIndex(List<LearningSession> sessions)
      : this._(
          List.unmodifiable(_sessionsByStartedDesc(sessions)),
          _buildOpenFollowUpMap(sessions),
        );

  AgentSessionFollowUpIndex._(
    List<LearningSession> sessions,
    Map<String, bool> openBySessionId,
  )   : _openBySessionId = openBySessionId,
        _openFollowUpCount =
            openBySessionId.values.where((isOpen) => isOpen).length,
        _openCountByGoal = _buildOpenCountByGoal(
          sessions,
          openBySessionId,
        ),
        _openCountByTarget = _buildOpenCountByTarget(
          sessions,
          openBySessionId,
        );

  int get openFollowUpCount {
    return _openFollowUpCount;
  }

  bool hasOpenFollowUp(LearningSession session) {
    return _openBySessionId[session.id] ?? false;
  }

  int openFollowUpCountForGoal(LearningAgentGoal goal) {
    return _openCountByGoal[goal] ?? 0;
  }

  int openFollowUpCountForTarget(String? targetId) {
    final normalizedTargetId = normalizeAgentSessionTargetId(targetId);
    if (normalizedTargetId == null) return 0;
    return _openCountByTarget[normalizedTargetId] ?? 0;
  }

  static Map<String, bool> _buildOpenFollowUpMap(
    List<LearningSession> sessions,
  ) {
    final sorted = _sessionsByStartedDesc(sessions);
    final handledQuestions = <String>{};
    final openBySessionId = <String, bool>{};

    for (final session in sorted) {
      final record = AgentSessionSummaryRecord.fromSession(session);
      final nextQuestion = record.nextQuestion?.trim();
      if (nextQuestion != null && nextQuestion.isNotEmpty) {
        openBySessionId[session.id] = !handledQuestions.contains(
          _followUpKey(session.targetId, nextQuestion),
        );
      }

      final activeQuestion = record.activeQuestion?.trim();
      if (activeQuestion != null && activeQuestion.isNotEmpty) {
        handledQuestions.add(_followUpKey(session.targetId, activeQuestion));
      }
    }

    return Map.unmodifiable(openBySessionId);
  }

  static Map<LearningAgentGoal, int> _buildOpenCountByGoal(
    List<LearningSession> sessions,
    Map<String, bool> openBySessionId,
  ) {
    final counts = <LearningAgentGoal, int>{};
    for (final session in sessions) {
      if (!(openBySessionId[session.id] ?? false)) continue;
      final goal = AgentSessionSummaryRecord.fromSession(session).goal;
      if (goal == null) continue;
      counts[goal] = (counts[goal] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  static Map<String, int> _buildOpenCountByTarget(
    List<LearningSession> sessions,
    Map<String, bool> openBySessionId,
  ) {
    final counts = <String, int>{};
    for (final session in sessions) {
      if (!(openBySessionId[session.id] ?? false)) continue;
      final targetId = normalizeAgentSessionTargetId(session.targetId);
      if (targetId == null) continue;
      counts[targetId] = (counts[targetId] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  static String _followUpKey(String? targetId, String question) {
    final normalizedTargetId = normalizeAgentSessionTargetId(targetId) ?? '';
    return '$normalizedTargetId\x00${question.trim()}';
  }
}

List<LearningSession> _sessionsByStartedDesc(List<LearningSession> sessions) {
  return [...sessions]..sort(
      (a, b) => b.startedAt.compareTo(a.startedAt),
    );
}

class AgentSessionCompletionMatcher {
  const AgentSessionCompletionMatcher._();

  static bool matchesCompletedPoint({
    required LearningSession session,
    required LearningSessionMode mode,
    required String pointId,
    String? followUpQuestion,
  }) {
    if (session.mode != mode || session.endedAt == null) return false;
    final matchesPoint = _matchesPoint(session, mode, pointId);
    if (!matchesPoint) return false;

    final question = followUpQuestion?.trim();
    if (question == null || question.isEmpty) return true;
    return _summaryHasFollowUpQuestion(session.summary, question);
  }

  static bool _matchesPoint(
    LearningSession session,
    LearningSessionMode mode,
    String pointId,
  ) {
    if (mode == LearningSessionMode.interview) {
      final pointIds =
          session.targetId?.split('\x00').where((id) => id.isNotEmpty).toSet();
      return pointIds?.contains(pointId) ?? false;
    }
    return session.targetId == pointId;
  }

  static bool _summaryHasFollowUpQuestion(
    String? summary,
    String question,
  ) {
    return followUpQuestionFromLearningSessionSummary(summary) == question;
  }
}
