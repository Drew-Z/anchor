import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/services/ingestion/question_bulk_verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = QuestionBulkVerificationService();

  group('QuestionBulkVerificationService', () {
    test('verifies only pending questions with readable citations', () {
      final questions = [
        _question(
          id: 'pending-readable',
          sourceStatus: SourceStatus.pending,
          citationIds: const ['readable', 'missing', 'readable'],
        ),
        _question(
          id: 'pending-missing',
          sourceStatus: SourceStatus.pending,
          citationIds: const ['missing'],
        ),
        _question(
          id: 'already-verified',
          sourceStatus: SourceStatus.verified,
          citationIds: const ['readable'],
        ),
        _question(
          id: 'manually-no-source',
          sourceStatus: SourceStatus.noSource,
          citationIds: const ['readable'],
        ),
      ];

      final plan = service.buildPlan(
        questions: questions,
        readableCitationIds: const {'readable'},
      );

      expect(plan.updates, hasLength(1));
      expect(plan.updates.single.index, 0);
      expect(
        plan.updates.single.question.sourceStatus,
        SourceStatus.verified,
      );
      expect(plan.updates.single.question.citationIds, ['readable']);
      expect(plan.skippedPendingCount, 1);
    });

    test('keeps pending questions without readable citations unchanged', () {
      final question = _question(
        id: 'pending-missing',
        sourceStatus: SourceStatus.pending,
        citationIds: const ['missing'],
      );

      final plan = service.buildPlan(
        questions: [question],
        readableCitationIds: const {},
      );

      expect(plan.hasUpdates, isFalse);
      expect(plan.updatedQuestions, isEmpty);
      expect(plan.skippedPendingCount, 1);
      expect(question.sourceStatus, SourceStatus.pending);
      expect(question.citationIds, ['missing']);
    });

    test('loads each distinct citation only once', () async {
      final loadCounts = <String, int>{};
      final questions = [
        _question(
          id: 'first',
          sourceStatus: SourceStatus.pending,
          citationIds: const ['shared', 'missing', 'shared'],
        ),
        _question(
          id: 'second',
          sourceStatus: SourceStatus.pending,
          citationIds: const ['shared'],
        ),
      ];

      final plan = await service.buildPlanFromLoader(
        questions: questions,
        citationExists: (citationId) async {
          loadCounts.update(
            citationId,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          return citationId == 'shared';
        },
      );

      expect(loadCounts, {'shared': 1, 'missing': 1});
      expect(plan.updates, hasLength(2));
      expect(
        plan.updates.map((update) => update.question.citationIds),
        everyElement(['shared']),
      );
      expect(plan.skippedPendingCount, 0);
    });
  });
}

Question _question({
  required String id,
  required SourceStatus sourceStatus,
  required List<String> citationIds,
}) {
  return Question(
    id: id,
    deckId: 'deck-1',
    type: QuestionType.fillBlank,
    content: 'question $id',
    answer: 'answer',
    sourceStatus: sourceStatus,
    citationIds: citationIds,
  );
}
