import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/deck.dart';
import '../../data/models/user_stats.dart';
import '../settings/about_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final decksAsync = ref.watch(deckListProvider);
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month}';
    final checkInAsync = ref.watch(monthlyCheckInProvider(monthKey));
    final medalsAsync = ref.watch(earnedMedalsProvider);
    final totalCorrectAsync = ref.watch(totalCorrectProvider);
    final perfectCountAsync = ref.watch(perfectCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 头像和等级
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.green, AppColors.greenDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '学习者',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    statsAsync.when(
                      data: (stats) => Text(
                        '等级 ${stats.xp ~/ 100 + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 统计网格
              statsAsync.when(
                data: (stats) => _buildStatsGrid(stats),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              // 每日目标
              statsAsync.when(
                data: (stats) => _buildDailyGoal(context, stats),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              // 月度打卡
              _buildMonthlyCheckIn(context, checkInAsync, medalsAsync),
              const SizedBox(height: 24),
              // 成就
              _buildAchievements(
                  context,
                  statsAsync,
                  decksAsync,
                  totalCorrectAsync,
                  perfectCountAsync,
                  medalsAsync,
                  checkInAsync),
              const SizedBox(height: 24),
              // 菜单项
              _buildMenuItems(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(UserStats stats) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.local_fire_department,
          color: AppColors.streakOrange,
          value: stats.streak.toString(),
          label: '连续天数',
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.diamond,
          color: AppColors.blue,
          value: stats.xp.toString(),
          label: '总 XP',
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.favorite,
          color: AppColors.heartRed,
          value: '${stats.hearts}/${stats.maxHearts}',
          label: '心数',
        ),
      ],
    );
  }

  Widget _buildDailyGoal(BuildContext context, UserStats stats) {
    final progress = (stats.todayXp / stats.dailyGoal).clamp(0.0, 1.0);
    final isComplete = stats.todayXp >= stats.dailyGoal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '每日目标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${stats.todayXp} / ${stats.dailyGoal} XP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isComplete ? AppColors.green : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 进度条
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.gold : AppColors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          if (isComplete) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.gold, size: 20),
                const SizedBox(width: 4),
                const Text(
                  '今日目标已达成！',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyCheckIn(
    BuildContext context,
    AsyncValue<List<String>> checkInAsync,
    AsyncValue<List<({int year, int month})>> medalsAsync,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final today = now.day;
    final checkInDates = checkInAsync.value ?? [];
    final checkInCount = checkInDates.length;
    final hasMedal = checkInCount >= 20;
    final medals = medalsAsync.value ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '月度打卡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasMedal
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$checkInCount / 20 天',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasMedal ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 日历网格
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(daysInMonth, (i) {
              final day = i + 1;
              final dateStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final isChecked = checkInDates.contains(dateStr);
              final isToday = day == today;
              final isFuture = day > today;

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.green
                      : (isFuture ? AppColors.surface : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isToday
                        ? AppColors.blue
                        : (isChecked ? AppColors.green : AppColors.border),
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isChecked ? FontWeight.w800 : FontWeight.w500,
                      color: isChecked
                          ? Colors.white
                          : (isFuture
                              ? AppColors.textLight
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (hasMedal) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.gold, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '本月全勤勋章已解锁！',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 已获得的月度勋章
          if (medals.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '已获得勋章',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medals.map((m) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${m.year}年${m.month}月',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    AsyncValue<UserStats> statsAsync,
    AsyncValue<List<Deck>> decksAsync,
    AsyncValue<int> totalCorrectAsync,
    AsyncValue<int> perfectCountAsync,
    AsyncValue<List<({int year, int month})>> medalsAsync,
    AsyncValue<List<String>> checkInAsync,
  ) {
    final decks = decksAsync.value ?? [];
    final stats = statsAsync.value;
    final totalCorrect = totalCorrectAsync.value ?? 0;
    final perfectCount = perfectCountAsync.value ?? 0;
    final medals = medalsAsync.value ?? [];
    final checkInCount = (checkInAsync.value ?? []).length;

    final achievements = <_Achievement>[
      // 连续学习
      _Achievement(
          icon: Icons.local_fire_department,
          title: '连续3天',
          desc: '坚持学习3天',
          unlocked: (stats?.streak ?? 0) >= 3,
          color: AppColors.streakOrange),
      _Achievement(
          icon: Icons.local_fire_department,
          title: '连续7天',
          desc: '坚持学习7天',
          unlocked: (stats?.streak ?? 0) >= 7,
          color: AppColors.red),
      _Achievement(
          icon: Icons.local_fire_department,
          title: '连续30天',
          desc: '坚持学习30天',
          unlocked: (stats?.streak ?? 0) >= 30,
          color: AppColors.purple),
      _Achievement(
          icon: Icons.local_fire_department,
          title: '连续100天',
          desc: '坚持学习100天',
          unlocked: (stats?.streak ?? 0) >= 100,
          color: AppColors.gold),
      // 经验值
      _Achievement(
          icon: Icons.diamond,
          title: '初心者',
          desc: '累计100 XP',
          unlocked: (stats?.xp ?? 0) >= 100,
          color: AppColors.blue),
      _Achievement(
          icon: Icons.diamond,
          title: '积少成多',
          desc: '累计500 XP',
          unlocked: (stats?.xp ?? 0) >= 500,
          color: AppColors.blue),
      _Achievement(
          icon: Icons.diamond,
          title: '知识富翁',
          desc: '累计1000 XP',
          unlocked: (stats?.xp ?? 0) >= 1000,
          color: AppColors.purple),
      _Achievement(
          icon: Icons.diamond,
          title: '勤学者',
          desc: '累计2000 XP',
          unlocked: (stats?.xp ?? 0) >= 2000,
          color: AppColors.purple),
      _Achievement(
          icon: Icons.diamond,
          title: '学霸',
          desc: '累计5000 XP',
          unlocked: (stats?.xp ?? 0) >= 5000,
          color: AppColors.gold),
      // 答题数
      _Achievement(
          icon: Icons.check_circle,
          title: '答题新手',
          desc: '答对100题',
          unlocked: totalCorrect >= 100,
          color: AppColors.green),
      _Achievement(
          icon: Icons.check_circle,
          title: '答题达人',
          desc: '答对500题',
          unlocked: totalCorrect >= 500,
          color: AppColors.blue),
      _Achievement(
          icon: Icons.check_circle,
          title: '答题大师',
          desc: '答对1000题',
          unlocked: totalCorrect >= 1000,
          color: AppColors.gold),
      // 题包
      _Achievement(
          icon: Icons.school,
          title: '初次学习',
          desc: '完成第一个题包',
          unlocked: decks.isNotEmpty,
          color: AppColors.green),
      _Achievement(
          icon: Icons.star,
          title: '收集达人',
          desc: '创建5个题包',
          unlocked: decks.length >= 5,
          color: AppColors.gold),
      _Achievement(
          icon: Icons.star,
          title: '题库大师',
          desc: '创建10个题包',
          unlocked: decks.length >= 10,
          color: AppColors.purple),
      _Achievement(
          icon: Icons.emoji_events,
          title: '满分通关',
          desc: '完美完成1次',
          unlocked: perfectCount >= 1,
          color: AppColors.purple),
      _Achievement(
          icon: Icons.emoji_events,
          title: '完美主义者',
          desc: '完美完成5次',
          unlocked: perfectCount >= 5,
          color: AppColors.gold),
      // 月度打卡
      _Achievement(
          icon: Icons.calendar_month,
          title: '月度全勤',
          desc: '单月打卡20天',
          unlocked: checkInCount >= 20 || medals.isNotEmpty,
          color: AppColors.green),
      _Achievement(
          icon: Icons.calendar_month,
          title: '满月达人',
          desc: '获得3个月勋章',
          unlocked: medals.length >= 3,
          color: AppColors.blue),
      _Achievement(
          icon: Icons.calendar_month,
          title: '持之以恒',
          desc: '获得6个月勋章',
          unlocked: medals.length >= 6,
          color: AppColors.gold),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '成就',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${achievements.where((a) => a.unlocked).length} / ${achievements.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) => _AchievementBadge(
            achievement: achievements[index],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        _MenuItem(
          icon: Icons.settings,
          title: '设置',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        _MenuItem(
          icon: Icons.info,
          title: '关于',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Achievement {
  final IconData icon;
  final String title;
  final String desc;
  final bool unlocked;
  final Color color;

  _Achievement({
    required this.icon,
    required this.title,
    required this.desc,
    required this.unlocked,
    required this.color,
  });
}

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击显示描述
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(achievement.icon,
                    color:
                        achievement.unlocked ? achievement.color : Colors.grey,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  '${achievement.title} - ${achievement.desc}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  achievement.unlocked ? '已解锁' : '未解锁',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: achievement.unlocked
                        ? AppColors.green
                        : AppColors.textLight,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: achievement.unlocked
              ? achievement.color.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.unlocked
                ? achievement.color.withValues(alpha: 0.3)
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon,
              size: 24,
              color: achievement.unlocked
                  ? achievement.color
                  : AppColors.textLight,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: achievement.unlocked
                    ? AppColors.textPrimary
                    : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
