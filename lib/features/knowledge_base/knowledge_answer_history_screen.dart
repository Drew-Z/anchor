import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/learning_session.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';
import 'knowledge_answer_citation_card.dart';
import 'knowledge_answer_evidence_quality_badges.dart';
import 'knowledge_answer_repair_action_button.dart';
import 'knowledge_answer_review_copy_button.dart';
import 'knowledge_answer_session_detail_screen.dart';
import 'knowledge_library_error_state.dart';

class KnowledgeAnswerHistoryScreen extends ConsumerStatefulWidget {
  final KnowledgeAnswerSourceChunkOpener? onOpenSourceChunk;
  final String? initialSearchQuery;
  final bool initialOnlyCleanEvidence;
  final bool initialOnlyQualityIssues;
  final bool initialOnlyWithSourceGaps;
  final bool initialOnlyWithoutCitations;
  final bool initialOnlyRepairable;
  final bool initialOnlyNeedsReview;

  const KnowledgeAnswerHistoryScreen({
    super.key,
    this.onOpenSourceChunk,
    this.initialSearchQuery,
    this.initialOnlyCleanEvidence = false,
    this.initialOnlyQualityIssues = false,
    this.initialOnlyWithSourceGaps = false,
    this.initialOnlyWithoutCitations = false,
    this.initialOnlyRepairable = false,
    this.initialOnlyNeedsReview = false,
  });

  @override
  ConsumerState<KnowledgeAnswerHistoryScreen> createState() =>
      _KnowledgeAnswerHistoryScreenState();
}

