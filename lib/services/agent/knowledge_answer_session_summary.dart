import '../../data/models/grounded_claim.dart';
import '../../data/models/learning_session.dart';

enum KnowledgeAnswerEvidenceRepairKind {
  sourceGap,
  missingCitation,
}

const knowledgeAnswerSavedRecordStatusText = '已保存到学习记录';
const knowledgeAnswerSavingRecordStatusText = '正在保存到学习记录';
const knowledgeAnswerUnconfirmedRecordStatusText = '尚未确认保存状态';

String knowledgeAnswerEvidenceRepairKindLabel(
  KnowledgeAnswerEvidenceRepairKind kind,
) {
  if (kind == KnowledgeAnswerEvidenceRepairKind.sourceGap) {
    return '检索缺口';
  }
  return '补齐引用';
}

String knowledgeAnswerEvidenceQualityGuidance(
  KnowledgeAnswerSessionSummaryRecord record,
) {
  if (record.hasCleanEvidence) {
    return '这条回答的主张、引用和来源缺口已经通过审计，适合优先作为复盘样本。';
  }
  if (record.groundingDisposition == GroundingDisposition.legacy) {
    return '这条历史回答没有主张级审计记录，不能直接视为证据合格，建议结合原始引用重新核查。';
  }
  if (record.hasRepairableQualityIssue) {
    return '这条回答还有证据质量债，可以先用补证动作继续检索依据。';
  }
  return '这条回答有证据质量债，但暂时没有直接补证动作，建议结合引用依据继续核查。';
}

List<String> knowledgeAnswerEvidenceQualityLabels(
  KnowledgeAnswerSessionSummaryRecord record,
) {
  if (record.hasCleanEvidence) return const ['证据合格'];
  return [
    if (record.groundingDisposition == GroundingDisposition.partial) '部分主张未支持',
    if (record.groundingDisposition == GroundingDisposition.refused) '证据不足已拒答',
    if (record.groundingDisposition == GroundingDisposition.legacy) '历史记录未审计',
    if (record.groundingDisposition == GroundingDisposition.grounded &&
        record.groundedClaims.isEmpty)
      '缺少主张审计',
    if (record.hasMissingCitations) '缺少引用',
    if (record.hasSourceGaps) '来源缺口',
    if (record.hasRepairableQualityIssue) '可补证',
    if (record.hasNonRepairableQualityIssue) '需核查',
  ];
}

class KnowledgeAnswerSessionSummaryRecord {
  final String? knowledgePointId;
  final String? groundedContextId;
  final String? question;
  final String? answer;
  final List<String> keyPoints;
  final List<String> sourceGaps;
  final List<String> followUpQuestions;
  final List<String> citationIds;
  final List<GroundedClaim> groundedClaims;
  final GroundingDisposition groundingDisposition;
  final List<String> lines;

  const KnowledgeAnswerSessionSummaryRecord({
    this.knowledgePointId,
    this.groundedContextId,
    required this.question,
    required this.answer,
    required this.keyPoints,
    required this.sourceGaps,
    required this.followUpQuestions,
    required this.citationIds,
    this.groundedClaims = const [],
    this.groundingDisposition = GroundingDisposition.legacy,
    required this.lines,
  });

  factory KnowledgeAnswerSessionSummaryRecord.fromSession(
    LearningSession session,
  ) {
    return KnowledgeAnswerSessionSummaryRecord.fromSummary(session.summary);
  }

  factory KnowledgeAnswerSessionSummaryRecord.fromFields({
    String? knowledgePointId,
    String? groundedContextId,
    String? question,
    String? answer,
    List<String> keyPoints = const [],
    List<String> sourceGaps = const [],
    List<String> followUpQuestions = const [],
    List<String> citationIds = const [],
    List<GroundedClaim> groundedClaims = const [],
    GroundingDisposition groundingDisposition = GroundingDisposition.legacy,
  }) {
    return KnowledgeAnswerSessionSummaryRecord(
      knowledgePointId: _emptyToNull(knowledgePointId),
      groundedContextId: _emptyToNull(groundedContextId),
      question: _emptyToNull(question),
      answer: _emptyToNull(answer),
      keyPoints: keyPoints,
      sourceGaps: sourceGaps,
      followUpQuestions: followUpQuestions,
      citationIds: citationIds,
      groundedClaims: groundedClaims,
      groundingDisposition: groundingDisposition,
      lines: const [],
    );
  }

