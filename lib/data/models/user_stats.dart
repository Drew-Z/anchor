/// 用户统计模型
class UserStats {
  final int xp;
  final int streak;
  final int hearts;
  final int maxHearts;
  final DateTime lastStudyDate;
  final int dailyGoal;
  final int todayXp;

  UserStats({
    this.xp = 0,
    this.streak = 0,
    this.hearts = 5,
    this.maxHearts = 5,
    required this.lastStudyDate,
    this.dailyGoal = 50,
    this.todayXp = 0,
  });

  UserStats copyWith({
    int? xp,
    int? streak,
    int? hearts,
    int? maxHearts,
    DateTime? lastStudyDate,
    int? dailyGoal,
    int? todayXp,
  }) {
    return UserStats(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      hearts: hearts ?? this.hearts,
      maxHearts: maxHearts ?? this.maxHearts,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      todayXp: todayXp ?? this.todayXp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'streak': streak,
      'hearts': hearts,
      'max_hearts': maxHearts,
      'last_study_date': lastStudyDate.millisecondsSinceEpoch,
      'daily_goal': dailyGoal,
      'today_xp': todayXp,
    };
  }

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      xp: (map['xp'] as int?) ?? 0,
      streak: (map['streak'] as int?) ?? 0,
      hearts: (map['hearts'] as int?) ?? 5,
      maxHearts: (map['max_hearts'] as int?) ?? 5,
      lastStudyDate: DateTime.fromMillisecondsSinceEpoch(
        (map['last_study_date'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      dailyGoal: (map['daily_goal'] as int?) ?? 50,
      todayXp: (map['today_xp'] as int?) ?? 0,
    );
  }

  /// 检查是否是新的一天(用于重置 todayXp 和更新 streak)
  bool get isToday {
    final now = DateTime.now();
    return lastStudyDate.year == now.year &&
        lastStudyDate.month == now.month &&
        lastStudyDate.day == now.day;
  }

  /// 检查昨天是否学习过
  bool get studiedYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastStudyDate.year == yesterday.year &&
        lastStudyDate.month == yesterday.month &&
        lastStudyDate.day == yesterday.day;
  }
}
