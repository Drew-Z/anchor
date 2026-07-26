import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';

class KnowledgeAnswerRepairActionButton extends StatelessWidget {
  final KnowledgeAnswerSessionSummaryRecord record;
  final ValueChanged<String> onSelected;

  const KnowledgeAnswerRepairActionButton({
    super.key,
    required this.record,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final kind = record.evidenceRepairKind;
    final query = record.evidenceRepairQuery;
    if (kind == null || query == null) return const SizedBox.shrink();
    final action = _KnowledgeAnswerRepairAction.fromKind(kind);
    return Tooltip(
      message: action.tooltip,
      child: TextButton.icon(
        onPressed: () => onSelected(query),
        icon: Icon(action.icon, size: 16),
        label: Text(action.label),
        style: TextButton.styleFrom(
          foregroundColor: action.color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _KnowledgeAnswerRepairAction {
  final String label;
  final String tooltip;
  final IconData icon;
  final Color color;

  const _KnowledgeAnswerRepairAction({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.color,
  });

  factory _KnowledgeAnswerRepairAction.fromKind(
    KnowledgeAnswerEvidenceRepairKind kind,
  ) {
    if (kind == KnowledgeAnswerEvidenceRepairKind.sourceGap) {
      return _KnowledgeAnswerRepairAction(
        label: knowledgeAnswerEvidenceRepairKindLabel(kind),
        tooltip: '使用来源缺口继续检索依据',
        icon: Icons.search,
        color: AppColors.goldDark,
      );
    }
    return _KnowledgeAnswerRepairAction(
      label: knowledgeAnswerEvidenceRepairKindLabel(kind),
      tooltip: '使用原问题补齐引用依据',
      icon: Icons.link,
      color: AppColors.red,
    );
  }
}
