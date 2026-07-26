/// 学习记录模型
class StudyRecord {
  final String id;
  final String deckId;
  final int correctCount;
  final int totalCount;
  final DateTime lastStudiedAt;

  StudyRecord({
    required this.id,
    required this.deckId,
    this.correctCount = 0,
    this.totalCount = 0,
    required this.lastStudiedAt,
  });

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'correct_count': correctCount,
      'total_count': totalCount,
      'last_studied_at': lastStudiedAt.millisecondsSinceEpoch,
    };
  }

  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      correctCount: (map['correct_count'] as int?) ?? 0,
      totalCount: (map['total_count'] as int?) ?? 0,
      lastStudiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['last_studied_at'] as int?) ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