  factory KnowledgeAnswerSessionSummaryRecord.fromSummary(String? summary) {
    final lines = _summaryLines(summary);
    return KnowledgeAnswerSessionSummaryRecord(
      knowledgePointId: _lineValue(lines, '知识点 ID:'),
      groundedContextId: _lineValue(lines, 'Grounded Context ID:'),
      question: _multiLineValue(
        lines,
        '知识库问答:',
        stopPrefixes: const [
          '知识点 ID:',
          'Grounded Context ID:',
          '回答:',
          '要点:',
          '来源缺口:',
          '继续追问:',
          '引用:',
          '证据门禁:',
          '主张JSON:',
        ],
      ),
      answer: _multiLineValue(
        lines,
        '回答:',
        stopPrefixes: const [
          '知识点 ID:',
          'Grounded Context ID:',
          '要点:',
          '来源缺口:',
          '继续追问:',
          '引用:',
          '证据门禁:',
          '主张JSON:',
        ],
      ),
      keyPoints: _splitSummaryList(_lineValue(lines, '要点:')),
      sourceGaps: _splitSummaryList(_lineValue(lines, '来源缺口:')),
      followUpQuestions: _splitSummaryList(_lineValue(lines, '继续追问:')),
      citationIds: _splitCitationIds(_lineValue(lines, '引用:')),
      groundedClaims: decodeGroundedClaims(_lineValue(lines, '主张JSON:')),
      groundingDisposition: GroundingDisposition.fromString(
        _lineValue(lines, '证据门禁:'),
      ),
      lines: lines,
    );
  }

  bool get hasMissingCitations => citationIds.isEmpty;

  bool get hasSourceGaps => sourceGaps.isNotEmpty;

  bool get hasVerifiedGrounding {
    return groundingDisposition == GroundingDisposition.grounded &&
        groundedClaims.isNotEmpty;
  }

  bool get hasQualityIssue {
    return hasMissingCitations || hasSourceGaps || !hasVerifiedGrounding;
  }

  bool get hasCleanEvidence => !hasQualityIssue;

  bool get hasRepairableQualityIssue => evidenceRepairQuery != null;

  bool get hasNonRepairableQualityIssue {
    return hasQualityIssue && !hasRepairableQualityIssue;
  }

  KnowledgeAnswerEvidenceRepairKind? get evidenceRepairKind {
    if (hasSourceGaps) {
      return KnowledgeAnswerEvidenceRepairKind.sourceGap;
    }
    final trimmedQuestion = question?.trim();
    if (hasMissingCitations &&
        trimmedQuestion != null &&
        trimmedQuestion.isNotEmpty) {
      return KnowledgeAnswerEvidenceRepairKind.missingCitation;
    }
    return null;
  }

  String? get evidenceRepairQuery {
    final kind = evidenceRepairKind;
    if (kind == KnowledgeAnswerEvidenceRepairKind.sourceGap) {
      return sourceGaps.first;
    }
    if (kind == KnowledgeAnswerEvidenceRepairKind.missingCitation) {
      return question!.trim();
    }
    return null;
  }

  List<String> get traceLabels {
    final labels = <String>[
      if (hasCleanEvidence) '证据合格',
      '主张门禁：${groundingDisposition.label}',
      if (groundedClaims.isNotEmpty) '${groundedClaims.length} 条已核验主张',
      if (hasMissingCitations) '缺少引用' else '${citationIds.length} 条引用',
      if (hasSourceGaps) '${sourceGaps.length} 个来源缺口',
      if (followUpQuestions.isNotEmpty) '${followUpQuestions.length} 条追问',
    ];
    return labels;
  }
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

class KnowledgeAnswerSessionStats {
  final int totalCount;
  final int cleanCount;
  final int qualityIssueCount;
  final int missingCitationCount;
  final int sourceGapCount;
  final int repairableCount;
  final int nonRepairableQualityIssueCount;

  const KnowledgeAnswerSessionStats({
    required this.totalCount,
    required this.cleanCount,
    required this.qualityIssueCount,
    required this.missingCitationCount,
    required this.sourceGapCount,
    required this.repairableCount,
    required this.nonRepairableQualityIssueCount,
  });

