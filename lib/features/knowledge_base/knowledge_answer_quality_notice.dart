import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';

class KnowledgeAnswerQualityNotice extends StatelessWidget {
  final KnowledgeAnswerSessionStats stats;
  final VoidCallback onOpenQualityIssues;
  final VoidCallback onOpenMissingCitations;
  final VoidCallback onOpenSourceGaps;
  final VoidCallback onOpenRepairable;
  final VoidCallback onOpenNeedsReview;
  final VoidCallback onOpenCleanEvidence;

  const KnowledgeAnswerQualityNotice({
    super.key,
    required this.stats,
    required this.onOpenQualityIssues,
    required this.onOpenMissingCitations,
    required this.onOpenSourceGaps,
    required this.onOpenRepairable,
    required this.onOpenNeedsReview,
    required this.onOpenCleanEvidence,
  });

  String get _guidanceText {
    if (stats.hasRepairableIssues && stats.hasNonRepairableQualityIssues) {
      return '当前 ${stats.repairableCount} 条可直接补证，另有 '
          '${stats.nonRepairableQualityIssueCount} 条需要打开历史继续判断。';
    }
    if (stats.hasRepairableIssues) {
      return '当前 ${stats.repairableCount} 条可直接补证，打开历史后可继续检索依据。';
    }
    return '当前 ${stats.qualityIssueCount} 条有证据质量债，打开历史后可继续核查依据。';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber,
                size: 19,
                color: AppColors.goldDark,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '证据待补',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.qualityIssueCount} 条待补证据 · '
            '${stats.cleanCount} 条已合格',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w900,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (stats.qualityIssueCount > 0)
                TextButton.icon(
                  onPressed: onOpenQualityIssues,
                  icon: const Icon(Icons.rule, size: 16),
                  label: Text('${stats.qualityIssueCount} 条质量债'),
                ),
              if (stats.missingCitationCount > 0)
                TextButton.icon(
                  onPressed: onOpenMissingCitations,
                  icon: const Icon(Icons.link_off, size: 16),
                  label: Text('${stats.missingCitationCount} 条缺少引用'),
                ),
              if (stats.sourceGapCount > 0)
                TextButton.icon(
                  onPressed: onOpenSourceGaps,
                  icon: const Icon(
                    Icons.warning_amber,
                    size: 16,
                  ),
                  label: Text('${stats.sourceGapCount} 条有来源缺口'),
                ),
              if (stats.repairableCount > 0)
                TextButton.icon(
                  onPressed: onOpenRepairable,
                  icon: const Icon(Icons.build, size: 16),
                  label: Text('${stats.repairableCount} 条可补证'),
                ),
              if (stats.nonRepairableQualityIssueCount > 0)
                TextButton.icon(
                  onPressed: onOpenNeedsReview,
                  icon: const Icon(Icons.rule, size: 16),
                  label: Text(
                    '${stats.nonRepairableQualityIssueCount} 条需核查',
                  ),
                ),
              if (stats.cleanCount > 0)
                TextButton.icon(
                  onPressed: onOpenCleanEvidence,
                  icon: const Icon(Icons.verified, size: 16),
                  label: Text('${stats.cleanCount} 条证据合格'),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _guidanceText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
