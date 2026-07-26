import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/knowledge_base/knowledge_answer_citation_card.dart';
import 'package:dlg_q/features/knowledge_base/knowledge_answer_evidence_quality_badges.dart';
import 'package:dlg_q/features/knowledge_base/knowledge_search_ranking_reasons.dart';
import 'package:dlg_q/services/agent/knowledge_answer_session_summary.dart';

void main() {
  testWidgets('shows distinct answer states and inspectable ranking reasons',
      (tester) async {
    const claim = GroundedClaim(
      section: 'answer',
      text: 'JSON mode guarantees valid JSON.',
      evidence: [
        GroundedClaimEvidence(
          citationId: 'chunk-openai-json',
          quote: 'JSON mode guarantees valid JSON',
        ),
      ],
    );
    final grounded = KnowledgeAnswerSessionSummaryRecord.fromFields(
      question: 'What does JSON mode guarantee?',
      answer: claim.text,
      citationIds: const ['chunk-openai-json'],
      groundedClaims: const [claim],
      groundingDisposition: GroundingDisposition.grounded,
    );
    final partial = KnowledgeAnswerSessionSummaryRecord.fromFields(
      question: grounded.question,
      answer: claim.text,
      sourceGaps: const ['Schema guarantee claim needs another source.'],
      citationIds: const ['chunk-openai-json'],
      groundedClaims: const [claim],
      groundingDisposition: GroundingDisposition.partial,
    );
    final refused = KnowledgeAnswerSessionSummaryRecord.fromFields(
      question: grounded.question,
      sourceGaps: const ['No supplied source supports the requested claim.'],
      groundingDisposition: GroundingDisposition.refused,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KnowledgeAnswerEvidenceQualityBadges(record: grounded),
                KnowledgeAnswerEvidenceQualityBadges(record: partial),
                KnowledgeAnswerEvidenceQualityBadges(record: refused),
                const KnowledgeSearchRankingReasons(
                  reasons: [
                    '词项覆盖 3/3',
                    '正文匹配 +18',
                    '来源可信度 +12',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('证据合格'), findsOneWidget);
    expect(find.text('部分主张未支持'), findsOneWidget);
    expect(find.text('证据不足已拒答'), findsOneWidget);
    expect(
      find.textContaining('排序依据：词项覆盖 3/3'),
      findsOneWidget,
    );
    expect(find.textContaining('来源可信度 +12'), findsOneWidget);
  });

  testWidgets('opens the selected source chunk from a citation card',
      (tester) async {
    final now = DateTime.utc(2026, 7, 15);
    final source = Source(
      id: 'source-openai-json',
      title: 'OpenAI Structured Outputs guide',
      type: SourceType.officialDoc,
      uri: 'https://developers.openai.com/api/docs/guides/structured-outputs',
      trustLevel: SourceTrustLevel.officialDoc,
      createdAt: now,
      updatedAt: now,
    );
    final chunk = SourceChunk(
      id: 'chunk-openai-json',
      sourceId: source.id,
      chunkIndex: 0,
      content:
          'JSON mode guarantees valid JSON but does not guarantee schema conformance.',
      locator: 'Structured Outputs guide: JSON mode',
      createdAt: now,
    );
    String? openedChunkId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KnowledgeAnswerCitationCard(
            source: source,
            chunk: chunk,
            onOpenSourceChunk: (context, openedSource, openedChunk) async {
              expect(openedSource.id, source.id);
              openedChunkId = openedChunk.id;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.textContaining('OpenAI Structured Outputs guide'));
    await tester.pump();

    expect(openedChunkId, chunk.id);
  });
}
