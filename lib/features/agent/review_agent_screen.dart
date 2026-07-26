import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/question.dart';
import '../../services/scheduling/programming_review_closure_service.dart';
import '../../services/scheduling/review_scheduler_service.dart';
import '../../shared/widgets/source_citation_block.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import '../learning/quiz_screen.dart';
import 'programming_exercise_screen.dart';

class ReviewAgentScreen extends ConsumerWidget {
  final KnowledgePoint? initialPoint;

  const ReviewAgentScreen({
    super.key,
    this.initialPoint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(todayReviewQueueProvider);
    final programmingQueueAsync = ref.watch(programmingReviewQueueProvider);
    final pointsAsync = ref.watch(practiceableKnowledgePointListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习模式')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            _refreshReviewAgentInputs(ref);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ReviewHeader(initialPoint: initialPoint),
              const SizedBox(height: 14),
              const _SectionTitle(title: '编程修复'),
              const SizedBox(height: 10),
              programmingQueueAsync.when(
                data: (items) => _ProgrammingReviewSection(items: items),
                loading: () => const _LoadingBlock(),
                error: (error, _) => KnowledgeLibraryErrorState(
                  title: '编程复习动作读取失败',
                  retryLabel: '重试读取编程复习动作',
                  diagnosticTitle: '复习模式编程动作读取失败',
                  diagnosticSuccessMessage: '已复制编程复习动作诊断',
                  diagnosticLines: _reviewDiagnosticLines(initialPoint),
                  error: error,
                  onRetry: () => ref.invalidate(
                    programmingReviewQueueProvider,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(title: '今日题目复习'),
              const SizedBox(height: 10),
              queueAsync.when(
                data: (items) => _DueReviewSection(
                  items: items,
                  initialPoint: initialPoint,
                ),
                loading: () => const _LoadingBlock(),
                error: (error, _) => KnowledgeLibraryErrorState(
                  title: '今日复习队列读取失败',
                  retryLabel: '重试读取复习队列',
                  diagnosticTitle: '复习模式今日复习队列读取失败',
                  diagnosticSuccessMessage: '已复制复习队列读取诊断',
                  diagnosticLines: _reviewDiagnosticLines(initialPoint),
                  error: error,
                  onRetry: () => _refreshReviewAgentInputs(ref),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(title: '薄弱知识点'),
              const SizedBox(height: 10),
              pointsAsync.when(
                data: (points) => _WeakPointSection(
                  points: points,
                  initialPoint: initialPoint,
                ),
                loading: () => const _LoadingBlock(),
                error: (error, _) => KnowledgeLibraryErrorState(
                  title: '薄弱知识点读取失败',
                  retryLabel: '重试读取知识点',
                  diagnosticTitle: '复习模式薄弱知识点读取失败',
                  diagnosticSuccessMessage: '已复制薄弱知识点读取诊断',
                  diagnosticLines: _reviewDiagnosticLines(initialPoint),
                  error: error,
                  onRetry: () => _refreshReviewAgentInputs(ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgrammingReviewSection extends StatelessWidget {
  final List<ProgrammingReviewQueueItem> items;

  const _ProgrammingReviewSection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyBlock(
        icon: Icons.task_alt,
        title: '暂无编程修复动作',
        subtitle: '导师或练习出现有引用的低分结果后，会在这里形成修复动作。',
      );
    }
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProgrammingReviewCard(item: item),
            ),
          )
          .toList(),
    );
  }
}

class _ProgrammingReviewCard extends ConsumerWidget {
  final ProgrammingReviewQueueItem item;

  const _ProgrammingReviewCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = item.action;
    final citationKey = action.citationIds.join('\x00');
    final chunksAsync = ref.watch(questionCitationChunksProvider(citationKey));
    final weakLabels =
        action.weakDimensions.map((dimension) => dimension.label).join('、');
    final prerequisiteLabels =
        item.prerequisiteKnowledgePoints.map((point) => point.title).join('、');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_outlined, color: AppColors.purpleDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.knowledgePoint.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${item.knowledgePoint.masteryLevel}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purpleDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ProgrammingReviewLine(label: '薄弱维度', text: weakLabels),
          if (prerequisiteLabels.isNotEmpty)
            _ProgrammingReviewLine(
              label: '缺失先修',
              text: prerequisiteLabels,
            ),
          _ProgrammingReviewLine(
            label: '下一动作',
            text: item.exercises.isNotEmpty
                ? '完成 ${item.exercises.length} 道已核验复测'
                : item.questions.isNotEmpty
                    ? '完成 ${item.questions.length} 道已核验题'
                    : '等待复测核验或补充已核验题',
          ),
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '来源依据 ${action.citationIds.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
              children: [
                chunksAsync.when(
                  data: (chunks) => Column(
                    children: chunks
                        .map(
                          (chunk) => SourceCitationBlock(
                            chunk: chunk,
                            backgroundColor: AppColors.blueLight,
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const _LoadingBlock(),
                  error: (_, __) => const Text('来源片段读取失败'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: item.isActionable
                  ? () => _startProgrammingReview(context, ref)
                  : null,
              icon: Icon(
                item.exercises.isNotEmpty ? Icons.code : Icons.quiz_outlined,
              ),
              label: Text(
                item.exercises.isNotEmpty ? '开始复测' : '开始题目复习',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startProgrammingReview(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (item.exercises.isNotEmpty) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ProgrammingExerciseScreen(
            knowledgePoint: item.knowledgePoint,
            initialExerciseId: item.exercises.first.id,
          ),
        ),
      );
    } else if (item.questions.isNotEmpty) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => QuizScreen(questions: item.questions),
        ),
      );
    }
    ref.invalidate(programmingReviewQueueProvider);
    _refreshReviewAgentInputs(ref);
  }
}

class _ProgrammingReviewLine extends StatelessWidget {
  final String label;
  final String text;

  const _ProgrammingReviewLine({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textPrimary,
          ),
          children: [
            TextSpan(
              text: '$label：',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _DueReviewSection extends ConsumerWidget {
  final List<ReviewQueueItem> items;
  final KnowledgePoint? initialPoint;

  const _DueReviewSection({
    required this.items,
    required this.initialPoint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const _EmptyBlock(
        icon: Icons.check_circle_outline,
        title: '今天没有到期复习',
        subtitle: '可以从薄弱知识点里主动练一轮。',
      );
    }

    final reviewItems = _prioritizedItems(items);
    final questionCount =
        reviewItems.fold<int>(0, (sum, item) => sum + item.questionCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.event_repeat,
                color: AppColors.blue,
                label: '知识点',
                value: items.length.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.quiz,
                color: AppColors.green,
                label: '题目',
                value: questionCount.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startTodayReview(context, ref),
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              '开始今日复习',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...reviewItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewQueueCard(item: item),
          ),
        ),
      ],
    );
  }

  Future<void> _startTodayReview(BuildContext context, WidgetRef ref) async {
    final focusedItem = _focusedReviewItem(items);
    final questions = focusedItem == null
        ? await ref
            .read(reviewSchedulerServiceProvider)
            .getTodayReviewQuestions(limit: 10)
        : focusedItem.questions.take(10).toList();
    if (questions.isEmpty || !context.mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)),
    );
    _refreshReviewAgentInputs(ref);
  }

  List<ReviewQueueItem> _prioritizedItems(List<ReviewQueueItem> items) {
    final focusId = initialPoint?.id;
    if (focusId == null) return items;

    final focused =
        items.where((item) => item.knowledgePoint.id == focusId).toList();
    if (focused.isEmpty) return items;
    final rest =
        items.where((item) => item.knowledgePoint.id != focusId).toList();
    return [...focused, ...rest];
  }

  ReviewQueueItem? _focusedReviewItem(List<ReviewQueueItem> items) {
    final focusId = initialPoint?.id;
    if (focusId == null) return null;
    for (final item in items) {
      if (item.knowledgePoint.id == focusId) return item;
    }
    return null;
  }
}

class _ReviewQueueCard extends ConsumerWidget {
  final ReviewQueueItem item;

  const _ReviewQueueCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _startItemReview(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.knowledgePoint.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.questionCount} 题 · 逾期 ${item.overdueCount} · 掌握度 ${item.knowledgePoint.masteryLevel}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startItemReview(BuildContext context, WidgetRef ref) async {
    if (item.questions.isEmpty) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(questions: item.questions)),
    );
    _refreshReviewAgentInputs(ref);
  }
}

class _WeakPointSection extends ConsumerWidget {
  final List<KnowledgePoint> points;
  final KnowledgePoint? initialPoint;

  const _WeakPointSection({
    required this.points,
    required this.initialPoint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakPoints = [...points]..sort((a, b) {
        final focusId = initialPoint?.id;
        if (focusId != null) {
          final aFocused = a.id == focusId;
          final bFocused = b.id == focusId;
          if (aFocused != bFocused) return aFocused ? -1 : 1;
        }
        final mastery = a.masteryLevel.compareTo(b.masteryLevel);
        if (mastery != 0) return mastery;
        return b.interviewRelevance.compareTo(a.interviewRelevance);
      });

    if (weakPoints.isEmpty) {
      return const _EmptyBlock(
        icon: Icons.psychology_outlined,
        title: '暂无可练习知识点',
        subtitle: '先完成来源核验，让题目进入已核验状态。',
      );
    }

    return Column(
      children: weakPoints.take(6).map((point) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _WeakPointCard(point: point),
        );
      }).toList(),
    );
  }
}

class _WeakPointCard extends ConsumerWidget {
  final KnowledgePoint point;

  const _WeakPointCard({required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _startWeakPointPractice(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                      point.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${point.masteryLevel}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                point.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: (point.masteryLevel.clamp(0, 100) / 100).toDouble(),
                  color: AppColors.green,
                  backgroundColor: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startWeakPointPractice(
      BuildContext context, WidgetRef ref) async {
    final questions = await _questionsForPoint(ref);
    if (questions.isNotEmpty) {
      if (!context.mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)),
      );
      _refreshReviewAgentInputs(ref);
      return;
    }

    final exercises = await ref
        .read(programmingExerciseRepositoryProvider)
        .getExercisesForKnowledgePoint(point.id);
    final verifiedExercises = exercises
        .where((exercise) =>
            exercise.sourceStatus == SourceStatus.verified &&
            exercise.citationIds.isNotEmpty)
        .toList();
    if (verifiedExercises.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这个知识点还没有可练习的已核验材料')),
      );
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProgrammingExerciseScreen(
          knowledgePoint: point,
          initialExerciseId: verifiedExercises.first.id,
        ),
      ),
    );
    _refreshReviewAgentInputs(ref);
  }

  Future<List<Question>> _questionsForPoint(WidgetRef ref) async {
    final allQuestions =
        await ref.read(questionRepositoryProvider).getAllQuestions();
    final matched = allQuestions.where((question) {
      return question.knowledgePointId == point.id &&
          question.sourceStatus == SourceStatus.verified;
    }).toList();
    matched.sort((a, b) {
      final aDue = a.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDue = b.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDue.compareTo(bDue);
    });
    return matched.take(8).toList();
  }
}

void _refreshReviewAgentInputs(WidgetRef ref) {
  ref.invalidate(todayReviewQueueProvider);
  ref.invalidate(programmingReviewQueueProvider);
  ref.invalidate(knowledgePointListProvider);
  ref.invalidate(evidenceBackedKnowledgePointListProvider);
  ref.invalidate(practiceableKnowledgePointListProvider);
  invalidateAgentLearningRecordProviders(ref);
}

List<String> _reviewDiagnosticLines(KnowledgePoint? initialPoint) {
  final point = initialPoint;
  return [
    '入口: 复习模式',
    '初始知识点: ${point == null ? '无' : point.title}',
    '初始知识点 ID: ${point?.id ?? '无'}',
  ];
}

class _ReviewHeader extends StatelessWidget {
  final KnowledgePoint? initialPoint;

  const _ReviewHeader({required this.initialPoint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_repeat, color: AppColors.goldDark, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              initialPoint == null
                  ? '优先处理到期复习，再补低掌握度知识点。'
                  : '优先复习“${initialPoint!.title}”，仍然只使用已核验题目。',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }
}
