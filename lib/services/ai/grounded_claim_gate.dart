import '../../data/models/grounded_claim.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/source_chunk.dart';

class GroundedClaimGateResult {
  final GroundingDisposition disposition;
  final List<GroundedClaim> groundedClaims;
  final List<GroundedClaim> uncoveredClaims;
  final int invalidEvidenceCount;

  const GroundedClaimGateResult({
    required this.disposition,
    required this.groundedClaims,
    required this.uncoveredClaims,
    required this.invalidEvidenceCount,
  });

  List<String> get citationIds => groundedClaims
      .expand((claim) => claim.citationIds)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  double get citationCoverage {
    final total = groundedClaims.length + uncoveredClaims.length;
    return total == 0 ? 0 : groundedClaims.length / total;
  }

  List<GroundedClaim> claimsForSection(String section) {
    return groundedClaims.where((claim) => claim.section == section).toList();
  }
}

class GroundedClaimGate {
  const GroundedClaimGate();

  GroundedClaimGateResult evaluate({
    required List<GroundedClaim> claims,
    required List<SourceChunk> sourceChunks,
    bool evidenceSufficient = true,
  }) {
    final chunksById = {
      for (final chunk in sourceChunks) chunk.id: chunk,
    };
    return _evaluate(
      claims: claims,
      evidenceSufficient: evidenceSufficient,
      containsQuote: (citationId, quote) {
        final chunk = chunksById[citationId];
        return chunk != null &&
            _normalize(chunk.content).contains(_normalize(quote));
      },
    );
  }

  GroundedClaimGateResult evaluateContext({
    required List<GroundedClaim> claims,
    required GroundedLearningContext context,
    bool evidenceSufficient = true,
  }) {
    return _evaluate(
      claims: claims,
      evidenceSufficient: evidenceSufficient && context.isExecutable,
      containsQuote: (citationId, quote) {
        return context.itemForChunkId(citationId)?.quoteBoundary.containsQuote(
                  quote,
                ) ??
            false;
      },
    );
  }

  GroundedClaimGateResult _evaluate({
    required List<GroundedClaim> claims,
    required bool evidenceSufficient,
    required bool Function(String citationId, String quote) containsQuote,
  }) {
    final groundedClaims = <GroundedClaim>[];
    final uncoveredClaims = <GroundedClaim>[];
    var invalidEvidenceCount = 0;

    for (final claim in claims) {
      final text = claim.text.trim();
      final section = claim.section.trim();
      if (text.isEmpty || section.isEmpty) {
        uncoveredClaims.add(claim.copyWith(text: text, section: section));
        invalidEvidenceCount += claim.evidence.length;
        continue;
      }

      final validEvidence = <GroundedClaimEvidence>[];
      final seenEvidence = <String>{};
      for (final evidence in claim.evidence) {
        final citationId = evidence.citationId.trim();
        final quote = evidence.quote.trim();
        final key = '$citationId\x00${_normalize(quote)}';
        if (quote.isEmpty ||
            !containsQuote(citationId, quote) ||
            !seenEvidence.add(key)) {
          invalidEvidenceCount += 1;
          continue;
        }
        validEvidence.add(
          GroundedClaimEvidence(citationId: citationId, quote: quote),
        );
      }

      final sanitized = claim.copyWith(
        section: section,
        text: text,
        evidence: validEvidence,
      );
      if (validEvidence.isEmpty) {
        uncoveredClaims.add(sanitized);
      } else {
        groundedClaims.add(sanitized);
      }
    }

    final disposition = !evidenceSufficient || groundedClaims.isEmpty
        ? GroundingDisposition.refused
        : uncoveredClaims.isEmpty
            ? GroundingDisposition.grounded
            : GroundingDisposition.partial;
    return GroundedClaimGateResult(
      disposition: disposition,
      groundedClaims: groundedClaims,
      uncoveredClaims: uncoveredClaims,
      invalidEvidenceCount: invalidEvidenceCount,
    );
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }
}
