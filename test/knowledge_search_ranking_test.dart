import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/services/agent/knowledge_answer_context_service.dart';
import 'package:dlg_q/services/agent/knowledge_search_service.dart';

void main() {
  test('trust is scaled by relevance and ranking reasons are inspectable', () {
    final corpus = _corpus();
    const service = KnowledgeSearchService();

    final exactResults = service.search(
      query: 'JSON schema guarantee',
      corpus: corpus,
    );
    final exactChunks = exactResults
        .where((result) => result.type == KnowledgeSearchResultType.sourceChunk)
        .toList();

    expect(exactChunks.first.sourceChunkId, 'chunk-official-json');
    expect(exactChunks.first.scoreBreakdown.termCoverage, 1);
    expect(exactChunks.first.scoreBreakdown.trustScore, greaterThan(0));
    expect(
      exactChunks.first.scoreBreakdown.reasonLabels,
      contains(startsWith('来源可信度')),
    );

    final relevanceResults = service.search(
      query: 'local retry timeout',
      corpus: corpus,
    );
    final relevanceChunks = relevanceResults
        .where((result) => result.type == KnowledgeSearchResultType.sourceChunk)
        .toList();

    expect(relevanceChunks.first.sourceChunkId, 'chunk-personal-retry');
    expect(
      relevanceChunks.first.scoreBreakdown.matchedTermCount,
      greaterThan(
        relevanceChunks.last.scoreBreakdown.matchedTermCount,
      ),
    );
  });

  test('equal results use a stable evidence-first id tie break', () {
    final now = DateTime.utc(2026, 7, 15);
    final corpus = KnowledgeSearchCorpus(
      sources: [
        Source(
          id: 'source',
          title: 'Reference',
          type: SourceType.text,
          trustLevel: SourceTrustLevel.unknown,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sourceChunks: [
        SourceChunk(
          id: 'chunk-b',
          sourceId: 'source',
          chunkIndex: 1,
          content: 'stable token',
          createdAt: now,
        ),
        SourceChunk(
          id: 'chunk-a',
          sourceId: 'source',
          chunkIndex: 0,
          content: 'stable token',
          createdAt: now,
        ),
      ],
      knowledgePoints: const [],
      questions: const [],
    );

    final results = const KnowledgeSearchService()
        .search(query: 'stable token', corpus: corpus)
        .where((result) => result.type == KnowledgeSearchResultType.sourceChunk)
        .toList();

    expect(results.map((result) => result.sourceChunkId), [
      'chunk-a',
      'chunk-b',
    ]);
  });

  test('context selection uses matching chunks and verified citations', () {
    final corpus = _corpus();
    const searchService = KnowledgeSearchService();
    const contextService = KnowledgeAnswerContextService();
    final results = searchService.search(
      query: 'atomic transaction',
      corpus: corpus,
    );

    final selection = contextService.select(
      results: results,
      sourceChunks: corpus.sourceChunks,
    );

    expect(selection.chunks.first.id, 'chunk-transaction');
    expect(
      selection.chunks.map((chunk) => chunk.id),
      isNot(contains('chunk-unrelated-first')),
    );
    expect(selection.candidates.first.rankingReasons, isNotEmpty);

    final citationResults = searchService.search(
      query: 'rollback field',
      corpus: corpus,
    );
    final citationSelection = contextService.select(
      results: citationResults,
      sourceChunks: corpus.sourceChunks,
    );

    expect(
      citationSelection.candidates
          .firstWhere((candidate) => candidate.chunk.id == 'chunk-transaction')
          .reason,
      KnowledgeAnswerContextReason.questionCitation,
    );
  });
}

KnowledgeSearchCorpus _corpus() {
  final now = DateTime.utc(2026, 7, 15);
  final sources = [
    Source(
      id: 'official-json',
      title: 'OpenAI JSON output',
      type: SourceType.officialDoc,
      trustLevel: SourceTrustLevel.officialDoc,
      createdAt: now,
      updatedAt: now,
    ),
    Source(
      id: 'personal-json',
      title: 'JSON schema guarantee notes',
      type: SourceType.userNote,
      trustLevel: SourceTrustLevel.userNote,
      createdAt: now,
      updatedAt: now,
    ),
    Source(
      id: 'official-transaction',
      title: 'Atomic transaction reference',
      type: SourceType.officialDoc,
      trustLevel: SourceTrustLevel.officialDoc,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final chunks = [
    SourceChunk(
      id: 'chunk-official-json',
      sourceId: 'official-json',
      chunkIndex: 0,
      content:
          'JSON schema guarantee is not provided by JSON mode. Valid JSON does not imply schema conformance. Retry behavior is provider specific.',
      createdAt: now,
    ),
    SourceChunk(
      id: 'chunk-personal-retry',
      sourceId: 'personal-json',
      chunkIndex: 0,
      content:
          'JSON schema guarantee is automatic. Local retry timeout is configured by the app.',
      createdAt: now,
    ),
    SourceChunk(
      id: 'chunk-unrelated-first',
      sourceId: 'official-transaction',
      chunkIndex: 0,
      content: 'This section lists connection pragma options.',
      createdAt: now,
    ),
    SourceChunk(
      id: 'chunk-transaction',
      sourceId: 'official-transaction',
      chunkIndex: 1,
      content:
          'An atomic transaction commits all changes or rolls all changes back.',
      createdAt: now,
    ),
  ];
  return KnowledgeSearchCorpus(
    sources: sources,
    sourceChunks: chunks,
    knowledgePoints: const [],
    questions: [
      Question(
        id: 'question-rollback',
        deckId: 'deck',
        type: QuestionType.fillBlank,
        content: 'Which rollback field describes an atomic failure?',
        answer: 'Rollback all changes.',
        sourceStatus: SourceStatus.verified,
        citationIds: const ['chunk-transaction'],
      ),
    ],
  );
}
