import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../services/agent/agent_session_memory_index.dart';
import '../../services/agent/agent_session_target_id.dart';
import '../../services/agent/learning_agent_runtime_contracts.dart';
import '../knowledge_base/knowledge_base_screen.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'agent_session_history_screen.dart';
import 'interview_session_screen.dart';
import 'tutor_session_screen.dart';

class AgentSessionDetailScreen extends ConsumerWidget {
  final LearningSession session;

  const AgentSessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = AgentSessionSummaryRecord.fromSession(session);
    final targetPointAsync = session.targetId == null
        ? null
        : ref.watch(knowledgePointProvider(session.targetId!));
    final followUpOpenAsync = ref.watch(agentSessionMemoryIndexProvider);
    final hasOpenFollowUp = followUpOpenAsync.maybeWhen<bool?>(
      data: (memory) => memory.hasOpenFollowUp(session),
      orElse: () => null,
    );
    final openFollowUpCount = followUpOpenAsync.maybeWhen<int?>(
      data: (memory) => _openFollowUpCount(memory, session, data),
      orElse: () => null,
    );
    final targetSessionCount = followUpOpenAsync.maybeWhen<int?>(
      data: (memory) => _targetSessionCount(memory, session),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Session 复盘')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SessionSummaryHero(
              session: session,
              data: data,
              hasOpenFollowUp: hasOpenFollowUp,
            ),
            const SizedBox(height: 14),
            ..._goalHistorySection(
              context,
              session,
              data,
              hasOpenFollowUp,
              openFollowUpCount,
              targetSessionCount,
            ),
            ..._knowledgePointSection(
              context,
              ref,
              targetPointAsync,
              data,
              session,
              hasOpenFollowUp,
            ),
            _DetailCard(
              title: '本轮目标',
              child: _TextBlock(text: data.target ?? '未记录目标'),
            ),
            const SizedBox(height: 12),
            _DetailCard(
              title: '成功标准',
              child: _TextBlock(text: data.criteria ?? '未记录成功标准'),
            ),
            const SizedBox(height: 12),
            if (data.confirmedCriteria != null) ...[
              _DetailCard(
                title: '已确认标准',
                child: _TextBlock(text: data.confirmedCriteria!),
              ),
              const SizedBox(height: 12),
            ],
            if (data.activeQuestion != null) ...[
              _DetailCard(
                title: '本轮追问',
                child: _TextBlock(text: data.activeQuestion!),
              ),
              const SizedBox(height: 12),
            ],
            if (data.nextQuestion != null) ...[
              _DetailCard(
                title: _followUpStatusTitle(hasOpenFollowUp),
                child: _TextBlock(text: data.nextQuestion!),
              ),
              const SizedBox(height: 12),
            ],
            _DetailCard(
              title: '复盘笔记',
              child: _TextBlock(text: data.note ?? '暂无复盘笔记'),
            ),
            const SizedBox(height: 12),
            if (data.traceLines.isNotEmpty) ...[
              _DetailCard(
                title: 'Agent Trace',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.traceLines
                      .map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _TextBlock(text: line),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _DetailCard(
              title: '完整摘要',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.lines
                    .map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _TextBlock(text: line),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _knowledgePointSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<KnowledgePoint?>? pointAsync,
    AgentSessionSummaryRecord data,
    LearningSession session,
    bool? hasOpenFollowUp,
  ) {
    if (pointAsync == null) return const [];
    final targetId = session.targetId;
    if (targetId == null || targetId.isEmpty) return const [];

    return pointAsync.when<List<Widget>>(
      data: (point) {
        if (point == null) return const [];
        return [
          _KnowledgePointLinkCard(
            point: point,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KnowledgePointDetailScreen(point: point),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (hasOpenFollowUp == true &&
              data.nextQuestion != null &&
              data.nextQuestion!.trim().isNotEmpty) ...[
            Builder(builder: (context) {
              final question = data.nextQuestion!.trim();
              return _FollowUpActionCard(
                point: point,
                question: question,
                onTutor: () => _runFollowUpAction(
                  context,
                  ref,
                  point,
                  question,
                  data,
                  actionLabel: '导师追问',
                  mode: LearningSessionMode.tutor,
                  openAction: () {
                    return Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TutorSessionScreen(
                          initialPoint: point,
                          initialFollowUpQuestion: question,
                        ),
                      ),
                    );
                  },
                ),
                onInterview: () => _runFollowUpAction(
                  context,
                  ref,
                  point,
                  question,
                  data,
                  actionLabel: '面试追问',
                  mode: LearningSessionMode.interview,
                  openAction: () {
                    return Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InterviewSessionScreen(
                          initialPoint: point,
                          initialFollowUpQuestion: question,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ];
      },
      loading: () => const [
        _InlineStatusCard(message: '正在读取关联知识点...'),
        SizedBox(height: 12),
      ],
      error: (error, _) => [
        KnowledgeLibraryErrorState(
          title: '关联知识点读取失败',
          retryLabel: '重试读取知识点',
          diagnosticTitle: 'Agent Session 详情关联知识点读取失败',
          diagnosticSuccessMessage: '已复制关联知识点读取诊断',
          diagnosticLines: [
            '入口: Agent Session 详情',
            '记录 ID: ${session.id}',
            '目标 ID: $targetId',
            '目标: ${data.target ?? '未记录目标'}',
            '学习目标: ${data.goal?.label ?? '未记录'}',
          ],
          error: error,
          onRetry: () => ref.invalidate(knowledgePointProvider(targetId)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _goalHistorySection(
    BuildContext context,
    LearningSession session,
    AgentSessionSummaryRecord data,
    bool? hasOpenFollowUp,
    int? openFollowUpCount,
    int? targetSessionCount,
  ) {
    final goal = data.goal;
    if (goal == null) return const [];
    final targetId = normalizeAgentSessionTargetId(session.targetId);
    final targetLabel = data.target;

    return [
      _GoalHistoryActionCard(
        goal: goal,
        targetId: targetId,
        targetLabel: targetLabel,
        hasOpenFollowUp: hasOpenFollowUp == true,
        openFollowUpCount: openFollowUpCount,
        targetSessionCount: targetSessionCount,
        onOpenHistory: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AgentSessionHistoryScreen(initialGoal: goal),
            ),
          );
        },
        onOpenFollowUps: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AgentSessionHistoryScreen(
                initialGoal: goal,
                initialOnlyWithFollowUp: true,
              ),
            ),
          );
        },
        onOpenTargetHistory: targetId == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AgentSessionHistoryScreen(
                      initialGoal: goal,
                      initialTargetId: targetId,
                      initialTargetLabel: targetLabel,
                    ),
                  ),
                );
              },
        onOpenTargetFollowUps: targetId == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AgentSessionHistoryScreen(
                      initialGoal: goal,
                      initialOnlyWithFollowUp: true,
                      initialTargetId: targetId,
                      initialTargetLabel: targetLabel,
                    ),
                  ),
                );
              },
      ),
      const SizedBox(height: 12),
    ];
  }

  int? _targetSessionCount(
    AgentSessionMemoryIndex memory,
    LearningSession session,
  ) {
    final targetId = normalizeAgentSessionTargetId(session.targetId);
    if (targetId == null) return null;
    return memory.countForTarget(targetId);
  }

  int _openFollowUpCount(
    AgentSessionMemoryIndex memory,
    LearningSession session,
    AgentSessionSummaryRecord data,
  ) {
    final targetId = normalizeAgentSessionTargetId(session.targetId);
    if (targetId != null) {
      return memory.openFollowUpCountForTarget(targetId);
    }
    final goal = data.goal;
    if (goal != null) {
      return memory.openFollowUpCountForGoal(goal);
    }
    return memory.openFollowUpCount;
  }

  void _refreshLearningRecords(WidgetRef ref) {
    invalidateAgentLearningRecordProviders(ref);
  }

  Future<void> _runFollowUpAction(
    BuildContext context,
    WidgetRef ref,
    KnowledgePoint point,
    String question,
    AgentSessionSummaryRecord data, {
    required String actionLabel,
    required LearningSessionMode mode,
    required Future<Object?> Function() openAction,
  }) async {
    final beforeCount = await _completedSessionCount(
      ref,
      mode,
      point.id,
      question,
    );
    if (!context.mounted) {
      _refreshLearningRecords(ref);
      return;
    }

    await openAction();
    if (!context.mounted) return;

    final afterCount = await _completedSessionCount(
      ref,
      mode,
      point.id,
      question,
    );
    if (afterCount <= beforeCount) {
      _refreshLearningRecords(ref);
      if (context.mounted) {
        _showFollowUpMessage(
          context,
          '还没有检测到完成的$actionLabel，追问仍保持未处理。',
        );
      }
      return;
    }

    try {
      await _recordFollowUpHandled(
        ref,
        point,
        question,
        data,
        actionLabel,
      );
      if (!context.mounted) return;
      _showFollowUpMessage(
        context,
        '已记录为已处理追问。',
      );
    } catch (e) {
      if (!context.mounted) return;
      _showFollowUpMessage(context, '追问处理记录保存失败: $e');
    }
  }

  void _showFollowUpMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<int> _completedSessionCount(
    WidgetRef ref,
    LearningSessionMode mode,
    String pointId,
    String question,
  ) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return 0;
    final sessions =
        await ref.read(learningSessionRepositoryProvider).getLearningSessions();
    return sessions
        .where(
          (session) => AgentSessionCompletionMatcher.matchesCompletedPoint(
            session: session,
            mode: mode,
            pointId: pointId,
            followUpQuestion: trimmed,
          ),
        )
        .length;
  }

