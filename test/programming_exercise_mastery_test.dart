import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/services/scheduling/mastery_service.dart';

void main() {
  test('updates mastery only for verified exercises and grounded evaluations',
      () async {
    final repository = _FakeKnowledgePointRepository(_point());
    final service = MasteryService(repository);
    final pending = _exercise(SourceStatus.pending);
    final verified = _exercise(SourceStatus.verified);
    final attempt = _attempt();

    expect(
      await service.updateFromProgrammingExerciseAttempt(
        exercise: pending,
        attempt: attempt,
      ),
      isFalse,
    );
    expect(repository.point.masteryLevel, 20);

    expect(
      await service.updateFromProgrammingExerciseAttempt(
        exercise: verified,
        attempt: attempt.copyWith(
          groundingDisposition: GroundingDisposition.partial,
        ),
      ),
      isFalse,
    );
    expect(repository.point.masteryLevel, 20);

    expect(
      await service.updateFromProgrammingExerciseAttempt(
        exercise: verified,
        attempt: attempt.copyWith(evidenceSufficient: false),
      ),
      isFalse,
    );
    expect(
      await service.updateFromProgrammingExerciseAttempt(
        exercise: verified,
        attempt: attempt.copyWith(citationIds: const ['other-chunk']),
      ),
      isFalse,
    );
    expect(repository.point.masteryLevel, 20);

    expect(
      await service.updateFromProgrammingExerciseAttempt(
        exercise: verified,
        attempt: attempt,
      ),
      isTrue,
    );
    expect(repository.point.masteryLevel, greaterThan(20));

    final updatedLevel = repository.point.masteryLevel;
    expect(
      await service.updateFromProgrammingExerciseAttempt(
        exercise: verified,
        attempt: attempt.copyWith(formalMasteryApplied: true),
      ),
      isFalse,
    );
    expect(repository.point.masteryLevel, updatedLevel);
  });
}

KnowledgePoint _point() {
  return KnowledgePoint(
    id: 'concept',
    title: 'Concept',
    summary: 'Source-backed concept.',
    masteryLevel: 20,
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  );
}

ProgrammingExercise _exercise(SourceStatus status) {
  final now = DateTime(2026, 7, 15);
  return ProgrammingExercise(
    id: 'exercise',
    knowledgePointId: 'concept',
    kind: ProgrammingExerciseKind.explanation,
    prompt: 'Explain the concept.',
    referenceAnswer: 'Reference.',
    conceptAccuracyCriterion: 'Accuracy.',
    reasoningProcessCriterion: 'Reasoning.',
    evidenceUseCriterion: 'Evidence.',
    clarityCriterion: 'Clarity.',
    sourceStatus: status,
    citationIds: const ['chunk'],
    createdAt: now,
    updatedAt: now,
  );
}

ProgrammingExerciseAttempt _attempt() {
  return ProgrammingExerciseAttempt(
    id: 'attempt',
    exerciseId: 'exercise',
    knowledgePointId: 'concept',
    userAnswer: 'Answer.',
    feedback: 'Feedback.',
    conceptAccuracyScore: 90,
    reasoningProcessScore: 80,
    evidenceUseScore: 85,
    clarityScore: 95,
    citationIds: const ['chunk'],
    createdAt: DateTime(2026, 7, 15),
  );
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  KnowledgePoint point;

  _FakeKnowledgePointRepository(this.point) : super(DatabaseHelper());

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    return id == point.id ? point : null;
  }

  @override
  Future<void> updateKnowledgePoint(KnowledgePoint point) async {
    this.point = point;
  }
}
