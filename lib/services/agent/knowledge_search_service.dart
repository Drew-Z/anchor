import '../../data/models/knowledge_point.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import 'search_query_term_service.dart';

enum KnowledgeSearchResultType {
  source('来源'),
  sourceChunk('来源片段'),
  knowledgePoint('知识点'),
  question('题目');

  final String label;
  const KnowledgeSearchResultType(this.label);
}

class KnowledgeSearchCorpus {
  final List<Source> sources;
  final List<SourceChunk> sourceChunks;
  final List<KnowledgePoint> knowledgePoints;
  final List<Question> questions;

  const KnowledgeSearchCorpus({
    required this.sources,
    required this.sourceChunks,
    required this.knowledgePoints,
    required this.questions,
  });
}

class KnowledgeSearchScoreBreakdown {
  final int matchedTermCount;
  final int queryTermCount;
  final int coverageScore;
  final int phraseScore;
  final int titleScore;
  final int bodyScore;
  final int metadataScore;
  final int trustScore;
  final int verificationScore;
  final List<String> matchedTerms;

  const KnowledgeSearchScoreBreakdown({
    this.matchedTermCount = 0,
    this.queryTermCount = 0,
    this.coverageScore = 0,
    this.phraseScore = 0,
    this.titleScore = 0,
    this.bodyScore = 0,
    this.metadataScore = 0,
    this.trustScore = 0,
    this.verificationScore = 0,
    this.matchedTerms = const [],
  });

  int get total =>
      coverageScore +
      phraseScore +
      titleScore +
      bodyScore +
      metadataScore +
      trustScore +
      verificationScore;

  double get termCoverage =>
      queryTermCount == 0 ? 0 : matchedTermCount / queryTermCount;

  List<String> get reasonLabels => [
        '词项覆盖 $matchedTermCount/$queryTermCount',
        if (phraseScore != 0) '短语匹配 ${_signed(phraseScore)}',
        if (titleScore != 0) '标题匹配 ${_signed(titleScore)}',
        if (bodyScore != 0) '正文匹配 ${_signed(bodyScore)}',
        if (metadataScore != 0) '元数据匹配 ${_signed(metadataScore)}',
        if (trustScore != 0) '来源可信度 ${_signed(trustScore)}',
        if (verificationScore != 0) '核验状态 ${_signed(verificationScore)}',
      ];

