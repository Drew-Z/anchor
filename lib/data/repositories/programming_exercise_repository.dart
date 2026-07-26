import '../database/database_helper.dart';
import '../models/programming_exercise.dart';
import '../models/programming_exercise_attempt.dart';
import '../models/product_event.dart';
import '../../services/privacy/product_event_recorder.dart';

class ProgrammingExerciseRepository {
  final DatabaseHelper _db;
  final ProductEventRecorder? _eventRecorder;

  ProgrammingExerciseRepository(
    this._db, {
    ProductEventRecorder? eventRecorder,
  }) : _eventRecorder = eventRecorder;

  Future<String> insertExercise(ProgrammingExercise exercise) {
    return _db.insertProgrammingExercise(exercise);
  }

  Future<void> updateExercise(ProgrammingExercise exercise) {
    return _db.updateProgrammingExercise(exercise);
  }

  Future<ProgrammingExercise?> getExercise(String id) {
    return _db.getProgrammingExercise(id);
  }

  Future<List<ProgrammingExercise>> getExercisesForKnowledgePoint(
    String knowledgePointId,
  ) {
    return _db.getProgrammingExercisesForKnowledgePoint(knowledgePointId);
  }

  Future<List<ProgrammingExercise>> getAllExercises() {
    return _db.getAllProgrammingExercises();
  }

  Future<String> insertAttempt(ProgrammingExerciseAttempt attempt) async {
    final id = await _db.insertProgrammingExerciseAttempt(attempt);
    await _eventRecorder?.recordBestEffort(
      ProductEventName.groundedTurnCompleted,
      flowId: 'programming_attempt_${attempt.id}',
      targetId: attempt.knowledgePointId,
      properties: {
        'surface': 'practice',
        'disposition': attempt.groundingDisposition.value,
        'citation_count': attempt.citationIds.length,
        'duration_bucket': 'unknown',
      },
      dedupeKey: 'grounded_turn_completed:practice:${attempt.id}',
    );
    return id;
  }

  Future<void> updateAttempt(ProgrammingExerciseAttempt attempt) {
    return _db.updateProgrammingExerciseAttempt(attempt);
  }

  Future<ProgrammingExerciseAttempt?> getAttempt(String id) {
    return _db.getProgrammingExerciseAttempt(id);
  }

  Future<List<ProgrammingExerciseAttempt>> getAttemptsForExercise(
    String exerciseId,
  ) {
    return _db.getProgrammingExerciseAttempts(exerciseId);
  }

  Future<List<ProgrammingExerciseAttempt>> getAllAttempts() {
    return _db.getAllProgrammingExerciseAttempts();
  }
}