  Future<void> _recordFollowUpHandled(
    WidgetRef ref,
    KnowledgePoint point,
    String question,
    AgentSessionSummaryRecord data,
    String actionLabel,
  ) async {
    final now = DateTime.now();
    final goalLabel = data.goal?.label ?? 'Agent Session';
    final lines = [
      '$goalLabel · 处理历史追问',
      '目标: ${point.title}',
      '成功标准: 1/1',
      '已确认: 已通过$actionLabel继续处理历史问题。',
      '本轮追问: $question',
      '复盘: 从 Agent Session 复盘详情进入$actionLabel。',
    ];

    await ref.read(learningSessionRepositoryProvider).insertLearningSession(
          LearningSession(
            id: now.microsecondsSinceEpoch.toString(),
            mode: LearningSessionMode.agentSession,
            targetId: point.id,
            startedAt: now,
            endedAt: now,
            summary: lines.join('\n'),
          ),
        );
    _refreshLearningRecords(ref);
  }

  String _followUpStatusTitle(bool? hasOpenFollowUp) {
    if (hasOpenFollowUp == null) return '下次追问';
    return hasOpenFollowUp ? '未处理追问' : '已处理追问';
  }
}

class _SessionSummaryHero extends StatelessWidget {
  final LearningSession session;
  final AgentSessionSummaryRecord data;
  final bool? hasOpenFollowUp;

