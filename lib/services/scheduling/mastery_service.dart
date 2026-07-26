import '../../data/models/interview_turn.dart';
import '../../data/models/grounded_claim.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/programming_exercise_attempt.dart';
import '../../data/models/question.dart';
import '../../data/repositories/knowledge_point_repository.dart';

class MasteryService {
  final KnowledgePointRepository _knowledgePointRepository;

  MasteryService(this._knowledgePointRepository);

  int calculateMastery({
    required double questionAccuracy,
    required double interviewScore,
    required double reviewStability,
  }) {
    final raw =
        questionAccuracy * 40 + interviewScore * 40 + reviewStability * 20;
    return _asPercent(raw.round());
  }

  Future<void> updateFromQuestionAttempt({
    required Question question,
    required bool isCorrect,
  }) async {
    final knowledgePointId = question.knowledgePointId;
    if (knowledgePointId == null || knowledgePointId.isEmpty) return;

    final point = await _knowledgePointRepository.getKnowledgePoint(
      knowledgePointId,
    );
    if (point == null) return;

    final target = isCorrect ? 82 : 32;
    await _updatePointToward(point, target, weight: isCorrect ? 0.24 : 0.34);
  }

  Future<void> updateFromInterviewTurn({
    required InterviewTurn turn,
    required List<String> knowledgePointIds,
  }) async {
    if (turn.groundingDisposition != GroundingDisposition.grounded) return;
    final affectedIds = {
      ...knowledgePointIds,
      ...turn.weakKnowledgePointIds,
    };
    if (affectedIds.isEmpty) return;

    final averageScore = (turn.accuracyScore +
            turn.projectDetailScore +
            turn.engineeringScore +
            turn.clarityScore) /
        20;
    final target = _asPercent((averageScore * 100).round());

    for (final id in affectedIds) {
      final point = await _knowledgePointRepository.getKnowledgePoint(id);
      if (point == null) continue;

      final isWeak = turn.weakKnowledgePointIds.contains(id);
      await _updatePointToward(
        point,
        isWeak ? target.clamp(0, 45).toInt() : target,
        weight: isWeak ? 0.38 : 0.28,
      );
    }
  }

  Future<bool> updateFromProgrammingExerciseAttempt({
    required ProgrammingExercise exercise,
    required ProgrammingExerciseAttempt attempt,
  }) async {
    final exerciseCitations = exercise.citationIds.toSet();
    final attemptCitations = attempt.citationIds.toSet();
    if (exercise.id != attempt.exerciseId ||
        exercise.knowledgePointId != attempt.knowledgePointId ||
        !exercise.canAffectFormalMastery ||
        attempt.groundingDisposition != GroundingDisposition.grounded ||
        !attempt.evidenceSufficient ||
        attempt.formalMasteryApplied ||
        attemptCitations.isEmpty ||
        !exerciseCitations.containsAll(attemptCitations)) {
      return false;
    }

    final point = await _knowledgePointRepository.getKnowledgePoint(
      exercise.knowledgePointId,
    );
    if (point == null) return false;

    final hasMisconception = attempt.misconceptionLabel.trim().isNotEmpty;
    final target = hasMisconception
        ? attempt.averageScore.clamp(0, 55).toInt()
        : attempt.averageScore;
    await _updatePointToward(
      point,
      target,
      weight: hasMisconception ? 0.38 : 0.3,
    );
    return true;
  }

  Future<void> _updatePointToward(
    KnowledgePoint point,
    int target, {
    required double weight,
  }) async {
    final current = point.masteryLevel;
    final updated = _asPercent((current + (target - current) * weight).round());
    await _knowledgePointRepository.updateKnowledgePoint(
      point.copyWith(
        masteryLevel: updated,
        updatedAt: DateTime.now(),
      ),
    );
  }

  int _asPercent(int value) {
    return value.clamp(0, 100).toInt();
  }
}
