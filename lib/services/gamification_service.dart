import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/database_helper.dart';
import '../data/models/user_stats.dart';

/// 游戏化统计与答题保存共用 SQLite 事务。
class GamificationService {
  final DatabaseHelper _db;
  final DatabaseExecutor? _executor;
  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _preferencesLoader;

  GamificationService(
    this._db, {
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? preferencesLoader,
  })  : _executor = null,
        _clock = clock ?? DateTime.now,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  GamificationService._scoped(
    this._db,
    this._executor,
    this._clock,
    this._preferencesLoader,
  );

  /// This instance must not escape the caller's transaction callback.
  GamificationService inTransaction(DatabaseExecutor executor,
          {DateTime? now}) =>
      GamificationService._scoped(
        _db,
        executor,
        now == null ? _clock : () => now,
        _preferencesLoader,
      );

  static const int xpPerCorrect = 10;
  static const int xpPerDeckComplete = 50;
  static const int xpPerPerfectDeck = 100;
  static const int streakBonusBase = 5;
  static const String legacyImportKey = 'legacy_preferences_imported';
  static final _monthlyKey =
      RegExp(r'^(checkin|medal)_([0-9]{4})_([0-9]{1,2})$');

  static bool isLegacyStatisticsKey(String key) =>
      key == 'total_correct' ||
      key == 'perfect_count' ||
      _monthlyKey.hasMatch(key);