class _KnowledgeAnswerHistoryScreenState
    extends ConsumerState<KnowledgeAnswerHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _onlyCleanEvidence = false;
  bool _onlyQualityIssues = false;
  bool _onlyWithSourceGaps = false;
  bool _onlyWithoutCitations = false;
  bool _onlyRepairable = false;
  bool _onlyNeedsReview = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _query = initialQuery;
      _searchController.text = initialQuery;
    }
    _onlyCleanEvidence = widget.initialOnlyCleanEvidence;
    _onlyQualityIssues = widget.initialOnlyQualityIssues;
    _onlyWithSourceGaps = widget.initialOnlyWithSourceGaps;
    _onlyWithoutCitations = widget.initialOnlyWithoutCitations;
    _onlyRepairable = widget.initialOnlyRepairable;
    _onlyNeedsReview = widget.initialOnlyNeedsReview;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(knowledgeAnswerSessionListProvider);
    final activeFilters = _activeFilters;

    return Scaffold(
      appBar: AppBar(
        title: _HistoryAppBarTitle(activeFilters: activeFilters),
      ),
      body: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) return const _EmptyHistoryState();
            final stats = KnowledgeAnswerSessionStats.fromSessions(sessions);
            final filteredSessions = _filteredSessions(sessions);
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount:
                  filteredSessions.isEmpty ? 2 : filteredSessions.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _HistorySearchPanel(
                    controller: _searchController,
                    stats: stats,
                    filteredCount: filteredSessions.length,
                    activeFilters: activeFilters,
                    onlyCleanEvidence: _onlyCleanEvidence,
                    onlyQualityIssues: _onlyQualityIssues,
                    onlyWithSourceGaps: _onlyWithSourceGaps,
                    onlyWithoutCitations: _onlyWithoutCitations,
                    onlyRepairable: _onlyRepairable,
                    onlyNeedsReview: _onlyNeedsReview,
                    hasActiveFilters: _hasActiveFilters,
                    onChanged: (value) {
                      setState(() => _query = value.trim());
                    },
                    onOnlyCleanEvidenceChanged: (value) {
                      setState(() => _onlyCleanEvidence = value);
                    },
                    onOnlyQualityIssuesChanged: (value) {
                      setState(() => _onlyQualityIssues = value);
                    },
                    onOnlyWithSourceGapsChanged: (value) {
                      setState(() => _onlyWithSourceGaps = value);
                    },
                    onOnlyWithoutCitationsChanged: (value) {
                      setState(() => _onlyWithoutCitations = value);
                    },
                    onOnlyRepairableChanged: (value) {
                      setState(() => _onlyRepairable = value);
                    },
                    onOnlyNeedsReviewChanged: (value) {
                      setState(() => _onlyNeedsReview = value);
                    },
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                    onClearFilters: _clearFilters,
                  );
                }
                if (filteredSessions.isEmpty) {
                  return _EmptyFilteredState(
                    activeFilters: activeFilters,
                    onClearFilters: _clearFilters,
                  );
                }
                final session = filteredSessions[index - 1];
                return _KnowledgeAnswerHistoryListCard(
                  session: session,
                  onTap: () => _openDetail(session),
                  onSearchQuerySelected: _returnSearchQuery,
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
          error: (error, _) => KnowledgeLibraryErrorState(
            title: '问答历史读取失败',
            retryLabel: '重试读取历史',
            diagnosticTitle: '知识库问答历史读取失败',
            diagnosticSuccessMessage: '已复制问答历史读取诊断',
            diagnosticLines: [
              '当前筛选: ${activeFilters.isEmpty ? '无' : activeFilters.map((filter) => filter.label).join(', ')}',
            ],
            error: error,
            onRetry: () => ref.invalidate(knowledgeAnswerSessionListProvider),
          ),
        ),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _query.isNotEmpty ||
        _onlyCleanEvidence ||
        _onlyQualityIssues ||
        _onlyWithSourceGaps ||
        _onlyWithoutCitations ||
        _onlyRepairable ||
        _onlyNeedsReview;
  }

  List<_ActiveFilterInfo> get _activeFilters {
    return [
      if (_query.isNotEmpty)
        _ActiveFilterInfo(
          label: '搜索 "$_query"',
          color: AppColors.greenDark,
          kind: _ActiveFilterKind.search,
        ),
      if (_onlyCleanEvidence)
        const _ActiveFilterInfo(
          label: '证据合格',
          color: AppColors.greenDark,
          kind: _ActiveFilterKind.cleanEvidence,
        ),
      if (_onlyQualityIssues)
        const _ActiveFilterInfo(
          label: '质量债',
          color: AppColors.goldDark,
          kind: _ActiveFilterKind.qualityIssue,
        ),
      if (_onlyWithoutCitations)
        const _ActiveFilterInfo(
          label: '缺少引用',
          color: AppColors.red,
          kind: _ActiveFilterKind.missingCitation,
        ),
      if (_onlyWithSourceGaps)
        const _ActiveFilterInfo(
          label: '有来源缺口',
          color: AppColors.goldDark,
          kind: _ActiveFilterKind.sourceGap,
        ),
      if (_onlyRepairable)
        const _ActiveFilterInfo(
          label: '可补证',
          color: AppColors.goldDark,
          kind: _ActiveFilterKind.repairable,
        ),
      if (_onlyNeedsReview)
        const _ActiveFilterInfo(
          label: '需核查',
          color: AppColors.purpleDark,
          kind: _ActiveFilterKind.needsReview,
        ),
    ];
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _onlyCleanEvidence = false;
      _onlyQualityIssues = false;
      _onlyWithSourceGaps = false;
      _onlyWithoutCitations = false;
      _onlyRepairable = false;
      _onlyNeedsReview = false;
      _searchController.clear();
    });
  }

  List<LearningSession> _filteredSessions(List<LearningSession> sessions) {
    final query = _query.toLowerCase();
    return sessions.where((session) {
      final record = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
      if (_onlyCleanEvidence && !record.hasCleanEvidence) return false;
      if (_onlyQualityIssues && !record.hasQualityIssue) return false;
      if (_onlyWithSourceGaps && !record.hasSourceGaps) return false;
      if (_onlyWithoutCitations && record.citationIds.isNotEmpty) return false;
      if (_onlyRepairable && !record.hasRepairableQualityIssue) return false;
      if (_onlyNeedsReview && !record.hasNonRepairableQualityIssue)
        return false;
      if (query.isEmpty) return true;
      final repairKind = record.evidenceRepairKind;
      final text = [
        record.question,
        record.answer,
        ...record.keyPoints,
        ...record.sourceGaps,
        ...record.followUpQuestions,
        ...record.citationIds,
        ...record.traceLabels,
        ...knowledgeAnswerEvidenceQualityLabels(record),
        if (record.hasQualityIssue) '质量债',
        if (repairKind != null)
          knowledgeAnswerEvidenceRepairKindLabel(repairKind),
      ].whereType<String>().join('\n').toLowerCase();
      return text.contains(query);
    }).toList(growable: false);
  }

  Future<void> _openDetail(LearningSession session) async {
    final question = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => KnowledgeAnswerSessionDetailScreen(
          session: session,
          onOpenSourceChunk: widget.onOpenSourceChunk,
        ),
      ),
    );
    if (!mounted || question == null || question.trim().isEmpty) return;
    Navigator.of(context).pop(question);
  }

  void _returnSearchQuery(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    Navigator.of(context).pop(trimmedQuery);
  }
}

class _HistoryAppBarTitle extends StatelessWidget {
  final List<_ActiveFilterInfo> activeFilters;

