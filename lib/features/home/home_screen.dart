import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/deck.dart';
import '../../data/models/user_stats.dart';
import '../ingestion/ingestion_screen.dart';
import '../learning/quiz_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final mode = ref.watch(learningModeProvider);

    // Determine if we're showing empty state to control FAB visibility
    final hasContent = mode == LearningMode.random
        ? ref.watch(verifiedQuestionsProvider).maybeWhen(
              data: (questions) => questions.isNotEmpty,
              orElse: () => true, // Show FAB during loading/error
            )
        : ref.watch(deckListProvider).maybeWhen(
              data: (decks) => decks.isNotEmpty,
              orElse: () => true, // Show FAB during loading/error
            );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏：模式切换 + 统计
            _buildTopBar(context, ref, statsAsync, mode),
            // 每日目标进度条
            _buildDailyGoalBar(statsAsync),
            _buildTodayReviewBanner(context, ref),
            // 内容区
            Expanded(
              child: mode == LearningMode.random
                  ? _buildRandomMode(context, ref)
                  : _buildKnowledgePointMode(context, ref),
            ),
          ],
        ),
      ),
      floatingActionButton: hasContent
          ? FloatingActionButton.extended(
              heroTag: 'home-add-content',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IngestionScreen()),
                );
              },
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                '添加内容',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildTodayReviewBanner(BuildContext context, WidgetRef ref) {
    final reviewQueueAsync = ref.watch(todayReviewQueueProvider);
    return reviewQueueAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final questionCount = items.fold<int>(
          0,
          (sum, item) => sum + item.questionCount,
        );
        final topTitles =
            items.take(3).map((item) => item.knowledgePoint.title).join('、');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今日复习 · ${items.length} 个知识点 · $questionCount 题',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topTitles,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _startTodayReview(context, ref),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text(
                      '复习',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _startTodayReview(BuildContext context, WidgetRef ref) async {
    final questions = await ref
        .read(reviewSchedulerServiceProvider)
        .getTodayReviewQuestions(limit: 10);
    if (questions.isEmpty || !context.mounted) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)),
    );
    _refreshLearningState(ref);
  }

  void _refreshLearningState(WidgetRef ref, {String? deckId}) {
    ref.invalidate(todayReviewQueueProvider);
    ref.invalidate(deckListProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    ref.invalidate(knowledgePointListProvider);
    ref.invalidate(evidenceBackedKnowledgePointListProvider);
    ref.invalidate(practiceableKnowledgePointListProvider);
    if (deckId != null && deckId.isNotEmpty) {
      ref.invalidate(deckQuestionsProvider(deckId));
      ref.invalidate(verifiedDeckQuestionsProvider(deckId));
    }
  }

  // ============ 顶部栏 ============

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserStats> statsAsync,
    LearningMode mode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Two-state responsive layout: single row when spacious, wrap when tight
          final needsWrap = constraints.maxWidth < 500;
          final statSpacing = needsWrap ? 4.0 : 12.0;

          if (needsWrap) {
            // Narrow or large text: two rows, mode left-aligned, stats right-aligned
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mode selector row
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _showModeSelector(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mode == LearningMode.random
                                ? Icons.shuffle
                                : Icons.list_alt,
                            size: 18,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mode == LearningMode.random ? '随机' : '知识点',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Stats row
                statsAsync.when(
                  data: (stats) {
                    final heartColor = stats.hearts <= 0
                        ? AppColors.red
                        : (stats.hearts <= 1
                            ? AppColors.streakOrange
                            : AppColors.heartRed);
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        runAlignment: WrapAlignment.end,
                        spacing: statSpacing,
                        runSpacing: 4,
                        children: [
                          _StatChip(
                            icon: Icons.local_fire_department,
                            iconColor: AppColors.streakOrange,
                            value: stats.streak.toString(),
                            isCompact: true,
                          ),
                          _StatChip(
                            icon: Icons.diamond,
                            iconColor: AppColors.blue,
                            value: stats.xp.toString(),
                            isCompact: true,
                          ),
                          _StatChip(
                            icon: stats.hearts <= 1
                                ? Icons.favorite
                                : Icons.favorite,
                            iconColor: heartColor,
                            value: '${stats.hearts}/${stats.maxHearts}',
                            isCompact: true,
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 24),
                  error: (_, __) => const SizedBox(height: 24),
                ),
              ],
            );
          }

          // Wide layout: single row with spacer, left mode / right stats
          return Row(
            children: [
              // 模式切换器（左上角）
              GestureDetector(
                onTap: () => _showModeSelector(context, ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode == LearningMode.random
                            ? Icons.shuffle
                            : Icons.list_alt,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mode == LearningMode.random ? '随机模式' : '知识点模式',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 统计
              statsAsync.when(
                data: (stats) {
                  final heartColor = stats.hearts <= 0
                      ? AppColors.red
                      : (stats.hearts <= 1
                          ? AppColors.streakOrange
                          : AppColors.heartRed);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatChip(
                        icon: Icons.local_fire_department,
                        iconColor: AppColors.streakOrange,
                        value: stats.streak.toString(),
                        isCompact: false,
                      ),
                      SizedBox(width: statSpacing),
                      _StatChip(
                        icon: Icons.diamond,
                        iconColor: AppColors.blue,
                        value: stats.xp.toString(),
                        isCompact: false,
                      ),
                      SizedBox(width: statSpacing),
                      _StatChip(
                        icon:
                            stats.hearts <= 1 ? Icons.favorite : Icons.favorite,
                        iconColor: heartColor,
                        value: '${stats.hearts}/${stats.maxHearts}',
                        isCompact: false,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 24),
                error: (_, __) => const SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 每日目标进度条
  Widget _buildDailyGoalBar(AsyncValue<UserStats> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final progress = (stats.todayXp / stats.dailyGoal).clamp(0.0, 1.0);
        final isComplete = stats.todayXp >= stats.dailyGoal;
        if (isComplete) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.flag, size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${stats.todayXp}/${stats.dailyGoal}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showModeSelector(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(learningModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择学习模式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              _ModeOption(
                icon: Icons.shuffle,
                iconColor: AppColors.blue,
                title: '随机模式',
                subtitle: '从题库随机抽题闯关，每次都不一样',
                isSelected: currentMode == LearningMode.random,
                onTap: () {
                  ref
                      .read(learningModeProvider.notifier)
                      .setMode(LearningMode.random);
                  Navigator.pop(context);
                },
              ),
              _ModeOption(
                icon: Icons.list_alt,
                iconColor: AppColors.green,
                title: '知识点模式',
                subtitle: '按题包逐个学习，巩固特定内容',
                isSelected: currentMode == LearningMode.knowledgePoint,
                onTap: () {
                  ref
                      .read(learningModeProvider.notifier)
                      .setMode(LearningMode.knowledgePoint);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ============ 随机模式 ============

  Widget _buildRandomMode(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(verifiedQuestionsProvider);
    final completedLevels = ref.watch(randomLevelProgressProvider);

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildRandomPath(context, ref, completedLevels);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (err, _) => Center(child: Text('加载失败: $err')),
    );
  }

  Widget _buildRandomPath(
    BuildContext context,
    WidgetRef ref,
    int completedLevels,
  ) {
    return CustomScrollView(
      slivers: [
        // 标题区
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                const Text(
                  '学习路径',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已通关 $completedLevels 关',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // 无限关卡列表（SliverList 懒加载，只构建可见项）
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final level = index + 1;
            // S型波浪布局：使用正弦函数实现连续曲线
            final waveOffset = math.sin(index * 0.7) * 140;

            // 根据相邻单元的水平距离动态调整垂直间距：
            // 水平距离大（图标分得开）→ 垂直间距小
            // 水平距离小（图标靠得近）→ 垂直间距大
            final nextOffset = math.sin((index + 1) * 0.7) * 140;
            final horizontalDiff = (nextOffset - waveOffset).abs();
            double verticalSpacing = (14 - horizontalDiff * 0.1).clamp(3, 14);

            final isCompleted = level <= completedLevels;
            final isCurrent = level == completedLevels + 1;
            final isLocked = !isCompleted && !isCurrent;

            return Padding(
              padding: EdgeInsets.only(
                left: 16 + (waveOffset > 0 ? waveOffset : 0),
                right: 16 + (waveOffset < 0 ? -waveOffset : 0),
                top: 0,
                bottom: 0,
              ),
              child: Column(
                children: [
                  // 关卡节点
                  _RandomPathNode(
                    level: level,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isLocked: isLocked,
                    onTap: isLocked
                        ? null
                        : () => _startRandomLevel(context, ref, level),
                  ),
                  // 动态垂直间距
                  SizedBox(height: verticalSpacing),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms);
          }, childCount: 100000),
        ),
        // 底部间距
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Future<void> _startRandomLevel(
    BuildContext context,
    WidgetRef ref,
    int level,
  ) async {
    final verifiedQuestions = await ref.read(verifiedQuestionsProvider.future);
    final questions = [...verifiedQuestions]..shuffle(math.Random());
    final levelQuestions = questions.take(5).toList();
    if (levelQuestions.isEmpty) return;
    if (!context.mounted) return;

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(questions: levelQuestions)),
    );

    if (completed == true) {
      await ref.read(randomLevelProgressProvider.notifier).completeLevel(level);
    }
    _refreshLearningState(ref);
  }

  // ============ 知识点模式 ============

  Widget _buildKnowledgePointMode(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckListProvider);
    return decksAsync.when(
      data: (decks) => _buildLearningPath(context, ref, decks),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (err, _) => Center(child: Text('加载失败: $err')),
    );
  }

  Widget _buildLearningPath(
    BuildContext context,
    WidgetRef ref,
    List<Deck> decks,
  ) {
    if (decks.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          const Text(
            '学习路径',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已完成 ${decks.where((d) => d.masteryLevel >= 100).length} / ${decks.length} 个题包',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          ..._buildPathNodes(context, ref, decks),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<Widget> _buildPathNodes(
    BuildContext context,
    WidgetRef ref,
    List<Deck> decks,
  ) {
    final nodes = <Widget>[];
    for (var i = 0; i < decks.length; i++) {
      final deck = decks[i];
      final offset = (i % 4 < 2) ? -0.25 : 0.25;
      final isCompleted = deck.masteryLevel >= 100;
      final isCurrent =
          !isCompleted && (i == 0 || decks[i - 1].masteryLevel >= 100);

      nodes.add(
        Align(
          alignment: Alignment(0, 0) + Alignment(offset, 0),
          widthFactor: 0.55,
          child: _PathNode(
            deck: deck,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            onTap: () => _startDeckPractice(context, ref, deck),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (i * 100).ms)
            .slideY(begin: 0.2, duration: 300.ms, delay: (i * 100).ms),
      );

      if (i < decks.length - 1) {
        nodes.add(
          Align(
            alignment: Alignment(0, 0) + Alignment(offset, 0),
            widthFactor: 0.55,
            child: Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: deck.masteryLevel >= 100
                    ? AppColors.gold
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }
    }
    return nodes;
  }

  Future<void> _startDeckPractice(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(deckId: deck.id)),
    );
    if (!context.mounted) return;
    _refreshLearningState(ref, deckId: deck.id);
  }

  // ============ 空状态 ============

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect very constrained layouts (narrow + likely large text scale)
        final isVeryConstrained = constraints.maxWidth < 350;
        final horizontalPadding = 32.0;
        final verticalPadding = isVeryConstrained ? 16.0 : 24.0;
        final iconSize = isVeryConstrained ? 64.0 : 80.0;
        final titleSize = isVeryConstrained ? 19.0 : 22.0;
        final bodySize = isVeryConstrained ? 13.0 : 15.0;
        final spacing1 = isVeryConstrained ? 16.0 : 24.0;
        final spacing2 = isVeryConstrained ? 6.0 : 12.0;
        final spacing3 = isVeryConstrained ? 16.0 : 32.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(iconSize / 2),
                  ),
                  child: Icon(
                    Icons.school,
                    size: iconSize / 2,
                    color: AppColors.green,
                  ),
                ).animate().scale(duration: 500.ms),
                SizedBox(height: spacing1),
                Text(
                  '开始你的学习之旅',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: spacing2),
                Text(
                  '从你的知识源添加内容，建立个人题库\n本地存储，自主掌控',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodySize,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: spacing3),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const IngestionScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    '添加内容',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============ 统计芯片 ============

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final bool isCompact;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 18.0 : 20.0;
    final fontSize = isCompact ? 14.0 : 16.0;
    final spacing = isCompact ? 3.0 : 4.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        SizedBox(width: spacing),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ============ 模式选择选项 ============

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isSelected ? iconColor : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: iconColor, size: 24)
          : null,
    );
  }
}

// ============ 随机模式路径节点 ============

class _RandomPathNode extends StatelessWidget {
  final int level;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onTap;

  const _RandomPathNode({
    required this.level,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeColor = AppColors.surface;
    Color borderColor = AppColors.border;
    Color iconColor = AppColors.textLight;
    IconData icon = Icons.lock;

    if (isCompleted) {
      nodeColor = AppColors.gold;
      borderColor = AppColors.goldDark;
      iconColor = Colors.white;
      icon = Icons.star;
    } else if (isCurrent) {
      nodeColor = AppColors.green;
      borderColor = AppColors.greenDark;
      iconColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, // 从72缩小到60
            height: 60, // 从72缩小到60
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.5), // 边框从3改为2.5
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: isLocked
                ? Icon(icon, color: iconColor, size: 24) // 从28缩小到24
                : isCompleted
                    ? Icon(icon, color: iconColor, size: 28) // 从32缩小到28
                    : Center(
                        child: Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 20, // 从24缩小到20
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 2), // 从4缩小到2，让标签更靠近图标
          Container(
            constraints: const BoxConstraints(maxWidth: 100), // 从120缩小到100
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ), // 从6,3缩小到5,2
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4), // 从6缩小到4
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              '单元 $level',
              style: const TextStyle(
                fontSize: 8, // 从9缩小到8
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 知识点模式路径节点 ============

class _PathNode extends ConsumerWidget {
  final Deck deck;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PathNode({
    required this.deck,
    required this.isCompleted,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifiedQuestionsAsync = ref.watch(
      verifiedDeckQuestionsProvider(deck.id),
    );
    final verifiedCount = verifiedQuestionsAsync.maybeWhen(
      data: (questions) => questions.length,
      orElse: () => null,
    );
    final canStudy = verifiedCount != null && verifiedCount > 0;
    final countLabel = verifiedQuestionsAsync.when(
      data: (questions) =>
          questions.isEmpty ? '待核验' : '${questions.length} 已核验',
      loading: () => '核验中',
      error: (_, __) => '核验状态异常',
    );
    Color nodeColor = AppColors.surface;
    Color borderColor = AppColors.border;
    Color iconColor = AppColors.textLight;
    IconData icon = Icons.lock;

    if (!canStudy) {
      nodeColor = AppColors.surface;
      borderColor = AppColors.border;
      iconColor = AppColors.textLight;
      icon = Icons.lock;
    } else if (isCompleted) {
      nodeColor = AppColors.gold;
      borderColor = AppColors.goldDark;
      iconColor = Colors.white;
      icon = Icons.star;
    } else if (isCurrent) {
      nodeColor = AppColors.green;
      borderColor = AppColors.greenDark;
      iconColor = Colors.white;
      icon = Icons.play_arrow;
    }

    return GestureDetector(
      onTap: canStudy ? onTap : null,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: canStudy && isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                Text(
                  deck.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (deck.masteryLevel > 0) ...[
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: deck.masteryLevel / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: deck.masteryLevel >= 100
                        ? AppColors.gold
                        : AppColors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
