enum CorrectnessEvaluationSurface {
  knowledgeAnswer('knowledge_answer'),
  tutorFeedback('tutor_feedback'),
  interviewEvaluation('interview_evaluation'),
  programmingExerciseEvaluation('programming_exercise_evaluation');

  final String value;

  const CorrectnessEvaluationSurface(this.value);

  static CorrectnessEvaluationSurface fromString(String value) {
    return CorrectnessEvaluationSurface.values.firstWhere(
      (surface) => surface.value == value,
      orElse: () => throw FormatException(
        'Unknown correctness evaluation surface: $value',
      ),
    );
  }
}

class RetrievalEvaluationCase {
  final String id;
  final List<String> relevantEvidenceIds;
  final List<String> rankedEvidenceIds;

  const RetrievalEvaluationCase({
    required this.id,
    required this.relevantEvidenceIds,
    required this.rankedEvidenceIds,
  });
}

class ClaimEvaluation {
  final String id;
  final bool supported;
  final List<String> supportingEvidenceIds;
  final List<String> citationIds;

  const ClaimEvaluation({
    required this.id,
    required this.supported,
    this.supportingEvidenceIds = const [],
    this.citationIds = const [],
  });

  bool get hasSupportingCitation {
    if (!supported || supportingEvidenceIds.isEmpty || citationIds.isEmpty) {
      return false;
    }
    final supportingIds = supportingEvidenceIds.toSet();
    return citationIds.any(supportingIds.contains);
  }
}

class GenerationEvaluationCase {
  final String id;
  final CorrectnessEvaluationSurface surface;
  final bool expectedRefusal;
  final bool actualRefusal;
  final List<ClaimEvaluation> claims;

  const GenerationEvaluationCase({
    required this.id,
    required this.surface,
    required this.expectedRefusal,
    required this.actualRefusal,
    this.claims = const [],
  });
}

class CorrectnessEvaluationReport {
  final int topK;
  final int retrievalCaseCount;
  final int generationCaseCount;
  final int supportedClaimCount;
  final int citationCoveredClaimCount;
  final int emittedClaimCount;
  final int unsupportedClaimCount;
  final int correctRefusalCount;
  final double recallAtK;
  final double meanReciprocalRank;
  final double citationCoverage;
  final double unsupportedClaimRate;
  final double refusalAccuracy;

  const CorrectnessEvaluationReport({
    required this.topK,
    required this.retrievalCaseCount,
    required this.generationCaseCount,
    required this.supportedClaimCount,
    required this.citationCoveredClaimCount,
    required this.emittedClaimCount,
    required this.unsupportedClaimCount,
    required this.correctRefusalCount,
    required this.recallAtK,
    required this.meanReciprocalRank,
    required this.citationCoverage,
    required this.unsupportedClaimRate,
    required this.refusalAccuracy,
  });
}

class CorrectnessEvaluationService {
  const CorrectnessEvaluationService();

  CorrectnessEvaluationReport evaluate({
    required List<RetrievalEvaluationCase> retrievalCases,
    required List<GenerationEvaluationCase> generationCases,
    int topK = 5,
  }) {
    if (topK <= 0) {
      throw ArgumentError.value(topK, 'topK', 'must be greater than zero');
    }

    final measurableRetrievalCases = retrievalCases
        .where(
            (evaluationCase) => evaluationCase.relevantEvidenceIds.isNotEmpty)
        .toList();
    var recallTotal = 0.0;
    var reciprocalRankTotal = 0.0;

    for (final evaluationCase in measurableRetrievalCases) {
      final relevantIds = evaluationCase.relevantEvidenceIds.toSet();
      final rankedIds = evaluationCase.rankedEvidenceIds
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final retrievedRelevantCount =
          rankedIds.take(topK).where(relevantIds.contains).length;
      recallTotal += retrievedRelevantCount / relevantIds.length;

      final firstRelevantIndex = rankedIds.indexWhere(relevantIds.contains);
      if (firstRelevantIndex >= 0) {
        reciprocalRankTotal += 1 / (firstRelevantIndex + 1);
      }
    }

    final claims = generationCases
        .expand((evaluationCase) => evaluationCase.claims)
        .toList();
    final supportedClaims = claims.where((claim) => claim.supported).toList();
    final citationCoveredClaimCount =
        supportedClaims.where((claim) => claim.hasSupportingCitation).length;
    final unsupportedClaimCount =
        claims.where((claim) => !claim.supported).length;
    final correctRefusalCount = generationCases
        .where(
          (evaluationCase) =>
              evaluationCase.expectedRefusal == evaluationCase.actualRefusal,
        )
        .length;

    return CorrectnessEvaluationReport(
      topK: topK,
      retrievalCaseCount: measurableRetrievalCases.length,
      generationCaseCount: generationCases.length,
      supportedClaimCount: supportedClaims.length,
      citationCoveredClaimCount: citationCoveredClaimCount,
      emittedClaimCount: claims.length,
      unsupportedClaimCount: unsupportedClaimCount,
      correctRefusalCount: correctRefusalCount,
      recallAtK: _average(recallTotal, measurableRetrievalCases.length),
      meanReciprocalRank:
          _average(reciprocalRankTotal, measurableRetrievalCases.length),
      citationCoverage:
          _ratio(citationCoveredClaimCount, supportedClaims.length),
      unsupportedClaimRate: _ratio(unsupportedClaimCount, claims.length),
      refusalAccuracy: _ratio(correctRefusalCount, generationCases.length),
    );
  }

  double _average(double total, int count) {
    return count == 0 ? 0 : total / count;
  }

  double _ratio(int numerator, int denominator) {
    return denominator == 0 ? 0 : numerator / denominator;
  }
}
