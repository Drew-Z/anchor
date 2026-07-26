import '../../data/models/grounded_claim.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/source_chunk.dart';

/// 引用验证门控 - 确保 AI 生成内容的每个断言都有原文支撑
///
/// **核心理念**:
/// AI 生成的内容(题目、解释、编程题)常包含"隐性断言"(implicit claims):
/// - "Flutter 使用 Dart 语言" ← 这是一个断言
/// - "StatefulWidget 有 build 方法" ← 这也是一个断言
///
/// 这些断言必须**可溯源** - 即能在原文中找到明确的引用依据。
/// 否则就是 AI 的"幻觉"(hallucination),不应该展示给用户。
///
/// **工作流程**:
/// 1. AI 在生成内容时,主动标注每个断言的引用(citation_id + quote)
/// 2. GroundedClaimGate 验证每个引用是否真实存在于原文中
/// 3. 如果所有断言都有效,内容通过;否则拒绝或标记为待人工复核
///
/// **判定规则**:
/// - **ACCEPT**: 所有断言都有有效引用
/// - **REJECT**: 存在无效引用,且证据不足
/// - **FLAG**: 存在无效引用,但已提供足够证据供人工复核
///
/// **使用示例**:
/// ```dart
/// final gate = GroundedClaimGate();
///
/// final result = gate.evaluate(
///   claims: aiGeneratedClaims,
///   sourceChunks: relatedChunks,
///   evidenceSufficient: true,
/// );
///
/// if (result.disposition == GroundingDisposition.accept) {
///   // 内容可信,直接使用
/// } else {
///   // 存在问题,需人工复核
///   print('无效引用: ${result.uncoveredClaims.length}个');
/// }
/// ```
///
/// **参考**: docs-to-book 的 citation-grounding 机制
/// 引用验证结果
///
/// **字段说明**:
/// - [disposition]: 判定结果 (ACCEPT/REJECT/FLAG)
/// - [groundedClaims]: 有有效引用的断言列表
/// - [uncoveredClaims]: 无有效引用的断言列表
/// - [invalidEvidenceCount]: 无效证据的数量
///
/// **派生属性**:
/// - [citationIds]: 所有有效引用的ID列表
/// - [citationCoverage]: 引用覆盖率 (0.0-1.0)
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

  /// 获取所有有效引用的ID列表(去重)
  List<String> get citationIds => groundedClaims
      .expand((claim) => claim.citationIds)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  /// 计算引用覆盖率 (有效断言数 / 总断言数)
  ///
  /// 返回值范围: 0.0 - 1.0
  /// - 1.0: 所有断言都有有效引用
  /// - 0.5: 一半断言有引用
  /// - 0.0: 没有任何有效引用
  double get citationCoverage {
    final total = groundedClaims.length + uncoveredClaims.length;
    return total == 0 ? 0 : groundedClaims.length / total;
  }

  /// 获取指定章节的所有有效断言
  ///
  /// **用途**: 在生成题目时,按章节筛选相关的断言
  List<GroundedClaim> claimsForSection(String section) {
    return groundedClaims.where((claim) => claim.section == section).toList();
  }
}

class GroundedClaimGate {
  const GroundedClaimGate();

  /// 验证断言列表的引用有效性(基于 SourceChunk)
  ///
  /// **参数**:
  /// - [claims]: AI 生成的断言列表(每个断言包含引用)
  /// - [sourceChunks]: 原文片段列表(用于验证引用)
  /// - [evidenceSufficient]: 证据是否充分(影响判定结果)
  ///
  /// **返回**: GroundedClaimGateResult 包含:
  /// - 有效/无效断言列表
  /// - 判定结果(ACCEPT/REJECT/FLAG)
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

  /// 验证断言列表的引用有效性(基于 GroundedLearningContext)
  ///
  /// **与 evaluate() 的区别**:
  /// - evaluate(): 直接在 SourceChunk 的完整内容中查找引用
  /// - evaluateContext(): 在 GroundedLearningContext 的 quoteBoundary 中查找
  ///   (更严格,要求引用在预先标注的引用边界内)
  ///
  /// **适用场景**: 编程题等需要精确引用边界的场景
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
