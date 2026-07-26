import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/ai/grounded_claim_gate.dart';

void main() {
  test('accepts exact evidence quotes and removes forged evidence', () {
    final result = const GroundedClaimGate().evaluate(
      claims: const [
        GroundedClaim(
          section: 'answer',
          text: 'The transaction commits all changes together.',
          evidence: [
            GroundedClaimEvidence(
              citationId: 'chunk-transaction',
              quote: 'commits all changes together',
            ),
            GroundedClaimEvidence(
              citationId: 'invented',
              quote: 'invented quote',
            ),
          ],
        ),
      ],
      sourceChunks: [_chunk()],
    );

    expect(result.disposition, GroundingDisposition.grounded);
    expect(result.citationIds, ['chunk-transaction']);
    expect(result.invalidEvidenceCount, 1);
    expect(result.citationCoverage, 1);
  });

  test('marks mixed claim coverage partial and no coverage refused', () {
    final partial = const GroundedClaimGate().evaluate(
      claims: const [
        GroundedClaim(
          section: 'feedback',
          text: 'Supported claim.',
          evidence: [
            GroundedClaimEvidence(
              citationId: 'chunk-transaction',
              quote: 'all changes together',
            ),
          ],
        ),
        GroundedClaim(
          section: 'feedback',
          text: 'Unsupported claim.',
        ),
      ],
      sourceChunks: [_chunk()],
    );
    final refused = const GroundedClaimGate().evaluate(
      claims: const [
        GroundedClaim(section: 'answer', text: 'Unsupported claim.'),
      ],
      sourceChunks: [_chunk()],
    );

    expect(partial.disposition, GroundingDisposition.partial);
    expect(partial.citationCoverage, 0.5);
    expect(refused.disposition, GroundingDisposition.refused);
    expect(refused.citationCoverage, 0);
  });

  test('explicit evidence insufficiency always refuses', () {
    final result = const GroundedClaimGate().evaluate(
      claims: const [
        GroundedClaim(
          section: 'answer',
          text: 'A supported sentence.',
          evidence: [
            GroundedClaimEvidence(
              citationId: 'chunk-transaction',
              quote: 'all changes together',
            ),
          ],
        ),
      ],
      sourceChunks: [_chunk()],
      evidenceSufficient: false,
    );

    expect(result.disposition, GroundingDisposition.refused);
    expect(result.groundedClaims, hasLength(1));
  });
}

SourceChunk _chunk() {
  return SourceChunk(
    id: 'chunk-transaction',
    sourceId: 'source',
    chunkIndex: 0,
    content: 'An atomic transaction commits all changes together.',
    createdAt: DateTime.utc(2026, 7, 15),
  );
}
