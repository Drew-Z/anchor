import '../../data/models/source_chunk.dart';
import 'knowledge_search_service.dart';

enum KnowledgeAnswerContextReason {
  directChunk('直接命中来源片段'),
  questionCitation('命中题目的已保存引用'),
  matchedSourceChunk('命中来源中的相关片段');

  final String label;

  const KnowledgeAnswerContextReason(this.label);
}

class KnowledgeAnswerContextCandidate {
  final SourceChunk chunk;
  final KnowledgeAnswerContextReason reason;
  final KnowledgeSearchResult searchResult;

  const KnowledgeAnswerContextCandidate({
    required this.chunk,
    required this.reason,
    required this.searchResult,
  });

  List<String> get rankingReasons => [
        reason.label,
        ...searchResult.scoreBreakdown.reasonLabels,
      ];
}

class KnowledgeAnswerContextSelection {
  final List<KnowledgeAnswerContextCandidate> candidates;

  const KnowledgeAnswerContextSelection(this.candidates);

  List<SourceChunk> get chunks =>
      candidates.map((candidate) => candidate.chunk).toList();
}

class KnowledgeAnswerContextService {
  const KnowledgeAnswerContextService();

  KnowledgeAnswerContextSelection select({
    required List<KnowledgeSearchResult> results,
    required List<SourceChunk> sourceChunks,
    int limit = 8,
    int maxMatchedChunksPerSource = 2,
  }) {
    if (limit <= 0 || sourceChunks.isEmpty || results.isEmpty) {
      return const KnowledgeAnswerContextSelection([]);
    }

    final chunksById = {
      for (final chunk in sourceChunks) chunk.id: chunk,
    };
    final matchingChunkResultsBySource =
        <String, List<KnowledgeSearchResult>>{};
    for (final result in results) {
      final chunkId = result.sourceChunkId;
      final sourceId = result.sourceId;
      if (chunkId == null ||
          sourceId == null ||
          !chunksById.containsKey(chunkId)) {
        continue;
      }
      matchingChunkResultsBySource.putIfAbsent(sourceId, () => []).add(result);
    }

    final candidates = <KnowledgeAnswerContextCandidate>[];
    final seenChunkIds = <String>{};

    void addCandidate(
      String chunkId,
      KnowledgeAnswerContextReason reason,
      KnowledgeSearchResult searchResult,
    ) {
      final chunk = chunksById[chunkId];
      if (chunk == null || !seenChunkIds.add(chunkId)) return;
      candidates.add(
        KnowledgeAnswerContextCandidate(
          chunk: chunk,
          reason: reason,
          searchResult: searchResult,
        ),
      );
    }

    for (final result in results) {
      final directChunkId = result.sourceChunkId;
      if (directChunkId != null) {
        addCandidate(
          directChunkId,
          KnowledgeAnswerContextReason.directChunk,
          result,
        );
      }
      for (final citationId in result.citationIds) {
        addCandidate(
          citationId,
          KnowledgeAnswerContextReason.questionCitation,
          result,
        );
      }
      if (result.type == KnowledgeSearchResultType.source &&
          result.sourceId != null) {
        final matchingResults =
            matchingChunkResultsBySource[result.sourceId] ?? const [];
        for (final chunkResult
            in matchingResults.take(maxMatchedChunksPerSource)) {
          addCandidate(
            chunkResult.sourceChunkId!,
            KnowledgeAnswerContextReason.matchedSourceChunk,
            chunkResult,
          );
        }
      }
      if (candidates.length >= limit) break;
    }

    return KnowledgeAnswerContextSelection(candidates.take(limit).toList());
  }
}