  const _HistoryAppBarTitle({required this.activeFilters});

  @override
  Widget build(BuildContext context) {
    final subtitle = activeFilters.map((filter) => filter.label).join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('知识库问答历史'),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _HistorySearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final KnowledgeAnswerSessionStats stats;
  final int filteredCount;
  final List<_ActiveFilterInfo> activeFilters;
  final bool onlyCleanEvidence;
  final bool onlyQualityIssues;
  final bool onlyWithSourceGaps;
  final bool onlyWithoutCitations;
  final bool onlyRepairable;
  final bool onlyNeedsReview;
  final bool hasActiveFilters;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onOnlyCleanEvidenceChanged;
  final ValueChanged<bool> onOnlyQualityIssuesChanged;
  final ValueChanged<bool> onOnlyWithSourceGapsChanged;
  final ValueChanged<bool> onOnlyWithoutCitationsChanged;
  final ValueChanged<bool> onOnlyRepairableChanged;
  final ValueChanged<bool> onOnlyNeedsReviewChanged;
  final VoidCallback? onClear;
  final VoidCallback onClearFilters;

  const _HistorySearchPanel({
    required this.controller,
    required this.stats,
    required this.filteredCount,
    required this.activeFilters,
    required this.onlyCleanEvidence,
    required this.onlyQualityIssues,
    required this.onlyWithSourceGaps,
    required this.onlyWithoutCitations,
    required this.onlyRepairable,
    required this.onlyNeedsReview,
    required this.hasActiveFilters,
    required this.onChanged,
    required this.onOnlyCleanEvidenceChanged,
    required this.onOnlyQualityIssuesChanged,
    required this.onOnlyWithSourceGapsChanged,
    required this.onOnlyWithoutCitationsChanged,
    required this.onOnlyRepairableChanged,
    required this.onOnlyNeedsReviewChanged,
    required this.onClear,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '搜索问题、回答、缺口、引用或标签',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: onClear == null
                ? null
                : IconButton(
                    tooltip: '清空',
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.green, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _HistoryStatPill(
              icon: Icons.history,
              label: '共 ${stats.totalCount} 条',
              color: AppColors.blue,
              tooltip: hasActiveFilters ? '清除筛选，查看全部记录' : '全部知识库问答记录',
              onTap: hasActiveFilters ? onClearFilters : null,
            ),
            _HistoryStatPill(
              icon: Icons.verified,
              label: '证据合格 ${stats.cleanCount}',
              color: AppColors.green,
              tooltip: '有引用且没有来源缺口的问答',
              selected: onlyCleanEvidence,
              onTap: () => onOnlyCleanEvidenceChanged(!onlyCleanEvidence),
            ),
            _HistoryStatPill(
              icon: Icons.rule,
              label: '质量债 ${stats.qualityIssueCount}',
              color:
                  stats.hasQualityIssues ? AppColors.goldDark : AppColors.green,
              tooltip: '缺少引用或存在来源缺口的问答',
              selected: onlyQualityIssues,
              onTap: () => onOnlyQualityIssuesChanged(!onlyQualityIssues),
            ),
            _HistoryStatPill(
              icon: Icons.link_off,
              label: '缺少引用 ${stats.missingCitationCount}',
              color: stats.missingCitationCount == 0
                  ? AppColors.green
                  : AppColors.red,
              tooltip: '没有保存引用 id 的问答',
              selected: onlyWithoutCitations,
              onTap: () => onOnlyWithoutCitationsChanged(
                !onlyWithoutCitations,
              ),
            ),
            _HistoryStatPill(
              icon: Icons.warning_amber,
              label: '来源缺口 ${stats.sourceGapCount}',
              color: stats.sourceGapCount == 0
                  ? AppColors.green
                  : AppColors.goldDark,
              tooltip: '记录了仍需补充依据问题的问答',
              selected: onlyWithSourceGaps,
              onTap: () => onOnlyWithSourceGapsChanged(!onlyWithSourceGaps),
            ),
            _HistoryStatPill(
              icon: Icons.build,
              label: '可补证 ${stats.repairableCount}',
              color: stats.repairableCount == 0
                  ? AppColors.green
                  : AppColors.goldDark,
              tooltip: '可以直接继续检索依据的问答',
              selected: onlyRepairable,
              onTap: () => onOnlyRepairableChanged(!onlyRepairable),
            ),
            _HistoryStatPill(
              icon: Icons.rule,
              label: '需核查 ${stats.nonRepairableQualityIssueCount}',
              color: stats.nonRepairableQualityIssueCount == 0
                  ? AppColors.green
                  : AppColors.purpleDark,
              tooltip: '有质量债但暂时没有直接补证动作的问答',
              selected: onlyNeedsReview,
              onTap: () => onOnlyNeedsReviewChanged(!onlyNeedsReview),
            ),
            _HistoryStatPill(
              icon: Icons.filter_list,
              label: '显示 $filteredCount',
              color: AppColors.textSecondary,
              tooltip: '当前筛选下显示的记录数',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: onlyCleanEvidence,
              onSelected: onOnlyCleanEvidenceChanged,
              label: const Text('证据合格'),
              avatar: const Icon(Icons.verified, size: 16),
              selectedColor: AppColors.greenLight,
              checkmarkColor: AppColors.greenDark,
            ),
            FilterChip(
              selected: onlyQualityIssues,
              onSelected: onOnlyQualityIssuesChanged,
              label: const Text('质量债'),
              avatar: const Icon(Icons.rule, size: 16),
              selectedColor: AppColors.gold.withValues(alpha: 0.18),
              checkmarkColor: AppColors.goldDark,
            ),
            FilterChip(
              selected: onlyWithoutCitations,
              onSelected: onOnlyWithoutCitationsChanged,
              label: const Text('缺少引用'),
              avatar: const Icon(Icons.link_off, size: 16),
              selectedColor: AppColors.redLight,
              checkmarkColor: AppColors.redDark,
            ),
            FilterChip(
              selected: onlyWithSourceGaps,
              onSelected: onOnlyWithSourceGapsChanged,
              label: const Text('有来源缺口'),
              avatar: const Icon(Icons.warning_amber, size: 16),
              selectedColor: AppColors.gold.withValues(alpha: 0.18),
              checkmarkColor: AppColors.goldDark,
            ),
            FilterChip(
              selected: onlyRepairable,
              onSelected: onOnlyRepairableChanged,
              label: const Text('可补证'),
              avatar: const Icon(Icons.build, size: 16),
              selectedColor: AppColors.gold.withValues(alpha: 0.18),
              checkmarkColor: AppColors.goldDark,
            ),
            FilterChip(
              selected: onlyNeedsReview,
              onSelected: onOnlyNeedsReviewChanged,
              label: const Text('需核查'),
              avatar: const Icon(Icons.rule, size: 16),
              selectedColor: AppColors.purple.withValues(alpha: 0.16),
              checkmarkColor: AppColors.purpleDark,
            ),
            if (hasActiveFilters)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('清除筛选'),
              ),
          ],
        ),
        if (activeFilters.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ActiveFilterSummary(filters: activeFilters),
        ],
      ],
    );
  }
}