  const _SessionSummaryHero({
    required this.session,
    required this.data,
    required this.hasOpenFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: session.mode.label),
              if (data.goal != null) _MetaChip(label: data.goal!.label),
              _MetaChip(label: '开始 ${_dateTimeText(session.startedAt)}'),
              if (session.endedAt != null)
                _MetaChip(label: '完成 ${_dateTimeText(session.endedAt!)}'),
              if (data.nextQuestion != null)
                _MetaChip(label: _followUpMetaLabel(hasOpenFollowUp)),
            ],
          ),
        ],
      ),
    );
  }

  String _followUpMetaLabel(bool? hasOpenFollowUp) {
    if (hasOpenFollowUp == null) return '追问状态读取中';
    return hasOpenFollowUp ? '有未处理追问' : '追问已处理';
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _GoalHistoryActionCard extends StatelessWidget {
  final LearningAgentGoal goal;
  final String? targetId;
  final String? targetLabel;
  final bool hasOpenFollowUp;
  final int? openFollowUpCount;
  final int? targetSessionCount;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenFollowUps;
  final VoidCallback? onOpenTargetHistory;
  final VoidCallback? onOpenTargetFollowUps;

  const _GoalHistoryActionCard({
    required this.goal,
    required this.targetId,
    required this.targetLabel,
    required this.hasOpenFollowUp,
    required this.openFollowUpCount,
    required this.targetSessionCount,
    required this.onOpenHistory,
    required this.onOpenFollowUps,
    required this.onOpenTargetHistory,
    required this.onOpenTargetFollowUps,
  });

  @override
  Widget build(BuildContext context) {
    final target = targetLabel?.trim();
    final targetText = target == null || target.isEmpty ? '当前目标' : target;
    final hasTarget = targetId != null;
    final followUpCount = openFollowUpCount;
    final followUpLabel = followUpCount == null || followUpCount <= 0
        ? '查看未处理追问'
        : '查看 $followUpCount 条未处理追问';
    final targetCount = targetSessionCount;
    final targetHistoryLabel = targetCount == null || targetCount <= 0
        ? '查看本目标记录'
        : '查看本目标 $targetCount 条记录';
    final historyButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.greenDark,
      side: const BorderSide(color: AppColors.green),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    final followUpButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.blueDark,
      side: const BorderSide(color: AppColors.blue),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '同目标历史',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasTarget
                ? '回到“${goal.label}”历史，或只看“$targetText”的复盘和追问。'
                : '回到“${goal.label}”的 Agent Session 历史，串联复盘和追问。',
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenHistory,
                icon: const Icon(Icons.history),
                label: const Text(
                  '查看同目标历史',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: historyButtonStyle,
              ),
              if (onOpenTargetHistory != null)
                OutlinedButton.icon(
                  onPressed: onOpenTargetHistory,
                  icon: const Icon(Icons.track_changes),
                  label: Text(
                    targetHistoryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: historyButtonStyle,
                ),
              if (hasOpenFollowUp)
                OutlinedButton.icon(
                  onPressed: onOpenTargetFollowUps ?? onOpenFollowUps,
                  icon: const Icon(Icons.question_answer_outlined),
                  label: Text(
                    followUpLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: followUpButtonStyle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KnowledgePointLinkCard extends StatelessWidget {
  final KnowledgePoint point;
  final VoidCallback onTap;

  const _KnowledgePointLinkCard({
    required this.point,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '掌握度 ${point.masteryLevel}% · 难度 ${point.difficulty} · 面试相关 ${point.interviewRelevance}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  final String message;

  const _InlineStatusCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FollowUpActionCard extends StatefulWidget {
  final KnowledgePoint point;
  final String question;
  final Future<void> Function() onTutor;
  final Future<void> Function() onInterview;

  const _FollowUpActionCard({
    required this.point,
    required this.question,
    required this.onTutor,
    required this.onInterview,
  });

  @override
  State<_FollowUpActionCard> createState() => _FollowUpActionCardState();
}

class _FollowUpActionCardState extends State<_FollowUpActionCard> {
  bool _isRunning = false;

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '继续这条追问',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.question,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isRunning ? null : () => _runAction(widget.onTutor),
                  icon: const Icon(Icons.school),
                  label: const Text(
                    '导师追问',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueDark,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isRunning ? null : () => _runAction(widget.onInterview),
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text(
                    '面试追问',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.greenDark,
                    side: const BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;

  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

String _dateTimeText(DateTime value) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
