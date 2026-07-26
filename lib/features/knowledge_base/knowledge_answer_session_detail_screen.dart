import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';
import 'knowledge_answer_citation_card.dart';
import 'knowledge_answer_evidence_quality_badges.dart';
import 'knowledge_answer_repair_action_button.dart';
import 'knowledge_answer_review_copy_button.dart';
import 'knowledge_library_error_state.dart';

final _knowledgeAnswerCitedChunksProvider =
    FutureProvider.family<List<_CitedSourceChunk>, String>(
  (ref, citationKey) async {
    final ids = citationKey
        .split('\n')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return const [];

    final chunkRepository = ref.read(sourceChunkRepositoryProvider);
    final sourceRepository = ref.read(sourceRepositoryProvider);
    final chunks = <_CitedSourceChunk>[];
    for (final id in ids) {
      final chunk = await chunkRepository.getSourceChunk(id);
      if (chunk == null) continue;
      final source = await sourceRepository.getSource(chunk.sourceId);
      chunks.add(_CitedSourceChunk(chunk: chunk, source: source));
    }
    return chunks;
  },
);

class _CitedSourceChunk {
  final SourceChunk chunk;
  final Source? source;

  const _CitedSourceChunk({
    required this.chunk,
    required this.source,
  });
}

class KnowledgeAnswerSessionDetailScreen extends ConsumerWidget {
  final LearningSession session;
  final KnowledgeAnswerSourceChunkOpener? onOpenSourceChunk;