enum _ActiveFilterKind {
  search,
  cleanEvidence,
  qualityIssue,
  missingCitation,
  sourceGap,
  repairable,
  needsReview,
}

class _ActiveFilterInfo {
  final String label;
  final Color color;
  final _ActiveFilterKind kind;

  const _ActiveFilterInfo({
    required this.label,
    required this.color,
    required this.kind,
  });
}

class _ActiveFilterSummary extends StatelessWidget {
  final List<_ActiveFilterInfo> filters;

  const _ActiveFilterSummary({required this.filters});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          '当前筛选',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        for (final filter in filters)
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: filter.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              filter.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: filter.color,
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? tooltip;
  final bool selected;
  final VoidCallback? onTap;

  const _HistoryStatPill({
    required this.icon,
    required this.label,
    required this.color,
    this.tooltip,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
    final wrappedContent = tooltip == null
        ? content
        : Tooltip(
            message: tooltip!,
            child: content,
          );
    if (onTap == null) return wrappedContent;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: wrappedContent,
      ),
    );
  }
}

class _KnowledgeAnswerHistoryListCard extends StatelessWidget {
  final LearningSession session;
  final VoidCallback onTap;
  final ValueChanged<String> onSearchQuerySelected;

  const _KnowledgeAnswerHistoryListCard({
    required this.session,
    required this.onTap,
    required this.onSearchQuerySelected,
  });

