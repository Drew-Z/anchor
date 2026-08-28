import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/product_event.dart';
import '../../services/agent/project_interview_outcome.dart';
import '../../shared/widgets/alpha_feedback_action.dart';
import '../knowledge_base/knowledge_base_screen.dart';
import '../knowledge_base/knowledge_library_error_state.dart';

class ProjectInterviewOutcomeScreen extends ConsumerStatefulWidget {
  final String? sourceId;

  const ProjectInterviewOutcomeScreen({super.key, this.sourceId});

  @override
  ConsumerState<ProjectInterviewOutcomeScreen> createState() =>
      _ProjectInterviewOutcomeScreenState();
}

class _ProjectInterviewOutcomeScreenState
    extends ConsumerState<ProjectInterviewOutcomeScreen> {
  ProjectInterviewOutcomeStatus? _filter;
  bool _isExporting = false;
  String? _lastRecordedSignature;

  @override
  Widget build(BuildContext context) {
    final outcomeAsync = ref.watch(projectInterviewOutcomeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目面试成果'),
        actions: [
          AlphaFeedbackIconButton(
            screenId: 'project_interview_outcome',
            diagnosticLines: [
              '成果范围: ${widget.sourceId == null ? 'all_sources' : 'single_source'}',
            ],
          ),
          PopupMenuButton<ProjectInterviewOutcomeExportFormat>(
            tooltip: '导出项目面试成果',
            enabled: !_isExporting,
            icon: _isExporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_outlined),
            onSelected: (format) => _export(format),
            itemBuilder: (context) => ProjectInterviewOutcomeExportFormat.values
                .map(
                  (format) => PopupMenuItem(
                    value: format,
                    child: Text('导出 ${format.label}'),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
      body: SafeArea(
        child: outcomeAsync.when(
          data: (outcome) {
            final scoped = _scoped(outcome);
            _recordViewed(scoped);
            return _buildOutcome(scoped);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: KnowledgeLibraryErrorState(
              title: '项目面试成果读取失败',
              retryLabel: '重新读取成果',
              diagnosticTitle: '项目面试成果读取失败',
              diagnosticSuccessMessage: '已复制成果读取诊断',
              diagnosticLines: const ['入口: 项目面试成果'],
              error: error,
              onRetry: () => ref.invalidate(projectInterviewOutcomeProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutcome(ProjectInterviewOutcome outcome) {
    final units = _filter == null
        ? outcome.units
        : outcome.units
            .where((unit) => unit.status == _filter)
            .toList(growable: false);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectInterviewOutcomeProvider);
        await ref.read(projectInterviewOutcomeProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _OutcomeHeader(outcome: outcome),
          const SizedBox(height: 14),
          _StatusFilter(
            selected: _filter,
            outcome: outcome,
            onSelected: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 14),
          if (outcome.units.isEmpty)
            const _EmptyOutcome()
          else if (units.isEmpty)
            const _EmptyFilter()
          else
            ...units.map(
              (unit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OutcomeUnitCard(
                  unit: unit,
                  onOpenEvidence: (evidence) => _openEvidence(evidence),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ProjectInterviewOutcome _scoped(ProjectInterviewOutcome outcome) {
    final sourceId = widget.sourceId;
    return sourceId == null ? outcome : outcome.forSource(sourceId);
  }

  Future<void> _export(ProjectInterviewOutcomeExportFormat format) async {
    if (_isExporting) return;
    final current = ref.read(projectInterviewOutcomeProvider).valueOrNull;
    if (current == null) return;
    final outcome = _scoped(current);
    setState(() => _isExporting = true);
    try {
      final artifact = ProjectInterviewOutcomeExporter().build(outcome, format);
      final path = await FilePicker.saveFile(
        dialogTitle: '导出项目面试成果',
        fileName: artifact.fileName,
        type: FileType.custom,
        allowedExtensions: [format.extension],
        bytes: Uint8List.fromList(utf8.encode(artifact.content)),
      );
      if (path == null || !mounted) return;
      await ref.read(productEventRecorderProvider).recordBestEffort(
        ProductEventName.outcomeExported,
        flowId: 'project_interview_outcome',
        goal: 'ai_interview_prep',
        properties: {
          'format': artifact.format.value,
          'included_citation_count': artifact.includedCitationCount,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.label} 导出完成'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $error')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openEvidence(ProjectInterviewOutcomeEvidence evidence) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SourceDetailScreen(
          source: evidence.source,
          highlightedChunkId: evidence.chunk.id,
          highlightedChunkLabel: '成果来源证据',
          highlightedChunkIcon: Icons.fact_check_outlined,
        ),
      ),
    );
  }

  void _recordViewed(ProjectInterviewOutcome outcome) {
    final signature = [
      outcome.readyCount,
      outcome.needsPracticeCount,
      outcome.evidenceGapCount,
      outcome.notAssessedCount,
      widget.sourceId ?? 'all',
    ].join(':');
    if (_lastRecordedSignature == signature) return;
    _lastRecordedSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(productEventRecorderProvider).recordBestEffort(
        ProductEventName.outcomeViewed,
        flowId: 'project_interview_outcome',
        goal: 'ai_interview_prep',
        properties: {
          'ready_count': outcome.readyCount,
          'weak_count': outcome.needsPracticeCount,
          'gap_count': outcome.evidenceGapCount,
          'unassessed_count': outcome.notAssessedCount,
        },
      );
    });
  }
}

class _OutcomeHeader extends StatelessWidget {
  final ProjectInterviewOutcome outcome;

  const _OutcomeHeader({required this.outcome});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '你能讲清多少，不由模型文笔决定。',
          style: TextStyle(
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          outcome.goal,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        if (outcome.projectTitles.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            outcome.projectTitles.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.blueDark,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CountCell(
                label: '可面试',
                count: outcome.readyCount,
                color: AppColors.greenDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountCell(
                label: '需练习',
                count: outcome.needsPracticeCount,
                color: AppColors.streakOrange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountCell(
                label: '证据缺口',
                count: outcome.evidenceGapCount,
                color: AppColors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CountCell(
                label: '未评估',
                count: outcome.notAssessedCount,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountCell extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountCell({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final ProjectInterviewOutcomeStatus? selected;
  final ProjectInterviewOutcome outcome;
  final ValueChanged<ProjectInterviewOutcomeStatus?> onSelected;

  const _StatusFilter({
    required this.selected,
    required this.outcome,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: '全部 ${outcome.units.length}',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in ProjectInterviewOutcomeStatus.values) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: '${status.label} ${_count(outcome, status)}',
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
          ],
        ],
      ),
    );
  }

  int _count(
    ProjectInterviewOutcome value,
    ProjectInterviewOutcomeStatus status,
  ) {
    return value.units.where((unit) => unit.status == status).length;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.greenLight,
      labelStyle: TextStyle(
        color: selected ? AppColors.greenDark : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? AppColors.green : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _OutcomeUnitCard extends StatelessWidget {
  final ProjectInterviewOutcomeUnit unit;
  final ValueChanged<ProjectInterviewOutcomeEvidence> onOpenEvidence;

  const _OutcomeUnitCard({
    required this.unit,
    required this.onOpenEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(unit.status);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      collapsedShape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_statusIcon(unit.status), color: color, size: 21),
      ),
      title: Text(
        unit.point.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${unit.point.kind.label} · ${unit.status.label} · 掌握 ${unit.point.masteryLevel}%',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: unit.reasons
                .map((reason) => _ReasonTag(reason.label, color))
                .toList(growable: false),
          ),
        ),
        if (unit.interviewScore != null) ...[
          const SizedBox(height: 14),
          _ScoreGrid(score: unit.interviewScore!),
        ],
        if (unit.latestAnswer != null) ...[
          const SizedBox(height: 14),
          _DetailSection(
            title: '最近回答',
            trailing: '用户内容 · ${_surfaceLabel(unit.latestAnswer!.surface)}',
            child: SelectableText(
              unit.latestAnswer!.text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _DetailSection(
          title: '来源支持的参考提纲',
          child: unit.referenceOutline.isEmpty
              ? const Text(
                  '当前没有通过逐字引用校验的正式主张。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: unit.referenceOutline
                      .map(
                        (claim) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 7),
                                child: Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: AppColors.greenDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  claim.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '查看该主张的来源证据',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => onOpenEvidence(
                                  claim.evidence.first.sourceEvidence,
                                ),
                                icon: const Icon(
                                  Icons.link,
                                  size: 19,
                                  color: AppColors.blueDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        if (unit.strongestEvidence != null) ...[
          const SizedBox(height: 14),
          _EvidencePanel(
            evidence: unit.strongestEvidence!,
            onTap: () => onOpenEvidence(unit.strongestEvidence!),
          ),
        ],
        if (unit.openFollowUp != null || unit.nextReviewAt != null) ...[
          const SizedBox(height: 14),
          _DetailSection(
            title: '下一步',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unit.openFollowUp != null)
                  Text(
                    '追问: ${unit.openFollowUp}',
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                if (unit.nextReviewAt != null)
                  Text(
                    '复习: ${_dateTime(unit.nextReviewAt!)}',
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReasonTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ReasonTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ScoreGrid extends StatelessWidget {
  final ProjectInterviewOutcomeScore score;

  const _ScoreGrid({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in [
          ('准确', score.accuracy),
          ('细节', score.projectDetail),
          ('判断', score.engineering),
          ('表达', score.clarity),
        ]) ...[
          Expanded(
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(
                    '${entry.$2}/5',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: entry.$2 >= 4
                          ? AppColors.greenDark
                          : AppColors.streakOrange,
                    ),
                  ),
                  Text(
                    entry.$1,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (entry.$1 != '表达') const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _EvidencePanel extends StatelessWidget {
  final ProjectInterviewOutcomeEvidence evidence;
  final VoidCallback onTap;

  const _EvidencePanel({required this.evidence, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.code, size: 19, color: AppColors.blueDark),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidence.locator,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blueDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    evidence.excerpt,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.blueDark),
          ],
        ),
      ),
    );
  }
}

class _EmptyOutcome extends StatelessWidget {
  const _EmptyOutcome();

  @override
  Widget build(BuildContext context) {
    return const _EmptyPanel(
      icon: Icons.account_tree_outlined,
      title: '还没有项目学习单元',
      message: '导入项目并确认架构、数据流、实现、边界或取舍后，这里会形成可追溯成果。',
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) {
    return const _EmptyPanel(
      icon: Icons.filter_alt_off_outlined,
      title: '当前状态没有单元',
      message: '切换筛选条件查看其他项目学习单元。',
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ProjectInterviewOutcomeStatus status) {
  switch (status) {
    case ProjectInterviewOutcomeStatus.ready:
      return AppColors.greenDark;
    case ProjectInterviewOutcomeStatus.needsPractice:
      return AppColors.streakOrange;
    case ProjectInterviewOutcomeStatus.evidenceGap:
      return AppColors.red;
    case ProjectInterviewOutcomeStatus.notAssessed:
      return AppColors.textSecondary;
  }
}

IconData _statusIcon(ProjectInterviewOutcomeStatus status) {
  switch (status) {
    case ProjectInterviewOutcomeStatus.ready:
      return Icons.verified_outlined;
    case ProjectInterviewOutcomeStatus.needsPractice:
      return Icons.fitness_center_outlined;
    case ProjectInterviewOutcomeStatus.evidenceGap:
      return Icons.link_off_outlined;
    case ProjectInterviewOutcomeStatus.notAssessed:
      return Icons.pending_actions_outlined;
  }
}

String _surfaceLabel(String value) {
  switch (value) {
    case 'interview':
      return '面试回答';
    case 'tutor':
      return '导师回答';
    case 'programming':
      return '编程练习';
    default:
      return value;
  }
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
