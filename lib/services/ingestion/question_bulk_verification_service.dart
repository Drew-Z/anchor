import '../../data/models/question.dart';

class QuestionBulkVerificationUpdate {
  final int index;
  final Question question;

  const QuestionBulkVerificationUpdate({
    required this.index,
    required this.question,
  });
}

class QuestionBulkVerificationPlan {
  final List<QuestionBulkVerificationUpdate> updates;
  final int skippedPendingCount;

  const QuestionBulkVerificationPlan({
    required this.updates,
    required this.skippedPendingCount,
  });

  bool get hasUpdates => updates.isNotEmpty;

  List<Question> get updatedQuestions =>
      updates.map((update) => update.question).toList();
}

class QuestionBulkVerificationService {
  const QuestionBulkVerificationService();

  QuestionBulkVerificationPlan buildPlan({
    required List<Question> questions,
    required Set<String> readableCitationIds,
    Set<int> ignoredIndexes = const {},
  }) {
    final updates = <QuestionBulkVerificationUpdate>[];
    var skippedPendingCount = 0;

    for (final entry in questions.asMap().entries) {
      if (ignoredIndexes.contains(entry.key)) continue;
      final question = entry.value;
      if (question.sourceStatus != SourceStatus.pending) continue;

      final validCitationIds = question.citationIds
          .where(readableCitationIds.contains)
          .toSet()
          .toList();
      if (validCitationIds.isEmpty) {
        skippedPendingCount++;
        continue;
      }

      updates.add(
        QuestionBulkVerificationUpdate(
          index: entry.key,
          question: question.copyWith(
            sourceStatus: SourceStatus.verified,
            citationIds: validCitationIds,
          ),
        ),
      );
    }

    return QuestionBulkVerificationPlan(
      updates: updates,
      skippedPendingCount: skippedPendingCount,
    );
  }

  Future<QuestionBulkVerificationPlan> buildPlanFromLoader({
    required List<Question> questions,
    required Future<bool> Function(String citationId) citationExists,
  }) async {
    final readableCitationIds = <String>{};
    final citationIds = questions
        .where((question) => question.sourceStatus == SourceStatus.pending)
        .expand((question) => question.citationIds)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final citationId in citationIds) {
      if (await citationExists(citationId)) {
        readableCitationIds.add(citationId);
      }
    }

    return buildPlan(
      questions: questions,
      readableCitationIds: readableCitationIds,
    );
  }
}
