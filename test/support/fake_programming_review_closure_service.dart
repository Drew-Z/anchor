import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/programming_review_action.dart';
import 'package:dlg_q/data/models/tutor_turn.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/programming_exercise_repository.dart';
import 'package:dlg_q/data/repositories/programming_review_action_repository.dart';
import 'package:dlg_q/data/repositories/question_repository.dart';
import 'package:dlg_q/services/scheduling/programming_review_closure_service.dart';

class FakeProgrammingReviewClosureService
    extends ProgrammingReviewClosureService {
  final Future<void> Function(TutorTurn turn)? onTutorTurn;
  final Future<void> Function(
    ProgrammingExercise exercise,
    ProgrammingExerciseAttempt attempt,
  )? onExerciseAttempt;

  FakeProgrammingReviewClosureService({
    this.onTutorTurn,
    this.onExerciseAttempt,
  }) : super(
          knowledgePointRepository: KnowledgePointRepository(DatabaseHelper()),
          questionRepository: QuestionRepository(DatabaseHelper()),
          exerciseRepository: ProgrammingExerciseRepository(DatabaseHelper()),
          actionRepository: ProgrammingReviewActionRepository(DatabaseHelper()),
          databaseHelper: DatabaseHelper(),
        );

  @override
  Future<ProgrammingReviewAction?> closeTutorTurn({
    required TutorTurn turn,
    DateTime? now,
  }) async {
    await onTutorTurn?.call(turn);
    return null;
  }

  @override
  Future<ProgrammingReviewAction?> closeExerciseAttempt({
    required ProgrammingExercise exercise,
    required ProgrammingExerciseAttempt attempt,
    DateTime? now,
  }) async {
    await onExerciseAttempt?.call(exercise, attempt);
    return null;
  }
}