  const KnowledgeAnswerSessionDetailScreen({
    super.key,
    required this.session,
    this.onOpenSourceChunk,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
    final question = summary.question ?? '知识库问答';
    final completedText = _dateText(session.endedAt ?? session.startedAt);
    final citationKey = summary.citationIds.join('\n');
    final citationIdText =
        summary.citationIds.isEmpty ? '无' : summary.citationIds.join(', ');
    final chunksAsync = citationKey.isEmpty
        ? null
        : ref.watch(_knowledgeAnswerCitedChunksProvider(citationKey));
    final citationContextLines = chunksAsync?.maybeWhen(
          data: _reviewCitationContextLines,
          orElse: () => const <String>[],
        ) ??
        const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _DetailTopBar(
              canSearchAgain: summary.question != null,
              onSearchAgain: summary.question == null
                  ? null
                  : () => Navigator.of(context).pop(summary.question),
              copyButton: KnowledgeAnswerReviewCopyButton(
                record: summary,
                completedText: completedText,
                recordStatusText: knowledgeAnswerSavedRecordStatusText,
                citationContextLines: citationContextLines,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              question,
              style: const TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TracePill(
                  icon: Icons.check_circle,
                  text: '完成于 $completedText',
                  color: AppColors.green,
                ),
                for (final label in summary.traceLabels)
                  _TracePill(
                    icon: _traceIcon(label),
                    text: label,
                    color: _traceColor(label),
                  ),
              ],
            ),
            if (summary.hasRepairableQualityIssue) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: KnowledgeAnswerRepairActionButton(
                  record: summary,
                  onSelected: (query) => Navigator.of(context).pop(query),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _DetailSection(
              title: '证据质量',
              child: _EvidenceQualityDetail(record: summary),
            ),
            if (summary.answer != null) ...[
              const SizedBox(height: 18),
              _DetailSection(
                title: '回答',
                child: Text(
                  summary.answer!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            if (summary.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailSection(
                title: '要点',
                child: _BulletList(items: summary.keyPoints),
              ),
            ],
            if (summary.sourceGaps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailSection(
                title: '来源缺口',
                child: _SourceGapList(
                  items: summary.sourceGaps,
                  onSelected: (gap) => Navigator.of(context).pop(gap),
                ),
              ),
            ],
            if (summary.followUpQuestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailSection(
                title: '继续追问',
                child: _FollowUpList(
                  items: summary.followUpQuestions,
                  onSelected: (question) => Navigator.of(context).pop(
                    question,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _DetailSection(
              title: '引用依据',
              child: chunksAsync == null
                  ? const _EmptyDetailText(
                      text: '这条记录没有保存引用 id，可使用上方补证动作继续检索依据。',
                    )
                  : chunksAsync.when(
                      data: (chunks) {
                        if (chunks.isEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CitationCoverageNotice(
                                foundCount: 0,
                                totalCount: summary.citationIds.length,
                              ),
                              const SizedBox(height: 10),
                              _MissingCitationIdsNotice(
                                citationIds: summary.citationIds,
                              ),
                            ],
                          );
                        }
                        return _CitationChunkList(
                          citationIds: summary.citationIds,
                          chunks: chunks,
                          onOpenSourceChunk: onOpenSourceChunk,
                        );
                      },
                      loading: () => const LinearProgressIndicator(
                        color: AppColors.green,
                      ),
                      error: (error, _) => KnowledgeLibraryErrorState(
                        title: '引用依据读取失败',
                        retryLabel: '重试读取引用',
                        diagnosticTitle: '知识库问答详情引用依据读取失败',
                        diagnosticSuccessMessage: '已复制引用依据读取诊断',
                        diagnosticLines: [
                          '问题: $question',
                          '记录 ID: ${session.id}',
                          '完成时间: $completedText',
                          '引用数量: ${summary.citationIds.length}',
                          '引用 ID: $citationIdText',
                        ],
                        error: error,
                        onRetry: () => ref.invalidate(
                          _knowledgeAnswerCitedChunksProvider(citationKey),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceQualityDetail extends StatelessWidget {
  final KnowledgeAnswerSessionSummaryRecord record;

  const _EvidenceQualityDetail({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KnowledgeAnswerEvidenceQualityBadges(record: record),
        const SizedBox(height: 8),
        Text(
          knowledgeAnswerEvidenceQualityGuidance(record),
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  final bool canSearchAgain;
  final VoidCallback? onSearchAgain;
  final Widget copyButton;

  const _DetailTopBar({
    required this.canSearchAgain,
    required this.onSearchAgain,
    required this.copyButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const Expanded(
          child: Text(
            '知识库问答复盘',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        copyButton,
        TextButton.icon(
          onPressed: canSearchAgain ? onSearchAgain : null,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('重新检索'),
        ),
      ],
    );
  }
}

class _TracePill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TracePill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FollowUpList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;

  const _FollowUpList({
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onSelected(item),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.question_answer,
                        size: 17,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.search,
                        size: 16,
                        color: AppColors.blueDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SourceGapList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;

  const _SourceGapList({
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onSelected(item),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 17,
                        color: AppColors.goldDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.search,
                        size: 16,
                        color: AppColors.goldDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CitationChunkList extends StatelessWidget {
  final List<String> citationIds;
  final List<_CitedSourceChunk> chunks;
  final KnowledgeAnswerSourceChunkOpener? onOpenSourceChunk;

  const _CitationChunkList({
    required this.citationIds,
    required this.chunks,
    required this.onOpenSourceChunk,
  });

  @override
  Widget build(BuildContext context) {
    final foundIds = chunks.map((entry) => entry.chunk.id).toSet();
    final missingIds = citationIds
        .where((id) => !foundIds.contains(id))
        .toList(growable: false);
    final missingSourceChunkIds = chunks
        .where((entry) => entry.source == null)
        .map((entry) => entry.chunk.id)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CitationCoverageNotice(
          foundCount: chunks.length,
          totalCount: citationIds.length,
        ),
        const SizedBox(height: 10),
        if (chunks.isNotEmpty) ...[
          _CitationTrustSummary(chunks: chunks),
          const SizedBox(height: 10),
        ],
        if (missingIds.isNotEmpty) ...[
          _MissingCitationIdsNotice(citationIds: missingIds),
          const SizedBox(height: 10),
        ],
        if (missingSourceChunkIds.isNotEmpty) ...[
          _MissingCitationSourcesNotice(chunkIds: missingSourceChunkIds),
          const SizedBox(height: 10),
        ],
        for (final entry in chunks)
          KnowledgeAnswerCitationCard(
            source: entry.source,
            chunk: entry.chunk,
            onOpenSourceChunk: onOpenSourceChunk,
            onCopySourceId: entry.source == null
                ? () => _copyIds(context, [entry.chunk.sourceId])
                : null,
            onCopyChunkId: () => _copyIds(context, [entry.chunk.id]),
          ),
      ],
    );
  }
}

class _CitationTrustSummary extends StatelessWidget {
  final List<_CitedSourceChunk> chunks;

  const _CitationTrustSummary({required this.chunks});

  @override
  Widget build(BuildContext context) {
    final counts = <SourceTrustLevel?, int>{};
    for (final entry in chunks) {
      final key = entry.source?.trustLevel;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final orderedCounts = _orderedCitationTrustCounts(counts);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          '来源可信度',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
          ),
        ),
        for (final entry in orderedCounts)
          _CitationTrustPill(
            label: _trustSummaryLabel(entry.key),
            count: entry.value,
            color: _trustColor(entry.key),
            tooltip: _trustTooltip(entry.key, entry.value),
          ),
      ],
    );
  }
}

class _CitationTrustPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final String tooltip;

  const _CitationTrustPill({
    required this.label,
    required this.count,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

List<MapEntry<SourceTrustLevel?, int>> _orderedCitationTrustCounts(
  Map<SourceTrustLevel?, int> counts,
) {
  return [
    for (final trustLevel in _citationTrustOrder)
      if ((counts[trustLevel] ?? 0) > 0)
        MapEntry(trustLevel, counts[trustLevel]!),
    if ((counts[null] ?? 0) > 0) MapEntry(null, counts[null]!),
  ];
}

const _citationTrustOrder = [
  SourceTrustLevel.officialDoc,
  SourceTrustLevel.sourceCode,
  SourceTrustLevel.bookCourse,
  SourceTrustLevel.article,
  SourceTrustLevel.userNote,
  SourceTrustLevel.unknown,
];

String _trustTooltip(SourceTrustLevel? trustLevel, int count) {
  if (trustLevel == null) {
    return '有 $count 个引用片段存在，但找不到对应来源记录。';
  }
  if (trustLevel == SourceTrustLevel.unknown) {
    return '有 $count 个引用片段的来源记录存在，但可信度未标注。';
  }
  return '有 $count 个引用片段来自${trustLevel.label}来源。';
}

String _trustSummaryLabel(SourceTrustLevel? trustLevel) {
  if (trustLevel == null) return '未知来源';
  if (trustLevel == SourceTrustLevel.unknown) return '可信度未知';
  return trustLevel.label;
}

Color _trustColor(SourceTrustLevel? trustLevel) {
  if (trustLevel == SourceTrustLevel.officialDoc) return AppColors.greenDark;
  if (trustLevel == SourceTrustLevel.sourceCode) return AppColors.blueDark;
  if (trustLevel == SourceTrustLevel.bookCourse) return AppColors.purpleDark;
  if (trustLevel == SourceTrustLevel.article) return AppColors.goldDark;
  if (trustLevel == SourceTrustLevel.userNote) return AppColors.textSecondary;
  return AppColors.red;
}

List<String> _reviewCitationContextLines(List<_CitedSourceChunk> chunks) {
  final extraCount = chunks.length - 5;
  return [
    for (final entry in chunks.take(5))
      buildKnowledgeAnswerCitationContextLine(
        chunkId: entry.chunk.id,
        sourceText: _sourceSummaryText(entry),
        locatorText: knowledgeAnswerCitationLocatorText(
          chunkIndex: entry.chunk.chunkIndex,
          locator: entry.chunk.locator,
        ),
        content: entry.chunk.content,
      ),
    if (extraCount > 0) knowledgeAnswerCitationOverflowLine(extraCount),
  ];
}

String _sourceSummaryText(_CitedSourceChunk entry) {
  final source = entry.source;
  if (source == null) return '未知来源 source ${entry.chunk.sourceId}';
  return '${source.title} · ${source.trustLevel.label}';
}

class _MissingCitationSourcesNotice extends StatelessWidget {
  final List<String> chunkIds;

  const _MissingCitationSourcesNotice({required this.chunkIds});

  @override
  Widget build(BuildContext context) {
    final visibleIds = chunkIds.take(6).toList(growable: false);
    final idsText = visibleIds.join(', ');
    final extraCount = chunkIds.length - visibleIds.length;
    final suffix = extraCount > 0 ? '，另有 $extraCount 条' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber,
            size: 17,
            color: AppColors.goldDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '这些引用片段存在，但来源记录缺失：$idsText$suffix。',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: AppColors.goldDark,
              ),
            ),
          ),
          IconButton(
            tooltip: '复制 chunk id',
            onPressed: () => _copyIds(context, chunkIds),
            icon: const Icon(Icons.copy, size: 16),
            color: AppColors.goldDark,
          ),
        ],
      ),
    );
  }
}

class _CitationCoverageNotice extends StatelessWidget {
  final int foundCount;
  final int totalCount;

  const _CitationCoverageNotice({
    required this.foundCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = foundCount >= totalCount;
    final color = isComplete ? AppColors.greenDark : AppColors.goldDark;
    final icon = isComplete ? Icons.verified : Icons.warning_amber;
    final message = isComplete
        ? '已找到全部 $totalCount 条引用片段。'
        : '已找到 $foundCount/$totalCount 条引用片段。';
    final tooltip = isComplete
        ? '这条回答保存的引用 id 都能在本地解析到来源片段。'
        : '这条回答保存了 $totalCount 个引用 id，其中 $foundCount 个能在本地解析到来源片段。';

    return Tooltip(
      message: tooltip,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingCitationIdsNotice extends StatelessWidget {
  final List<String> citationIds;

  const _MissingCitationIdsNotice({required this.citationIds});

  @override
  Widget build(BuildContext context) {
    final visibleIds = citationIds.take(6).toList(growable: false);
    final idsText = visibleIds.join(', ');
    final extraCount = citationIds.length - visibleIds.length;
    final suffix = extraCount > 0 ? '，另有 $extraCount 条' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.redLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.link_off, size: 17, color: AppColors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '引用 id 已记录，但本地没有找到对应片段：$idsText$suffix。',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: AppColors.redDark,
              ),
            ),
          ),
          IconButton(
            tooltip: '复制引用 id',
            onPressed: () => _copyIds(context, citationIds),
            icon: const Icon(Icons.copy, size: 16),
            color: AppColors.red,
          ),
        ],
      ),
    );
  }
}

Future<void> _copyIds(BuildContext context, List<String> ids) async {
  await Clipboard.setData(ClipboardData(text: ids.join('\n')));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已复制 ${ids.length} 条 id')),
  );
}

class _EmptyDetailText extends StatelessWidget {
  final String text;

  const _EmptyDetailText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}

IconData _traceIcon(String label) {
  if (label.contains('证据合格')) return Icons.verified;
  if (label.contains('缺少引用')) return Icons.link_off;
  if (label.contains('引用')) return Icons.link;
  if (label.contains('缺口')) return Icons.warning_amber;
  return Icons.question_answer;
}

Color _traceColor(String label) {
  if (label.contains('证据合格')) return AppColors.greenDark;
  if (label.contains('缺少引用')) return AppColors.red;
  if (label.contains('引用')) return AppColors.blue;
  if (label.contains('缺口')) return AppColors.goldDark;
  return AppColors.purpleDark;
}

String _dateText(DateTime date) {
  return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