  @override
  Widget build(BuildContext context) {
    final record = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
    final question = record.question ?? '知识库问答';
    final hasRepairAction = record.hasRepairableQualityIssue;
    final completedText = _dateText(session.endedAt ?? session.startedAt);
    final detailParts = [
      '完成于 $completedText',
      ...record.traceLabels,
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    KnowledgeAnswerEvidenceQualityBadges(record: record),
                    if (record.answer != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.answer!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (hasRepairAction) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KnowledgeAnswerRepairActionButton(
                          record: record,
                          onSelected: onSearchQuerySelected,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              KnowledgeAnswerReviewCopyButton(
                record: record,
                completedText: completedText,
                recordStatusText: knowledgeAnswerSavedRecordStatusText,
                iconSize: 18,
                color: AppColors.textLight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '还没有知识库问答记录',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyFilteredState extends StatelessWidget {
  final List<_ActiveFilterInfo> activeFilters;
  final VoidCallback onClearFilters;

  const _EmptyFilteredState({
    required this.activeFilters,
    required this.onClearFilters,
  });

  bool get _hasSearch {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.search,
    );
  }

  bool get _hasCleanEvidence {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.cleanEvidence,
    );
  }

  bool get _hasQualityIssue {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.qualityIssue,
    );
  }

  bool get _hasMissingCitation {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.missingCitation,
    );
  }

  bool get _hasSourceGap {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.sourceGap,
    );
  }

  bool get _hasRepairable {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.repairable,
    );
  }

  bool get _hasNeedsReview {
    return activeFilters.any(
      (filter) => filter.kind == _ActiveFilterKind.needsReview,
    );
  }

  String get _emptyTitle {
    if (_hasCleanEvidence &&
        (_hasRepairable ||
            _hasSourceGap ||
            _hasMissingCitation ||
            _hasQualityIssue ||
            _hasNeedsReview)) {
      return '当前组合筛选没有匹配记录';
    }
    if (_hasNeedsReview && _hasRepairable) {
      return '当前组合筛选没有匹配记录';
    }
    if (_hasCleanEvidence) {
      return _hasSearch ? '当前搜索下暂无证据合格问答' : '当前筛选下暂无证据合格问答';
    }
    if (_hasQualityIssue &&
        !_hasRepairable &&
        !_hasNeedsReview &&
        !_hasSourceGap &&
        !_hasMissingCitation) {
      return _hasSearch ? '当前搜索下暂无质量债问答' : '当前筛选下暂无质量债问答';
    }
    if (_hasNeedsReview) {
      return _hasSearch ? '当前搜索下暂无需核查问答' : '当前筛选下暂无需核查问答';
    }
    if (_hasRepairable) {
      return _hasSearch ? '当前搜索下暂无可补证知识库问答' : '当前筛选下暂无可补证知识库问答';
    }
    if (_hasSourceGap && !_hasMissingCitation) {
      return _hasSearch ? '当前搜索下暂无来源缺口问答' : '当前筛选下暂无来源缺口问答';
    }
    if (_hasMissingCitation && !_hasSourceGap) {
      return _hasSearch ? '当前搜索下暂无缺少引用问答' : '当前筛选下暂无缺少引用问答';
    }
    if (_hasMissingCitation || _hasSourceGap) {
      return _hasSearch ? '当前搜索和质量筛选没有匹配记录' : '当前组合筛选下暂无符合质量条件的问答';
    }
    return '当前搜索没有匹配的知识库问答';
  }

  String get _emptyDescription {
    if (_hasCleanEvidence &&
        (_hasRepairable ||
            _hasSourceGap ||
            _hasMissingCitation ||
            _hasQualityIssue ||
            _hasNeedsReview)) {
      return '证据合格和待补证据条件通常互斥，可以先清除其中一个筛选。';
    }
    if (_hasNeedsReview && _hasRepairable) {
      return '可补证和需核查条件通常互斥，可以先清除其中一个筛选。';
    }
    if (_hasCleanEvidence) {
      return '可以换一个关键词，或清除筛选查看全部知识库问答。';
    }
    if (_hasQualityIssue &&
        !_hasRepairable &&
        !_hasNeedsReview &&
        !_hasSourceGap &&
        !_hasMissingCitation) {
      return '说明现有记录里没有证据质量债，可以清除筛选查看全部问答。';
    }
    if (_hasSearch) {
      return '试试换一个问题关键词、引用 id 或追溯标签，或清除筛选后再看。';
    }
    if (_hasRepairable) {
      return '说明现有记录里没有可以直接继续检索补证的条目。';
    }
    if (_hasNeedsReview) {
      return '说明现有记录里没有需要人工继续核查的证据质量债。';
    }
    if (_hasMissingCitation || _hasSourceGap) {
      return '可以清除筛选查看全部问答，或继续从搜索页产生新的来源回答。';
    }
    return '清除筛选后可以回到完整知识库问答历史。';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Text(
            _emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _emptyDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 10),
          if (activeFilters.isNotEmpty) ...[
            _ActiveFilterSummary(filters: activeFilters),
            const SizedBox(height: 10),
          ],
          TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.filter_alt_off, size: 18),
            label: const Text('清除筛选'),
          ),
        ],
      ),
    );
  }
}

String _dateText(DateTime date) {
  return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
