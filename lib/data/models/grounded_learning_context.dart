import 'knowledge_point.dart';
import 'source.dart';
import 'source_chunk.dart';

enum GroundedLearningSurface {
  knowledgeAnswer('knowledge_answer', '知识库回答'),
  tutor('tutor', '导师'),
  interview('interview', '面试'),
  programmingExerciseEvaluation(
    'programming_exercise_evaluation',
    '编程练习评价',
  );

  final String value;
  final String label;

  const GroundedLearningSurface(this.value, this.label);
}

enum GroundedLearningContextReason {
  knowledgeSearch('knowledge_search', '知识检索命中'),
  questionCitation('question_citation', '题目引用'),
  targetRelation('target_relation', '目标知识点来源'),
  prerequisiteRelation('prerequisite_relation', '已确认先修来源'),
  practiceCitation('practice_citation', '练习引用');

  final String value;
  final String label;

  const GroundedLearningContextReason(this.value, this.label);
}

enum GroundedLearningContextRejectionCode {
  missingTarget('missing_target', '缺少目标'),
  missingSource('missing_source', '来源记录缺失'),
  emptyChunk('empty_chunk', '来源片段为空'),
  missingSelectionReason('missing_selection_reason', '缺少选择理由'),
  missingRequiredCitation('missing_required_citation', '指定引用不可用'),
  contextLimit('context_limit', '超过上下文上限');

  final String value;
  final String label;

  const GroundedLearningContextRejectionCode(this.value, this.label);
}

class GroundedLearningQuoteBoundary {
  final String sourceChunkId;
  final int startOffset;
  final int endOffset;
  final String exactText;

  const GroundedLearningQuoteBoundary({
    required this.sourceChunkId,
    required this.startOffset,
    required this.endOffset,
    required this.exactText,
  });

  bool containsQuote(String quote) {
    final normalizedQuote = _normalizeQuote(quote);
    if (normalizedQuote.isEmpty) return false;
    return _normalizeQuote(exactText).contains(normalizedQuote);
  }
}

class GroundedLearningContextItem {
  final SourceChunk chunk;
  final Source source;
  final List<GroundedLearningContextReason> selectionReasons;
  final GroundedLearningQuoteBoundary quoteBoundary;

  const GroundedLearningContextItem({
    required this.chunk,
    required this.source,
    required this.selectionReasons,
    required this.quoteBoundary,
  });

  SourceTrustLevel get trustLevel => source.trustLevel;

  String get locator {
    final direct = chunk.locator?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final relativePath = chunk.relativePath?.trim();
    if (relativePath != null && relativePath.isNotEmpty) {
      final start = chunk.startLine;
      final end = chunk.endLine;
      if (start != null && end != null) return '$relativePath:$start-$end';
      if (start != null) return '$relativePath:$start';
      return relativePath;
    }
    final uri = source.uri?.trim();
    if (uri != null && uri.isNotEmpty) return uri;
    return '${source.title}#${chunk.chunkIndex}';
  }
}

class GroundedLearningContextRejection {
  final GroundedLearningContextRejectionCode code;
  final String? sourceChunkId;
  final String detail;

  const GroundedLearningContextRejection({
    required this.code,
    this.sourceChunkId,
    required this.detail,
  });
}

class GroundedLearningContext {
  final String targetId;
  final KnowledgePoint? knowledgePoint;
  final GroundedLearningSurface surface;
  final List<GroundedLearningContextItem> items;
  final List<GroundedLearningContextRejection> rejections;

  const GroundedLearningContext({
    required this.targetId,
    this.knowledgePoint,
    required this.surface,
    required this.items,
    this.rejections = const [],
  });

  String get contextId {
    final chunkPart = items.map((item) => item.chunk.id).join(',');
    return 'context:${surface.value}:$targetId:$chunkPart';
  }

  bool get hasBlockingRejection => rejections.any(
        (rejection) =>
            rejection.code ==
                GroundedLearningContextRejectionCode.missingTarget ||
            rejection.code ==
                GroundedLearningContextRejectionCode.missingRequiredCitation,
      );

  bool get isExecutable =>
      targetId.trim().isNotEmpty && items.isNotEmpty && !hasBlockingRejection;

  bool isExecutableFor(GroundedLearningSurface expectedSurface) {
    return isExecutable && surface == expectedSurface;
  }

  List<SourceChunk> get chunks =>
      items.map((item) => item.chunk).toList(growable: false);

  List<Source> get sources => {
        for (final item in items) item.source.id: item.source
      }.values.toList(growable: false);

  List<String> get chunkIds =>
      items.map((item) => item.chunk.id).toList(growable: false);

  Set<String> get chunkIdSet => chunkIds.toSet();

  GroundedLearningContextItem? itemForChunkId(String chunkId) {
    for (final item in items) {
      if (item.chunk.id == chunkId) return item;
    }
    return null;
  }

  List<String> get diagnosticLines {
    return [
      'Grounded context ID: $contextId',
      '执行 surface: ${surface.value} / ${surface.label}',
      '目标 ID: ${targetId.isEmpty ? '无' : targetId}',
      '可执行: ${isExecutable ? '是' : '否'}',
      '合法 context ids: ${chunkIds.isEmpty ? '无' : chunkIds.join('、')}',
      for (final item in items)
        '${item.chunk.id}: trust=${item.trustLevel.value} · locator=${item.locator} · selection_reason=${item.selectionReasons.map((reason) => reason.value).join(',')}',
      for (final rejection in rejections)
        '拒绝 ${rejection.sourceChunkId ?? 'context'}: ${rejection.code.value} / ${rejection.code.label} · ${rejection.detail}',
    ];
  }
}

String _normalizeQuote(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}