  factory KnowledgeAnswerSessionStats.fromSessions(
    List<LearningSession> sessions,
  ) {
    var cleanCount = 0;
    var qualityIssueCount = 0;
    var missingCitationCount = 0;
    var sourceGapCount = 0;
    var repairableCount = 0;
    var nonRepairableQualityIssueCount = 0;
    for (final session in sessions) {
      final record = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
      final hasMissingCitations = record.hasMissingCitations;
      final hasSourceGaps = record.hasSourceGaps;
      final hasQualityIssue = record.hasQualityIssue;
      final isRepairable = record.hasRepairableQualityIssue;
      final needsReview = record.hasNonRepairableQualityIssue;
      if (hasMissingCitations) missingCitationCount += 1;
      if (hasSourceGaps) sourceGapCount += 1;
      if (hasQualityIssue) {
        qualityIssueCount += 1;
      } else {
        cleanCount += 1;
      }
      if (isRepairable) repairableCount += 1;
      if (needsReview) {
        nonRepairableQualityIssueCount += 1;
      }
    }
    return KnowledgeAnswerSessionStats(
      totalCount: sessions.length,
      cleanCount: cleanCount,
      qualityIssueCount: qualityIssueCount,
      missingCitationCount: missingCitationCount,
      sourceGapCount: sourceGapCount,
      repairableCount: repairableCount,
      nonRepairableQualityIssueCount: nonRepairableQualityIssueCount,
    );
  }

  bool get hasQualityIssues {
    return qualityIssueCount > 0;
  }

  bool get hasRepairableIssues {
    return repairableCount > 0;
  }

