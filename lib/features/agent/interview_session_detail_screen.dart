import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/learning_session.dart';
import '../../shared/widgets/source_citation_block.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'interview_session_screen.dart';
import 'review_agent_screen.dart';

class InterviewSessionDetailScreen extends ConsumerWidget {
  final LearningSession session;

  const InterviewSessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turnsAsync = ref.watch(interviewTurnsProvider(session.id));

    return Scaffold(
      appBar: AppBar(title: const Text('面试复盘')),
      body: SafeArea(
        child: turnsAsync.when(
          data: (turns) {
            if (turns.isEmpty) {
              return _EmptyReview(
                session: session,
                canResume: _hasResumePath(session, turns),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (session.endedAt == null) ...[
                  _IncompleteInterviewNotice(
                    session: session,
                    turnCount: turns.length,
                    canResume: _hasResumePath(session, turns),
                  ),
                  const SizedBox(height: 14),
                ],
                _SessionSummary(session: session, turns: turns),
                const SizedBox(height: 14),
                for (var i = 0; i < turns.length; i++) ...[
                  _TurnReviewCard(index: i + 1, turn: turns[i]),
                  if (i < turns.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
          error: (error, _) => KnowledgeLibraryErrorState(
            title: '面试复盘读取失败',
            retryLabel: '重试读取复盘',
            diagnosticTitle: '面试复盘回合读取失败',
            diagnosticSuccessMessage: '已复制面试复盘读取诊断',
            diagnosticLines: [
              '入口: 面试复盘',
              '记录 ID: ${session.id}',
              '开始时间: ${_dateText(session.startedAt)}',
            ],
            error: error,
            onRetry: () => ref.invalidate(interviewTurnsProvider(session.id)),
          ),
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  final LearningSession session;
  final List<InterviewTurn> turns;

  const _SessionSummary({
    required this.session,
    required this.turns,
  });

  @override
  Widget build(BuildContext context) {
    final averageScore = _averageScore(turns);

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
          const Text(
            '项目面试复盘',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: '${turns.length} 轮'),
              _MetaChip(label: '平均 ${averageScore.round()} / 20'),
              _MetaChip(label: _dateText(session.startedAt)),
            ],
          ),
          if (session.summary != null && session.summary!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              session.summary!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _averageScore(List<InterviewTurn> turns) {
    if (turns.isEmpty) return 0;
    final total = turns
        .map((turn) =>
            turn.accuracyScore +
            turn.projectDetailScore +
            turn.engineeringScore +
            turn.clarityScore)
        .reduce((a, b) => a + b);
    return total / turns.length;
  }
}

class _TurnReviewCard extends ConsumerWidget {
  final int index;
  final InterviewTurn turn;

  const _TurnReviewCard({
    required this.index,
    required this.turn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citationKey = turn.citationIds.join('\x00');
    final chunksAsync = ref.watch(questionCitationChunksProvider(citationKey));
    final totalScore = turn.accuracyScore +
        turn.projectDetailScore +
        turn.engineeringScore +
        turn.clarityScore;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '第 $index 轮 · $totalScore / 20',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _timeText(turn.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: turn.knowledgePointKind.label),
              if (turn.knowledgePointId != null)
                _MetaChip(label: '知识单元 ${turn.knowledgePointId}'),
              _MetaChip(label: '事实 ${turn.accuracyScore}/5'),
              _MetaChip(label: '项目 ${turn.projectDetailScore}/5'),
              _MetaChip(label: '工程 ${turn.engineeringScore}/5'),
              _MetaChip(label: '表达 ${turn.clarityScore}/5'),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: '问题'),
          const SizedBox(height: 6),
          _TextBlock(text: turn.questionText),
          const SizedBox(height: 12),
          const _SectionTitle(title: '你的回答'),
          const SizedBox(height: 6),
          _TextBlock(text: turn.userAnswer),
          const SizedBox(height: 12),
          const _SectionTitle(title: '反馈'),
          const SizedBox(height: 6),
          _TextBlock(text: turn.aiFeedback),
          const SizedBox(height: 12),
          const _SectionTitle(title: '参考回答'),
          const SizedBox(height: 6),
          _TextBlock(text: turn.referenceAnswer),
          if (turn.weakKnowledgePointIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionTitle(title: '薄弱知识点'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: turn.weakKnowledgePointIds
                  .map((id) => _MetaChip(label: id))
                  .toList(),
            ),
          ],
          if (turn.hasReviewAction) ...[
            const SizedBox(height: 12),
            const _SectionTitle(title: '下一步'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...turn.weakDimensions.map(
                  (dimension) => _MetaChip(label: dimension.label),
                ),
                _MetaChip(label: '${turn.reviewQuestionIds.length} 道复习题'),
              ],
            ),
            const SizedBox(height: 8),
            _TextBlock(text: turn.nextInterviewQuestion),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: turn.reviewQuestionIds.isEmpty
                      ? null
                      : () => _openReview(context, ref),
                  icon: const Icon(Icons.event_repeat),
                  label: const Text('开始复习'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openInterview(context, ref),
                  icon: const Icon(Icons.record_voice_over),
                  label: const Text('再次面试'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const _SectionTitle(title: '依据片段'),
          const SizedBox(height: 8),
          chunksAsync.when(
            data: (chunks) {
              if (chunks.isEmpty) {
                return const Text(
                  '暂无引用片段',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < chunks.length; i++) ...[
                    SourceCitationBlock(
                      chunk: chunks[i],
                      margin: EdgeInsets.zero,
                      backgroundColor: AppColors.blueLight,
                      contentLineHeight: 1.45,
                    ),
                    if (i < chunks.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(color: AppColors.green),
            ),
            error: (error, _) => KnowledgeLibraryErrorState(
              title: '引用片段读取失败',
              retryLabel: '重试读取引用',
              diagnosticTitle: '面试复盘引用片段读取失败',
              diagnosticSuccessMessage: '已复制面试引用读取诊断',
              diagnosticLines: [
                '入口: 面试复盘',
                '轮次: 第 $index 轮',
                '问题: ${turn.questionText}',
                '引用数量: ${turn.citationIds.length}',
                '引用 ID: ${turn.citationIds.isEmpty ? '无' : turn.citationIds.join(', ')}',
              ],
              error: error,
              onRetry: () => ref.invalidate(
                questionCitationChunksProvider(citationKey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReview(BuildContext context, WidgetRef ref) async {
    final point = await _loadKnowledgePoint(ref);
    if (point == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewAgentScreen(initialPoint: point),
      ),
    );
  }

  Future<void> _openInterview(BuildContext context, WidgetRef ref) async {
    final point = await _loadKnowledgePoint(ref);
    if (point == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterviewSessionScreen(
          initialPoint: point,
          initialFollowUpQuestion: turn.nextInterviewQuestion,
        ),
      ),
    );
  }

  Future<KnowledgePoint?> _loadKnowledgePoint(WidgetRef ref) {
    final pointId = turn.knowledgePointId;
    if (pointId == null) return Future.value(null);
    return ref
        .read(knowledgePointRepositoryProvider)
        .getKnowledgePoint(pointId);
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
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
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

class _EmptyReview extends StatelessWidget {
  final LearningSession session;
  final bool canResume;

  const _EmptyReview({required this.session, required this.canResume});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _IncompleteInterviewNotice(
          session: session,
          turnCount: 0,
          canResume: canResume,
        ),
      ),
    );
  }
}

class _IncompleteInterviewNotice extends ConsumerWidget {
  final LearningSession session;
  final int turnCount;
  final bool canResume;

  const _IncompleteInterviewNotice({
    required this.session,
    required this.turnCount,
    required this.canResume,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncomplete = session.endedAt == null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIncomplete
            ? AppColors.gold.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIncomplete ? AppColors.gold : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIncomplete ? '这次面试尚未完成' : '这次面试还没有保存回合',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isIncomplete
                ? canResume
                    ? '已保存 $turnCount 轮评分。继续后会恢复未完成的来源约束问题。'
                    : '已保存 $turnCount 轮评分。本次没有可恢复的问题，可以完成面试。'
                : '本次未产生可复盘的评分记录。',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (isIncomplete) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: canResume
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              InterviewSessionScreen(resumeSession: session),
                        ),
                      );
                    }
                  : () async {
                      final completedSession = session.copyWith(
                        endedAt: DateTime.now(),
                        xpGained: turnCount * 15,
                        summary: '完成 $turnCount 轮项目面试训练',
                      );
                      await ref
                          .read(learningSessionRepositoryProvider)
                          .updateLearningSession(completedSession);
                      invalidateAgentLearningRecordProviders(ref);
                      if (context.mounted) Navigator.of(context).pop();
                    },
              icon: Icon(canResume ? Icons.play_arrow : Icons.check),
              label: Text(canResume ? '继续面试' : '完成面试'),
            ),
          ],
        ],
      ),
    );
  }
}

bool _hasResumePath(LearningSession session, List<InterviewTurn> turns) {
  if (session.endedAt != null) return false;
  final targetIds =
      session.targetId?.split('\x00').where((id) => id.isNotEmpty).toSet() ??
          const <String>{};
  if (targetIds.isEmpty) return false;

  final pointCounts = <String, int>{};
  for (final turn in turns) {
    final pointId = turn.knowledgePointId;
    if (pointId == null || pointId.isEmpty) continue;
    pointCounts[pointId] = (pointCounts[pointId] ?? 0) + 1;
  }
  final latest = turns.isEmpty ? null : turns.last;
  if (latest != null &&
      latest.knowledgePointId != null &&
      latest.nextInterviewQuestion.trim().isNotEmpty &&
      pointCounts[latest.knowledgePointId!] == 1) {
    return true;
  }
  return targetIds.any((id) => !pointCounts.containsKey(id));
}

String _dateText(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _timeText(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