  Future<T> _withDatabase<T>(
      Future<T> Function(DatabaseExecutor) action) async {
    final executor = _executor;
    if (executor != null) return action(executor);
    return _db.runInTransaction(action);
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  Future<UserStats> _readStats(DatabaseExecutor executor) async {
    final rows = await executor.query('user_stats', where: 'id = 1');
    if (rows.isEmpty) throw StateError('User statistics are missing.');
    var stats = UserStats.fromMap(rows.single);
    final now = _clock();
    if (!_sameDay(stats.lastStudyDate, now)) {
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      stats = stats.copyWith(
        todayXp: 0,
        streak: _sameDay(stats.lastStudyDate, yesterday) ? stats.streak : 0,
      );
      await _writeStats(executor, stats);
    }
    return stats;
  }

  Future<void> _writeStats(DatabaseExecutor executor, UserStats stats) async {
    final updated = await executor.update(
      'user_stats',
      stats.toMap(),
      where: 'id = 1',
    );
    if (updated != 1) throw StateError('User statistics were not saved.');
  }

  UserStats _recordStudyDay(UserStats stats) {
    final now = _clock();
    if (_sameDay(stats.lastStudyDate, now)) return stats;
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return stats.copyWith(
      streak: _sameDay(stats.lastStudyDate, yesterday) ? stats.streak + 1 : 1,
      lastStudyDate: now,
    );
  }

  /// 获取用户统计，日重置和所有读改写均在同一事务中。
  Future<UserStats> getStats() => _withDatabase(_readStats);

  Future<UserStats> onCorrectAnswer() => _withDatabase((executor) async {
        var stats = _recordStudyDay(await _readStats(executor));
        stats = stats.copyWith(
          xp: stats.xp + xpPerCorrect,
          todayXp: stats.todayXp + xpPerCorrect,
        );
        await _writeStats(executor, stats);
        return stats;
      });

  Future<UserStats> onWrongAnswer() => _withDatabase((executor) async {
        var stats = _recordStudyDay(await _readStats(executor));
        if (stats.hearts > 0) stats = stats.copyWith(hearts: stats.hearts - 1);
        await _writeStats(executor, stats);
        return stats;
      });

  Future<UserStats> onDeckComplete({required bool allCorrect}) =>
      _withDatabase((executor) async {
        var stats = await _readStats(executor);
        final bonus = allCorrect ? xpPerPerfectDeck : xpPerDeckComplete;
        final reward = bonus + stats.streak * streakBonusBase;
        stats = stats.copyWith(
            xp: stats.xp + reward, todayXp: stats.todayXp + reward);
        await _writeStats(executor, stats);
        return stats;
      });

  Future<UserStats> onPerfectQuiz() => refillOneHeart();
  bool isOutOfHearts(UserStats stats) => stats.hearts <= 0;

  Future<UserStats> refillOneHeart() => _withDatabase((executor) async {
        var stats = await _readStats(executor);
        if (stats.hearts < stats.maxHearts) {
          stats = stats.copyWith(hearts: stats.hearts + 1);
          await _writeStats(executor, stats);
        }
        return stats;
      });

  Future<void> setDailyGoal(int goal) => _withDatabase((executor) async {
        final stats = await _readStats(executor);
        await _writeStats(executor, stats.copyWith(dailyGoal: goal));
      });

  bool isDailyGoalComplete(UserStats stats) => stats.todayXp >= stats.dailyGoal;

  int calculateMasteryLevel(int correctCount, int totalCount) =>
      totalCount == 0 ? 0 : (correctCount / totalCount * 100).round();

  /// Marker and values commit together, including when the first quiz save fails.
  Future<void> migrateLegacyStatistics() => _withDatabase(_importLegacy);

  Future<void> _importLegacy(DatabaseExecutor executor) async {
    if (await _readValue(executor, legacyImportKey) == true) return;
    final preferences = await _preferencesLoader();
    for (final key in preferences.getKeys().where(isLegacyStatisticsKey)) {
      final value = preferences.get(key);
      final valid = key.startsWith('checkin_')
          ? value is List<String>
          : key.startsWith('medal_')
              ? value is bool
              : value is int;
      if (valid) {
        await executor.insert(
          'gamification_state',
          {'key': key, 'value_json': jsonEncode(value)},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    await _writeValue(executor, legacyImportKey, true);
  }

  Future<T> _withStatistics<T>(Future<T> Function(DatabaseExecutor) action) =>
      _withDatabase((executor) async {
        await _importLegacy(executor);
        return action(executor);
      });

  Future<Object?> _readValue(DatabaseExecutor executor, String key) async {
    final rows = await executor.query(
      'gamification_state',
      columns: ['value_json'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['value_json'] as String);
  }

  Future<void> _writeValue(
      DatabaseExecutor executor, String key, Object value) async {
    await executor.insert(
      'gamification_state',
      {'key': key, 'value_json': jsonEncode(value)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> _checkInDates(
      DatabaseExecutor executor, int year, int month) async {
    final value = await _readValue(executor, 'checkin_${year}_$month');
    return value is List ? value.whereType<String>().toList() : [];
  }

  Future<void> recordCheckIn() => _withStatistics((executor) async {
        final now = _clock();
        final date = '${now.year}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        final dates = (await _checkInDates(executor, now.year, now.month))
            .toSet()
          ..add(date);
        await _writeValue(
            executor, 'checkin_${now.year}_${now.month}', dates.toList());
        if (dates.length >= 20) {
          await _writeValue(executor, 'medal_${now.year}_${now.month}', true);
        }
      });

  Future<List<String>> getMonthlyCheckInDates(int year, int month) =>
      _withStatistics((executor) => _checkInDates(executor, year, month));

  Future<int> getMonthlyCheckInCount(int year, int month) async =>
      (await getMonthlyCheckInDates(year, month)).length;

  Future<bool> hasMonthlyMedal(int year, int month) =>
      _withStatistics((executor) async =>
          await _readValue(executor, 'medal_${year}_$month') == true);

  Future<List<({int year, int month})>> getEarnedMedals() =>
      _withStatistics((executor) async {
        final rows = await executor.query(
          'gamification_state',
          where: 'key LIKE ?',
          whereArgs: ['medal_%'],
        );
        final medals = <({int year, int month})>[];
        for (final row in rows) {
          final match = _monthlyKey.firstMatch(row['key'] as String);
          if (match == null ||
              jsonDecode(row['value_json'] as String) != true) {
            continue;
          }
          medals.add((year: int.parse(match[2]!), month: int.parse(match[3]!)));
        }
        medals.sort((a, b) {
          final year = b.year.compareTo(a.year);
          return year != 0 ? year : b.month.compareTo(a.month);
        });
        return medals;
      });

  Future<int> _increment(String key) => _withStatistics((executor) async {
        final count = ((await _readValue(executor, key)) as int? ?? 0) + 1;
        await _writeValue(executor, key, count);
        return count;
      });

  Future<int> _count(String key) => _withStatistics(
      (executor) async => (await _readValue(executor, key)) as int? ?? 0);

  Future<int> incrementTotalCorrect() => _increment('total_correct');
  Future<int> getTotalCorrect() => _count('total_correct');
  Future<int> incrementPerfectCount() => _increment('perfect_count');
  Future<int> getPerfectCount() => _count('perfect_count');
}
