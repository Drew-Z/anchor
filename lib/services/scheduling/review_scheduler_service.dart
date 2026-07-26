import '../../data/models/knowledge_point.dart';
import '../../data/models/product_event.dart';
import '../../data/models/question.dart';
import '../../data/repositories/knowledge_point_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../privacy/product_event_recorder.dart';

class ReviewQueueItem {
  final KnowledgePoint knowledgePoint;
  final List<Question> questions;
  final int overdueCount;
  final int priority;

  const ReviewQueueItem({
    required this.knowledgePoint,
    required this.questions,
    required this.overdueCount,
    required this.priority,
  });

  int get questionCount => questions.length;
}

class ReviewSchedulerService {
  final QuestionRepository _questionRepository;
  final KnowledgePointRepository _knowledgePointRepository;
  final ProductEventRecorder? _eventRecorder;

  ReviewSchedulerService({
    required QuestionRepository questionRepository,
    required KnowledgePointRepository knowledgePointRepository,
    ProductEventRecorder? eventRecorder,
  })  : _questionRepository = questionRepository,
        _knowledgePointRepository = knowledgePointRepository,
        _eventRecorder = eventRecorder;

  Future<List<ReviewQueueItem>> getTodayReviewQueue({
    DateTime? now,
    int limit = 12,
  }) async {
    final current = now ?? DateTime.now();
    final startOfToday = DateTime(current.year, current.month, current.day);
    final dueQuestions = await _getDueQuestions(current);
    final grouped = <String, List<Question>>{};

    for (final question in dueQuestions) {
      final knowledgePointId = question.knowledgePointId;
      if (knowledgePointId == null || knowledgePointId.isEmpty) continue;
      grouped.putIfAbsent(knowledgePointId, () => []).add(question);
    }

    final items = <ReviewQueueItem>[];
    for (final entry in grouped.entries) {
      final point =
          await _knowledgePointRepository.getKnowledgePoint(entry.key);
      if (point == null) continue;

      final overdueCount = entry.value.where((question) {
        final nextReviewAt = question.nextReviewAt;
        return nextReviewAt != null && nextReviewAt.isBefore(startOfToday);
      }).length;

      items.add(
        ReviewQueueItem(
          knowledgePoint: point,
          questions: _sortQuestions(entry.value),
          overdueCount: overdueCount,
          priority: _priority(point, entry.value, overdueCount),
        ),
      );
    }

    items.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.knowledgePoint.title.compareTo(b.knowledgePoint.title);
    });

    return items.take(limit).toList();
  }

  Future<List<Question>> getTodayReviewQuestions({
    DateTime? now,
    int limit = 10,
  }) async {
    final current = now ?? DateTime.now();
    final items = await getTodayReviewQueue(now: current, limit: limit);
    final questions = <Question>[];
    for (final item in items) {
      questions.addAll(item.questions);
    }
    return _sortQuestions(questions).take(limit).toList();
  }

  Future<Question> recordQuestionReview({
    required Question question,
    required bool isCorrect,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final updated = question.copyWith(
      lastReviewedAt: current,
      nextReviewAt: _nextReviewAt(question, isCorrect, current),
      ease: _nextEase(question.ease, isCorrect),
      lapseCount: isCorrect ? question.lapseCount : question.lapseCount + 1,
    );
    await _questionRepository.updateQuestion(updated);
    final flowId =
        'question_review_${question.id}_${current.toUtc().microsecondsSinceEpoch}';
    await _eventRecorder?.recordBestEffort(
      ProductEventName.followUpCompleted,
      flowId: flowId,
      targetId: question.knowledgePointId ?? question.id,
      properties: const {
        'action_type': 'question_review',
        'target_type': 'question',
      },
    );
    await _eventRecorder?.recordBestEffort(
      ProductEventName.reviewScheduled,
      flowId: flowId,
      targetId: question.knowledgePointId ?? question.id,
      properties: {
        'target_type': 'question',
        'due_bucket': ProductEventRecorder.dueBucket(
          updated.nextReviewAt!,
          now: current,
        ),
      },
    );
    return updated;
  }

  Future<List<Question>> _getDueQuestions(DateTime now) async {
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final questions = await _questionRepository.getAllQuestions();
    return questions.where((question) {
      if (question.sourceStatus != SourceStatus.verified) return false;
      final nextReviewAt = question.nextReviewAt;
      if (nextReviewAt == null) return true;
      return nextReviewAt.isBefore(endOfToday);
    }).toList();
  }

  List<Question> _sortQuestions(List<Question> questions) {
    final sorted = [...questions];
    sorted.sort((a, b) {
      final aDue = a.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDue = b.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dueCompare = aDue.compareTo(bDue);
      if (dueCompare != 0) return dueCompare;
      return b.difficulty.compareTo(a.difficulty);
    });
    return sorted;
  }

  int _priority(
    KnowledgePoint point,
    List<Question> questions,
    int overdueCount,
  ) {
    final lowMasteryBoost = 100 - point.masteryLevel;
    final relevanceBoost = point.interviewRelevance * 2;
    final loadBoost = questions.length * 6;
    return lowMasteryBoost + relevanceBoost + loadBoost + overdueCount * 18;
  }

  DateTime _nextReviewAt(
    Question question,
    bool isCorrect,
    DateTime now,
  ) {
    if (!isCorrect) return now.add(const Duration(days: 1));

    final difficultyPenalty = (question.difficulty - 1).clamp(0, 4);
    final lapsePenalty = question.lapseCount.clamp(0, 4);
    final intervalDays =
        (1 + question.ease * 2.2 - difficultyPenalty - lapsePenalty)
            .round()
            .clamp(1, 14)
            .toInt();
    return now.add(Duration(days: intervalDays));
  }

  double _nextEase(double ease, bool isCorrect) {
    final next = isCorrect ? ease + 0.12 : ease - 0.2;
    return next.clamp(0.6, 2.5).toDouble();
  }
}