  bool get hasNonRepairableQualityIssues {
    return nonRepairableQualityIssueCount > 0;
  }
}

String buildKnowledgeAnswerSessionSummary({
  String? knowledgePointId,
  String? groundedContextId,
  required String question,
  required String answer,
  List<String> keyPoints = const [],
  List<String> sourceGaps = const [],
  List<String> followUpQuestions = const [],
  List<String> citationIds = const [],
  List<GroundedClaim> groundedClaims = const [],
  GroundingDisposition groundingDisposition = GroundingDisposition.legacy,
}) {
  final trimmedQuestion = question.trim();
  final trimmedAnswer = answer.trim();
  final trimmedKnowledgePointId = knowledgePointId?.trim();
  final trimmedGroundedContextId = groundedContextId?.trim();
  final lines = [
    '知识库问答: $trimmedQuestion',
    if (trimmedKnowledgePointId != null && trimmedKnowledgePointId.isNotEmpty)
      '知识点 ID: $trimmedKnowledgePointId',
    if (trimmedGroundedContextId != null && trimmedGroundedContextId.isNotEmpty)
      'Grounded Context ID: $trimmedGroundedContextId',
    if (trimmedAnswer.isNotEmpty) '回答: $trimmedAnswer',
    if (keyPoints.isNotEmpty) '要点: ${keyPoints.join('；')}',
    if (sourceGaps.isNotEmpty) '来源缺口: ${sourceGaps.join('；')}',
    if (followUpQuestions.isNotEmpty) '继续追问: ${followUpQuestions.join('；')}',
    if (citationIds.isNotEmpty) '引用: ${citationIds.join(', ')}',
    '证据门禁: ${groundingDisposition.value}',
    if (groundedClaims.isNotEmpty)
      '主张JSON: ${encodeGroundedClaims(groundedClaims)}',
  ];
  return lines.join('\n');
}

String buildKnowledgeAnswerReviewText(
  KnowledgeAnswerSessionSummaryRecord record, {
  String? completedText,
  String? recordStatusText,
  List<String> citationContextLines = const [],
}) {
  final repairKind = record.evidenceRepairKind;
  final repairQuery = record.evidenceRepairQuery;
  final trimmedCompletedText = completedText?.trim();
  final trimmedRecordStatusText = recordStatusText?.trim();
  final completedLabel =
      trimmedCompletedText == null || trimmedCompletedText.isEmpty
          ? '未记录完成时间'
          : trimmedCompletedText;
  final questionLabel = record.question ?? '未记录问题';
  final lines = <String>[
    '# 知识库问答复盘',
    '完成时间: $completedLabel',
    '问题: $questionLabel',
    if (trimmedRecordStatusText != null && trimmedRecordStatusText.isNotEmpty)
      '记录状态: $trimmedRecordStatusText',
    '证据质量: ${knowledgeAnswerEvidenceQualityLabels(record).join('、')}',
    '追溯标签: ${record.traceLabels.join('、')}',
    '证据建议: ${knowledgeAnswerEvidenceQualityGuidance(record)}',
    if (repairKind != null && repairQuery != null) ...[
      '补证动作: ${knowledgeAnswerEvidenceRepairKindLabel(repairKind)}',
      '补证查询: $repairQuery',
    ],
    '',
    '## 回答',
    record.answer ?? '未记录回答',
    '',
    '## 要点',
    if (record.keyPoints.isEmpty)
      '- 未记录要点'
    else
      ..._markdownList(record.keyPoints),
    '',
    '## 来源缺口',
    if (record.sourceGaps.isEmpty)
      '- 未记录来源缺口'
    else
      ..._markdownList(record.sourceGaps),
    '',
    '## 继续追问',
    if (record.followUpQuestions.isEmpty)
      '- 未记录继续追问'
    else
      ..._markdownList(record.followUpQuestions),
    '',
    '## 引用片段 id',
    if (record.citationIds.isEmpty)
      '- 未保存引用 id'
    else
      ..._markdownList(record.citationIds),
    '',
    '## 已核验主张',
    if (record.groundedClaims.isEmpty)
      '- 未保存主张级审计'
    else
      ..._markdownList(
        record.groundedClaims.map((claim) => claim.text).toList(),
      ),
    if (citationContextLines.isNotEmpty) ...[
      '',
      '## 引用片段摘要',
      ..._markdownList(citationContextLines),
    ],
  ];
  return lines.join('\n');
}

List<String> _markdownList(List<String> items) {
  return [
    for (final item in items)
      if (item.trim().isNotEmpty) '- ${item.trim()}',
  ];
}

String buildKnowledgeAnswerCitationContextLine({
  required String chunkId,
  required String locatorText,
  required String content,
  String? sourceText,
}) {
  final trimmedSourceText = sourceText?.trim();
  final sourcePart = trimmedSourceText == null || trimmedSourceText.isEmpty
      ? ''
      : ' · $trimmedSourceText';
  return '$chunkId$sourcePart · $locatorText: '
      '${_compactKnowledgeAnswerCitationSnippet(content)}';
}

String knowledgeAnswerCitationLocatorText({
  required int chunkIndex,
  String? locator,
}) {
  final trimmedLocator = locator?.trim();
  if (trimmedLocator == null || trimmedLocator.isEmpty) {
    return '片段 ${chunkIndex + 1}';
  }
  return trimmedLocator;
}

String knowledgeAnswerCitationOverflowLine(int extraCount) {
  return '另有 $extraCount 条引用片段未列出';
}

String _compactKnowledgeAnswerCitationSnippet(String content) {
  final snippet = content.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (snippet.isEmpty) return '内容为空';
  if (snippet.length <= 140) return snippet;
  return '${snippet.substring(0, 140)}...';
}

String? knowledgeAnswerQuestionFromSummary(String? summary) {
  return KnowledgeAnswerSessionSummaryRecord.fromSummary(summary).question;
}

String? knowledgeAnswerAnswerFromSummary(String? summary) {
  return KnowledgeAnswerSessionSummaryRecord.fromSummary(summary).answer;
}

List<String> knowledgeAnswerKeyPointsFromSummary(String? summary) {
  return KnowledgeAnswerSessionSummaryRecord.fromSummary(summary).keyPoints;
}

List<String> knowledgeAnswerSourceGapsFromSummary(String? summary) {
  return KnowledgeAnswerSessionSummaryRecord.fromSummary(summary).sourceGaps;
}

List<String> knowledgeAnswerFollowUpsFromSummary(String? summary) {
  final record = KnowledgeAnswerSessionSummaryRecord.fromSummary(summary);
  return record.followUpQuestions;
}

List<String> knowledgeAnswerCitationIdsFromSummary(String? summary) {
  return KnowledgeAnswerSessionSummaryRecord.fromSummary(summary).citationIds;
}

List<String> _summaryLines(String? summary) {
  if (summary == null || summary.isEmpty) return const [];
  return summary
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String? _lineValue(List<String> lines, String prefix) {
  for (final line in lines) {
    if (!line.startsWith(prefix)) continue;
    final content = line.substring(prefix.length).trim();
    if (content.isNotEmpty) return content;
  }
  return null;
}

String? _multiLineValue(
  List<String> lines,
  String prefix, {
  List<String> stopPrefixes = const [],
}) {
  final start = lines.indexWhere((line) => line.startsWith(prefix));
  if (start == -1) return null;

  final values = <String>[lines[start].substring(prefix.length).trim()];
  for (final line in lines.skip(start + 1)) {
    if (stopPrefixes.any((prefix) => line.startsWith(prefix))) break;
    values.add(line);
  }
  final text = values.where((line) => line.isNotEmpty).join('\n');
  if (text.isNotEmpty) return text;
  return null;
}

List<String> _splitSummaryList(String? value) {
  if (value == null || value.isEmpty) return const [];
  return value
      .split(RegExp(r'[；;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _splitCitationIds(String? value) {
  if (value == null || value.isEmpty) return const [];
  return value
      .split(RegExp(r'[,，；;\s]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