  KnowledgeSearchScoreBreakdown copyWith({
    int? trustScore,
    int? verificationScore,
  }) {
    return KnowledgeSearchScoreBreakdown(
      matchedTermCount: matchedTermCount,
      queryTermCount: queryTermCount,
      coverageScore: coverageScore,
      phraseScore: phraseScore,
      titleScore: titleScore,
      bodyScore: bodyScore,
      metadataScore: metadataScore,
      trustScore: trustScore ?? this.trustScore,
      verificationScore: verificationScore ?? this.verificationScore,
      matchedTerms: matchedTerms,
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class KnowledgeSearchResult {
  final KnowledgeSearchResultType type;
  final String title;
  final String snippet;
  final int score;
  final String? sourceId;
  final String? sourceChunkId;
  final String? knowledgePointId;
  final String? questionId;
  final List<String> citationIds;
  final SourceTrustLevel? trustLevel;
  final SourceStatus? sourceStatus;
  final KnowledgeSearchScoreBreakdown scoreBreakdown;

  const KnowledgeSearchResult({
    required this.type,
    required this.title,
    required this.snippet,
    required this.score,
    this.sourceId,
    this.sourceChunkId,
    this.knowledgePointId,
    this.questionId,
    this.citationIds = const [],
    this.trustLevel,
    this.sourceStatus,
    this.scoreBreakdown = const KnowledgeSearchScoreBreakdown(),
  });
}

class KnowledgeSearchService {
  const KnowledgeSearchService();

  List<KnowledgeSearchResult> search({
    required String query,
    required KnowledgeSearchCorpus corpus,
    int limit = 20,
  }) {
    final terms = _terms(query);
    if (terms.isEmpty || limit <= 0) return const [];
    final normalizedQuery = _clean(query).toLowerCase();

    final sourceById = {
      for (final source in corpus.sources) source.id: source,
    };
    final results = <KnowledgeSearchResult>[
      for (final source in corpus.sources)
        ..._sourceResult(source, terms, normalizedQuery),
      for (final chunk in corpus.sourceChunks)
        ..._chunkResult(
          chunk,
          sourceById[chunk.sourceId],
          terms,
          normalizedQuery,
        ),
      for (final point in corpus.knowledgePoints)
        ..._pointResult(point, terms, normalizedQuery),
      for (final question in corpus.questions)
        ..._questionResult(question, terms, normalizedQuery),
    ];

    results.sort(_compareResults);
    return results.take(limit).toList();
  }

  List<KnowledgeSearchResult> _sourceResult(
    Source source,
    List<String> terms,
    String normalizedQuery,
  ) {
    final base = _score(
      terms: terms,
      normalizedQuery: normalizedQuery,
      title: source.title,
      body: [source.uri ?? ''],
      metadata: [
        source.type.label,
        source.trustLevel.label,
        source.publisher ?? '',
        source.revision ?? '',
      ],
    );
    if (base == null) return const [];
    final ranking = _withRankSignals(
      base,
      trustLevel: source.trustLevel,
    );

    return [
      KnowledgeSearchResult(
        type: KnowledgeSearchResultType.source,
        title: source.title,
        snippet: _snippet(terms, [source.uri ?? source.type.label]),
        score: ranking.total,
        sourceId: source.id,
        trustLevel: source.trustLevel,
        scoreBreakdown: ranking,
      ),
    ];
  }

  List<KnowledgeSearchResult> _chunkResult(
    SourceChunk chunk,
    Source? source,
    List<String> terms,
    String normalizedQuery,
  ) {
    final sourceTitle = source?.title ?? '';
    final chunkFields = [
      chunk.content,
      chunk.locator ?? '',
      chunk.relativePath ?? '',
    ];
    if (!_containsAnyTerm(terms, chunkFields)) return const [];
    final base = _score(
      terms: terms,
      normalizedQuery: normalizedQuery,
      title: chunk.locator ?? chunk.relativePath ?? '',
      body: [chunk.content],
      metadata: [sourceTitle],
    );
    if (base == null) return const [];
    final ranking = _withRankSignals(
      base,
      trustLevel: source?.trustLevel,
    );

    return [
      KnowledgeSearchResult(
        type: KnowledgeSearchResultType.sourceChunk,
        title:
            sourceTitle.isEmpty ? '来源片段 ${chunk.chunkIndex + 1}' : sourceTitle,
        snippet: _snippet(terms, [chunk.content, chunk.locator ?? '']),
        score: ranking.total,
        sourceId: chunk.sourceId,
        sourceChunkId: chunk.id,
        trustLevel: source?.trustLevel,
        scoreBreakdown: ranking,
      ),
    ];
  }

  List<KnowledgeSearchResult> _pointResult(
    KnowledgePoint point,
    List<String> terms,
    String normalizedQuery,
  ) {
    final ranking = _score(
      terms: terms,
      normalizedQuery: normalizedQuery,
      title: point.title,
      body: [point.summary],
      metadata: [point.kind.label, point.kind.value, ...point.tags],
    );
    if (ranking == null) return const [];

    return [
      KnowledgeSearchResult(
        type: KnowledgeSearchResultType.knowledgePoint,
        title: point.title,
        snippet: _snippet(
          terms,
          [point.kind.label, point.summary, point.tags.join(' · ')],
        ),
        score: ranking.total,
        knowledgePointId: point.id,
        scoreBreakdown: ranking,
      ),
    ];
  }

  List<KnowledgeSearchResult> _questionResult(
    Question question,
    List<String> terms,
    String normalizedQuery,
  ) {
    final base = _score(
      terms: terms,
      normalizedQuery: normalizedQuery,
      title: question.content,
      body: [
        question.answer,
        question.explanation ?? '',
        ...question.options,
      ],
      metadata: [question.sourceStatus.label],
    );
    if (base == null) return const [];
    final ranking = _withRankSignals(
      base,
      sourceStatus: question.sourceStatus,
    );

    return [
      KnowledgeSearchResult(
        type: KnowledgeSearchResultType.question,
        title: question.content,
        snippet: _snippet(
          terms,
          [
            question.explanation ?? '',
            question.answer,
            question.options.join(' · '),
          ],
        ),
        score: ranking.total,
        knowledgePointId: question.knowledgePointId,
        questionId: question.id,
        citationIds: question.citationIds,
        sourceStatus: question.sourceStatus,
        scoreBreakdown: ranking,
      ),
    ];
  }

  KnowledgeSearchScoreBreakdown? _score({
    required List<String> terms,
    required String normalizedQuery,
    required String title,
    required List<String> body,
    required List<String> metadata,
  }) {
    final normalizedTitle = _clean(title).toLowerCase();
    final normalizedBody = _normalizedFields(body);
    final normalizedMetadata = _normalizedFields(metadata);
    final matchedTerms = terms
        .where(
          (term) =>
              normalizedTitle.contains(term) ||
              normalizedBody.any((field) => field.contains(term)) ||
              normalizedMetadata.any((field) => field.contains(term)),
        )
        .toList();
    if (matchedTerms.isEmpty) return null;

    final titleMatches =
        terms.where((term) => normalizedTitle.contains(term)).length;
    final bodyMatches = terms
        .where((term) => normalizedBody.any((field) => field.contains(term)))
        .length;
    final metadataMatches = terms
        .where(
          (term) => normalizedMetadata.any((field) => field.contains(term)),
        )
        .length;
    final queryTermCount = terms.length;
    final phraseScore = normalizedQuery.isEmpty
        ? 0
        : (normalizedTitle.contains(normalizedQuery) ? 8 : 0) +
            (normalizedBody.any((field) => field.contains(normalizedQuery))
                ? 12
                : 0) +
            (normalizedMetadata.any((field) => field.contains(normalizedQuery))
                ? 4
                : 0);

    return KnowledgeSearchScoreBreakdown(
      matchedTermCount: matchedTerms.length,
      queryTermCount: queryTermCount,
      coverageScore: (100 * matchedTerms.length / queryTermCount).round(),
      phraseScore: phraseScore,
      titleScore: (10 * titleMatches / queryTermCount).round(),
      bodyScore: (20 * bodyMatches / queryTermCount).round(),
      metadataScore: (4 * metadataMatches / queryTermCount).round(),
      matchedTerms: matchedTerms,
    );
  }

  KnowledgeSearchScoreBreakdown _withRankSignals(
    KnowledgeSearchScoreBreakdown base, {
    SourceTrustLevel? trustLevel,
    SourceStatus? sourceStatus,
  }) {
    return base.copyWith(
      trustScore: (_trustWeight(trustLevel) * base.termCoverage).round(),
      verificationScore:
          (_verificationWeight(sourceStatus) * base.termCoverage).round(),
    );
  }

  int _trustWeight(SourceTrustLevel? trustLevel) {
    switch (trustLevel) {
      case SourceTrustLevel.officialDoc:
        return 28;
      case SourceTrustLevel.sourceCode:
        return 24;
      case SourceTrustLevel.bookCourse:
        return 16;
      case SourceTrustLevel.article:
        return 6;
      case SourceTrustLevel.userNote:
      case SourceTrustLevel.unknown:
      case null:
        return 0;
    }
  }

  int _verificationWeight(SourceStatus? sourceStatus) {
    switch (sourceStatus) {
      case SourceStatus.verified:
        return 12;
      case SourceStatus.pending:
        return 2;
      case SourceStatus.noSource:
        return -8;
      case null:
        return 0;
    }
  }

  int _compareResults(KnowledgeSearchResult a, KnowledgeSearchResult b) {
    var comparison = b.score.compareTo(a.score);
    if (comparison != 0) return comparison;
    comparison = b.scoreBreakdown.matchedTermCount
        .compareTo(a.scoreBreakdown.matchedTermCount);
    if (comparison != 0) return comparison;
    comparison =
        b.scoreBreakdown.trustScore.compareTo(a.scoreBreakdown.trustScore);
    if (comparison != 0) return comparison;
    comparison = _typePriority(a.type).compareTo(_typePriority(b.type));
    if (comparison != 0) return comparison;
    comparison = a.title.compareTo(b.title);
    if (comparison != 0) return comparison;
    return _stableId(a).compareTo(_stableId(b));
  }

  int _typePriority(KnowledgeSearchResultType type) {
    switch (type) {
      case KnowledgeSearchResultType.sourceChunk:
        return 0;
      case KnowledgeSearchResultType.question:
        return 1;
      case KnowledgeSearchResultType.source:
        return 2;
      case KnowledgeSearchResultType.knowledgePoint:
        return 3;
    }
  }

  String _stableId(KnowledgeSearchResult result) {
    return result.sourceChunkId ??
        result.questionId ??
        result.sourceId ??
        result.knowledgePointId ??
        result.title;
  }

  List<String> _terms(String query) {
    return const SearchQueryTermService().terms(query);
  }

  List<String> _normalizedFields(List<String> fields) {
    return fields
        .map((field) => _clean(field).toLowerCase())
        .where((field) => field.isNotEmpty)
        .toList();
  }

  bool _containsAnyTerm(List<String> terms, List<String> fields) {
    final normalizedFields = _normalizedFields(fields);
    return terms.any(
      (term) => normalizedFields.any((field) => field.contains(term)),
    );
  }

  String _snippet(List<String> terms, List<String> fields) {
    for (final field in fields) {
      final cleaned = _clean(field);
      if (cleaned.isEmpty) continue;
      final lower = cleaned.toLowerCase();
      final term = terms.firstWhere(
        (term) => lower.contains(term),
        orElse: () => '',
      );
      if (term.isEmpty) continue;
      return _window(cleaned, lower.indexOf(term));
    }

    final fallback = fields.map(_clean).firstWhere(
          (field) => field.isNotEmpty,
          orElse: () => '',
        );
    return _window(fallback, 0);
  }

  String _window(String text, int index) {
    if (text.length <= 140) return text;
    final start = index <= 40 ? 0 : index - 40;
    final end = start + 140 >= text.length ? text.length : start + 140;
    final prefix = start == 0 ? '' : '...';
    final suffix = end == text.length ? '' : '...';
    return '$prefix${text.substring(start, end)}$suffix';
  }

  String _clean(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
