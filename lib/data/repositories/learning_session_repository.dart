import '../database/database_helper.dart';
import '../models/interview_turn.dart';
import '../models/learning_session.dart';
import '../models/product_event.dart';
import '../models/tutor_turn.dart';
import '../../services/privacy/product_event_recorder.dart';

class LearningSessionRepository {
  final DatabaseHelper _db;
  final ProductEventRecorder? _eventRecorder;

  LearningSessionRepository(this._db, {ProductEventRecorder? eventRecorder})
      : _eventRecorder = eventRecorder;

  Future<String> insertLearningSession(LearningSession session) {
    return _db.insertLearningSession(session);
  }

  Future<void> updateLearningSession(LearningSession session) {
    return _db.updateLearningSession(session);
  }

  Future<List<LearningSession>> getLearningSessions() {
    return _db.getLearningSessions();
  }

  Future<LearningSession?> getLearningSession(String id) {
    return _db.getLearningSession(id);
  }

  Future<String> insertInterviewTurn(InterviewTurn turn) async {
    final id = await _db.insertInterviewTurn(turn);
    await _recordGroundedTurn(
      surface: 'interview',
      sessionId: turn.sessionId,
      targetId: turn.knowledgePointId,
      disposition: turn.groundingDisposition.value,
      citationCount: turn.citationIds.length,
      createdAt: turn.createdAt,
      dedupeKey: 'grounded_turn_completed:interview:${turn.id}',
    );
    return id;
  }

  Future<List<InterviewTurn>> getInterviewTurns(String sessionId) {
    return _db.getInterviewTurns(sessionId);
  }

  Future<List<InterviewTurn>> getAllInterviewTurns() {
    return _db.getAllInterviewTurns();
  }

  Future<String> insertTutorTurn(TutorTurn turn) async {
    final id = await _db.insertTutorTurn(turn);
    await _recordGroundedTurn(
      surface: 'tutor',
      sessionId: turn.sessionId,
      targetId: turn.knowledgePointId,
      disposition: turn.groundingDisposition.value,
      citationCount: turn.citationIds.length,
      createdAt: turn.createdAt,
      dedupeKey: 'grounded_turn_completed:tutor:${turn.id}',
    );
    return id;
  }

  Future<List<TutorTurn>> getTutorTurns(String sessionId) {
    return _db.getTutorTurns(sessionId);
  }

  Future<List<TutorTurn>> getAllTutorTurns() {
    return _db.getAllTutorTurns();
  }

  Future<void> _recordGroundedTurn({
    required String surface,
    required String sessionId,
    required String? targetId,
    required String disposition,
    required int citationCount,
    required DateTime createdAt,
    required String dedupeKey,
  }) async {
    final recorder = _eventRecorder;
    if (recorder == null) return;
    final session = await _db.getLearningSession(sessionId);
    final duration = session == null
        ? Duration.zero
        : createdAt.difference(session.startedAt).abs();
    await recorder.recordBestEffort(
      ProductEventName.groundedTurnCompleted,
      flowId: 'learning_session_$sessionId',
      targetId: targetId,
      sessionId: sessionId,
      properties: {
        'surface': surface,
        'disposition': disposition,
        'citation_count': citationCount,
        'duration_bucket': ProductEventRecorder.durationBucket(duration),
      },
      dedupeKey: dedupeKey,
    );
  }
}
