import '../database/database_helper.dart';
import '../models/product_event.dart';
import '../models/programming_review_action.dart';
import '../../services/privacy/product_event_recorder.dart';

class ProgrammingReviewActionRepository {
  final DatabaseHelper _db;
  final ProductEventRecorder? _eventRecorder;

  ProgrammingReviewActionRepository(
    this._db, {
    ProductEventRecorder? eventRecorder,
  }) : _eventRecorder = eventRecorder;

  Future<void> upsertAction(ProgrammingReviewAction action) async {
    await _db.upsertProgrammingReviewAction(action);
    await _eventRecorder?.recordBestEffort(
      ProductEventName.reviewScheduled,
      flowId: 'review_${action.triggerType.value}_${action.triggerId}',
      targetId: action.knowledgePointId,
      properties: {
        'target_type': 'knowledge_point',
        'due_bucket': ProductEventRecorder.dueBucket(
          action.dueAt,
          now: action.createdAt,
        ),
      },
      dedupeKey:
          'review_scheduled:${action.triggerType.value}:${action.triggerId}',
    );
  }

  Future<void> updateAction(ProgrammingReviewAction action) async {
    final previous = await _db.getProgrammingReviewAction(action.id);
    await _db.updateProgrammingReviewAction(action);
    if (previous?.completedAt == null && action.completedAt != null) {
      await _eventRecorder?.recordBestEffort(
        ProductEventName.followUpCompleted,
        flowId: 'review_${action.triggerType.value}_${action.triggerId}',
        targetId: action.knowledgePointId,
        properties: const {
          'action_type': 'programming_review',
          'target_type': 'knowledge_point',
        },
        dedupeKey: 'follow_up_completed:${action.id}',
      );
    }
  }

  Future<ProgrammingReviewAction?> getAction(String id) {
    return _db.getProgrammingReviewAction(id);
  }

  Future<List<ProgrammingReviewAction>> getOpenActions() {
    return _db.getOpenProgrammingReviewActions();
  }

  Future<List<ProgrammingReviewAction>> getAllActions() {
    return _db.getAllProgrammingReviewActions();
  }
}
