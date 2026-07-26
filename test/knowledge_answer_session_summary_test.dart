import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/services/agent/knowledge_answer_session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips claim-level grounding audit in a knowledge answer summary',
      () {
    const claim = GroundedClaim(
      section: 'answer',
      text: 'The repository persists the learning session.',
      evidence: [
        GroundedClaimEvidence(
          citationId: 'chunk-repository',
          quote: 'persists the learning session',
        ),
      ],
    );

    final summary = buildKnowledgeAnswerSessionSummary(
      knowledgePointId: 'point-repository',
      groundedContextId: 'context:knowledge_answer:repository:chunk-repository',
      question: 'What does the repository do?',
      answer: claim.text,
      citationIds: const ['chunk-repository'],
      groundedClaims: const [claim],
      groundingDisposition: GroundingDisposition.grounded,
    );
    final record = KnowledgeAnswerSessionSummaryRecord.fromSummary(summary);

    expect(record.question, 'What does the repository do?');
    expect(record.knowledgePointId, 'point-repository');
    expect(
      record.groundedContextId,
      'context:knowledge_answer:repository:chunk-repository',
    );
    expect(record.answer, claim.text);
    expect(record.groundingDisposition, GroundingDisposition.grounded);
    expect(record.groundedClaims, hasLength(1));
    expect(record.groundedClaims.single.text, claim.text);
    expect(
      record.groundedClaims.single.evidence.single.citationId,
      'chunk-repository',
    );
    expect(record.hasCleanEvidence, isTrue);
  });

  test('keeps legacy summaries readable without treating them as audited', () {
    final record = KnowledgeAnswerSessionSummaryRecord.fromSummary(
      '知识库问答: What does the repository do?\n'
      '回答: It persists a session.\n'
      '引用: chunk-repository',
    );

    expect(record.answer, 'It persists a session.');
    expect(record.knowledgePointId, isNull);
    expect(record.groundedContextId, isNull);
    expect(record.citationIds, ['chunk-repository']);
    expect(record.groundingDisposition, GroundingDisposition.legacy);
    expect(record.groundedClaims, isEmpty);
    expect(record.hasCleanEvidence, isFalse);
    expect(
      knowledgeAnswerEvidenceQualityLabels(record),
      contains('历史记录未审计'),
    );
  });
}
