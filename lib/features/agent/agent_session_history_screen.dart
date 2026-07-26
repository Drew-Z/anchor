import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/learning_session.dart';
import '../../services/agent/agent_session_memory_index.dart';
import '../../services/agent/agent_session_target_id.dart';
import '../../services/agent/learning_agent_runtime_contracts.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'agent_session_detail_screen.dart';

class AgentSessionHistoryScreen extends ConsumerStatefulWidget {
  final LearningAgentGoal? initialGoal;
  final bool initialOnlyWithFollowUp;
  final String? initialTargetId;
  final String? initialTargetLabel;

  const AgentSessionHistoryScreen({
    super.key,
    this.initialGoal,
    this.initialOnlyWithFollowUp = false,
    this.initialTargetId,
    this.initialTargetLabel,
  });

  @override
  ConsumerState<AgentSessionHistoryScreen> createState() =>
      _AgentSessionHistoryScreenState();
}

class _AgentSessionHistoryScreenState
    extends ConsumerState<AgentSessionHistoryScreen> {
  late LearningAgentGoal? _selectedGoal;
  late bool _onlyWithFollowUp;
  late String? _targetId;
  late String? _targetLabel;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal;
    _onlyWithFollowUp = widget.initialOnlyWithFollowUp;
    _targetId = normalizeAgentSessionTargetId(widget.initialTargetId);
    _targetLabel = _targetId == null ? null : widget.initialTargetLabel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(agentSessionMemoryIndexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Session 历史')),
      body: SafeArea(
        child: memoryAsync.when(
          data: (memory) {
            if (memory.sessions.isEmpty) {
              return const _EmptyAgentSessionHistory();
            }
            final followUpIndex = memory.followUps;
            final filteredSessions = _filteredSessions(
              memory.sessions,
              followUpIndex,
            );
            final goalCounts = memory.goals.countsByGoal;
            final openFollowUpCount = _openFollowUpCount(memory);
            final targetTotalCount = _targetSessionCount(memory);
            final itemCount =
                filteredSessions.isEmpty ? 2 : filteredSessions.length + 1;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _GoalFilterBar(
                    selectedGoal: _selectedGoal,
                    onlyWithFollowUp: _onlyWithFollowUp,
                    hasTargetFilter: _hasTargetFilter,
                    targetLabel: _targetLabel,
                    searchController: _searchController,
                    hasActiveFilters: _hasActiveFilters,
                    goalCounts: goalCounts,
                    totalCount: memory.totalCount,
                    filteredCount: filteredSessions.length,
                    targetTotalCount: targetTotalCount,
                    openFollowUpCount: openFollowUpCount,
                    onSelected: (goal) {
                      setState(() {
                        _selectedGoal = goal;
                        _targetId = null;
                        _targetLabel = null;
                      });
                    },
                    onOnlyWithFollowUpChanged: (value) {
                      setState(() => _onlyWithFollowUp = value);
                    },
                    onSearchChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                    onClearTargetFilter: _clearTargetFilter,
                    onClearFilters: _clearFilters,
                  );
                }
                if (filteredSessions.isEmpty) {
                  return _EmptyFilteredHistory(
                    message: _emptyFilteredMessage(),
                    onClearFilters: _hasActiveFilters ? _clearFilters : null,
                  );
                }
                final session = filteredSessions[index - 1];
                return _AgentSessionHistoryListCard(
                  session: session,
                  hasOpenFollowUp: followUpIndex.hasOpenFollowUp(session),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AgentSessionDetailScreen(
                          session: session,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          ),
          error: (error, _) => KnowledgeLibraryErrorState(
            title: 'Agent Session 历史读取失败',
            retryLabel: '重试读取历史',
            diagnosticTitle: 'Agent Session 历史读取失败',
            diagnosticSuccessMessage: '已复制 Agent Session 历史读取诊断',
            diagnosticLines: _historyErrorDiagnosticLines(),
            error: error,
            onRetry: () {
              ref.invalidate(agentSessionListProvider);
              ref.invalidate(agentSessionMemoryIndexProvider);
            },
          ),
        ),
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedGoal != null ||
        _hasTargetFilter ||
        _onlyWithFollowUp ||
        _searchQuery.isNotEmpty;
  }

  bool get _hasTargetFilter {
    return normalizeAgentSessionTargetId(_targetId) != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedGoal = null;
      _targetId = null;
      _targetLabel = null;
      _onlyWithFollowUp = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _clearTargetFilter() {
    setState(() {
      _targetId = null;
      _targetLabel = null;
    });
  }

  String _emptyFilteredMessage() {
    if (_onlyWithFollowUp) {
      if (_hasTargetFilter) return '当前目标没有未处理追问';
      return _selectedGoal == null ? '当前没有未处理追问' : '当前目标没有未处理追问';
    }
    if (_searchQuery.isNotEmpty) {
      return '当前搜索没有匹配的 Agent Session 记录';
    }
    if (_hasTargetFilter) {
      return '当前目标还没有 Agent Session 记录';
    }
    if (_selectedGoal != null) {
      return '当前目标还没有 Agent Session 记录';
    }
    return '当前筛选没有 Agent Session 记录';
  }

  List<LearningSession> _filteredSessions(
    List<LearningSession> sessions,
    AgentSessionFollowUpIndex followUpIndex,
  ) {
    final selectedGoal = _selectedGoal;
    final targetId = normalizeAgentSessionTargetId(_targetId);
    final query = _searchQuery.toLowerCase();
    return sessions.where((session) {
      final record = AgentSessionSummaryRecord.fromSession(session);
      if (targetId != null &&
          normalizeAgentSessionTargetId(session.targetId) != targetId) {
        return false;
      }
      if (selectedGoal != null && record.goal != selectedGoal) {
        return false;
      }
      if (_onlyWithFollowUp && !followUpIndex.hasOpenFollowUp(session)) {
        return false;
      }
      if (query.isNotEmpty && !_recordMatchesQuery(record, query)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _recordMatchesQuery(AgentSessionSummaryRecord record, String query) {
    final text = [
      record.title,
      record.target,
      record.criteria,
      record.confirmedCriteria,
      record.activeQuestion,
      record.nextQuestion,
      record.note,
      ...record.lines,
    ].whereType<String>().join('\n').toLowerCase();
    return text.contains(query);
  }

  int _openFollowUpCount(AgentSessionMemoryIndex memory) {
    final selectedGoal = _selectedGoal;
    final targetId = normalizeAgentSessionTargetId(_targetId);
    if (targetId != null) {
      return memory.openFollowUpCountForTarget(targetId);
    }
    if (selectedGoal == null) return memory.openFollowUpCount;
    return memory.openFollowUpCountForGoal(selectedGoal);
  }

  int? _targetSessionCount(AgentSessionMemoryIndex memory) {
    final targetId = normalizeAgentSessionTargetId(_targetId);
    if (targetId == null) return null;
    return memory.countForTarget(targetId);
  }

  List<String> _historyErrorDiagnosticLines() {
    final selectedGoal = _selectedGoal;
    final query = _searchQuery.trim();
    final target = _targetLabel?.trim();
    return [
      '入口: Agent Session 历史',
      '当前目标: ${selectedGoal?.label ?? '全部'}',
      '只看未处理追问: ${_onlyWithFollowUp ? '是' : '否'}',
      '目标筛选: ${target == null || target.isEmpty ? '无' : target}',
      '搜索: ${query.isEmpty ? '无' : query}',
    ];
  }
}

class _GoalFilterBar extends StatelessWidget {
  final LearningAgentGoal? selectedGoal;
  final bool onlyWithFollowUp;
  final bool hasTargetFilter;
  final String? targetLabel;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final Map<LearningAgentGoal, int> goalCounts;
  final int totalCount;
  final int filteredCount;
  final int? targetTotalCount;
  final int openFollowUpCount;
  final ValueChanged<LearningAgentGoal?> onSelected;
  final ValueChanged<bool> onOnlyWithFollowUpChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearTargetFilter;
  final VoidCallback onClearFilters;

  const _GoalFilterBar({
    required this.selectedGoal,
    required this.onlyWithFollowUp,
    required this.hasTargetFilter,
    required this.targetLabel,
    required this.searchController,
    required this.hasActiveFilters,
    required this.goalCounts,
    required this.totalCount,
    required this.filteredCount,
    required this.targetTotalCount,
    required this.openFollowUpCount,
    required this.onSelected,
    required this.onOnlyWithFollowUpChanged,
    required this.onSearchChanged,
    required this.onClearTargetFilter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _summaryText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasTargetFilter) ...[
            const SizedBox(height: 8),
            _TargetFilterBadge(
              label: _targetText,
              onClear: onClearTargetFilter,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GoalFilterChip(
                label: '全部 $totalCount',
                selected: selectedGoal == null,
                onSelected: () => onSelected(null),
              ),
              ...LearningAgentGoal.values.map(
                (goal) => _GoalFilterChip(
                  label: '${goal.label} ${goalCounts[goal] ?? 0}',
                  selected: selectedGoal == goal,
                  onSelected: () => onSelected(goal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => onOnlyWithFollowUpChanged(!onlyWithFollowUp),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: onlyWithFollowUp,
                  onChanged: (value) {
                    onOnlyWithFollowUpChanged(value ?? false);
                  },
                  activeColor: AppColors.green,
                  visualDensity: VisualDensity.compact,
                ),
                const Text(
                  '只看未处理追问',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$openFollowUpCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blueDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: '搜索目标、追问或复盘',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.green),
              ),
            ),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text(
                  '清除筛选',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _titleText {
    if (hasTargetFilter) {
      return '$_targetText $filteredCount/${targetTotalCount ?? totalCount}';
    }
    if (selectedGoal == null) return '全部记录 $filteredCount/$totalCount';
    return '${selectedGoal!.label} $filteredCount/$totalCount';
  }

  String get _summaryText {
    if (hasTargetFilter) {
      final targetCount = targetTotalCount ?? filteredCount;
      return '当前目标共 $targetCount 条记录，'
          '当前视图 $filteredCount 条，'
          '$openFollowUpCount 条未处理追问';
    }
    return _followUpSummaryText;
  }

  String get _targetText {
    final target = targetLabel?.trim();
    return target == null || target.isEmpty ? '当前目标' : target;
  }

  String get _followUpSummaryText {
    if (selectedGoal == null) {
      return '当前视图有 $openFollowUpCount 条未处理追问';
    }
    return '当前目标有 $openFollowUpCount 条未处理追问';
  }
}

class _TargetFilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _TargetFilterBadge({
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt, size: 14, color: AppColors.blueDark),
          const SizedBox(width: 4),
          Text(
            '目标筛选: $label',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.blueDark,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppColors.blueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _GoalFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.greenLight,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.green : AppColors.border,
        width: 1.5,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: selected ? AppColors.greenDark : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _AgentSessionHistoryListCard extends StatelessWidget {
  final LearningSession session;
  final bool hasOpenFollowUp;
  final VoidCallback onTap;

  const _AgentSessionHistoryListCard({
    required this.session,
    required this.hasOpenFollowUp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = _AgentSessionListData.fromSession(session);

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
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (data.activeQuestion != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '本轮追问: ${data.activeQuestion}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                    if (data.followUp != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${hasOpenFollowUp ? '下次追问' : '已处理追问'}: ${data.followUp}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: hasOpenFollowUp
                              ? AppColors.blueDark
                              : AppColors.textLight,
                        ),
                      ),
                      if (hasOpenFollowUp) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.question_answer_outlined),
                            label: const Text(
                              '继续追问',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.blueDark,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentSessionListData {
  final String title;
  final String subtitle;
  final String? activeQuestion;
  final String? followUp;

  const _AgentSessionListData({
    required this.title,
    required this.subtitle,
    required this.activeQuestion,
    required this.followUp,
  });

  factory _AgentSessionListData.fromSession(LearningSession session) {
    final summary = AgentSessionSummaryRecord.fromSession(session);
    final date = _dateText(session.endedAt ?? session.startedAt);
    final subtitleParts = [
      if (summary.target != null) '目标: ${summary.target}',
      if (summary.criteria != null) '成功标准: ${summary.criteria}',
      date,
    ];

    return _AgentSessionListData(
      title: summary.title,
      subtitle: subtitleParts.join(' · '),
      activeQuestion: summary.activeQuestion,
      followUp: summary.nextQuestion,
    );
  }
}

class _EmptyAgentSessionHistory extends StatelessWidget {
  const _EmptyAgentSessionHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '完成 Agent Session 后，这里会出现完整历史',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyFilteredHistory extends StatelessWidget {
  final String message;
  final VoidCallback? onClearFilters;

  const _EmptyFilteredHistory({
    required this.message,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          if (onClearFilters != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text(
                '清除筛选',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.greenDark,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _dateText(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
