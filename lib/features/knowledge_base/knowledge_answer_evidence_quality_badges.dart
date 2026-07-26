import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/agent/knowledge_answer_session_summary.dart';

class KnowledgeAnswerEvidenceQualityBadges extends StatelessWidget {
  final KnowledgeAnswerSessionSummaryRecord record;

  const KnowledgeAnswerEvidenceQualityBadges({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in knowledgeAnswerEvidenceQualityLabels(record))
          _EvidenceQualityBadge(data: _badgeData(label)),
      ],
    );
  }
}

class _EvidenceQualityBadgeData {
  final IconData icon;
  final String label;
  final String message;
  final Color color;

  const _EvidenceQualityBadgeData({
    required this.icon,
    required this.label,
    required this.message,
    required this.color,
  });
}

_EvidenceQualityBadgeData _badgeData(String label) {
  if (label == '证据合格') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.verified,
      label: '证据合格',
      message: '这条回答有引用，且没有记录来源缺口',
      color: AppColors.greenDark,
    );
  }
  if (label == '缺少引用') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.link_off,
      label: '缺少引用',
      message: '这条回答没有保存引用 id',
      color: AppColors.red,
    );
  }
  if (label == '来源缺口') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.warning_amber,
      label: '来源缺口',
      message: '这条回答记录了仍需补充依据的问题',
      color: AppColors.goldDark,
    );
  }
  if (label == '部分主张未支持') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.rule,
      label: '部分主张未支持',
      message: '仅展示通过逐字引文核验的主张，未通过部分已被移除',
      color: AppColors.goldDark,
    );
  }
  if (label == '证据不足已拒答') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.block,
      label: '证据不足已拒答',
      message: '没有主张通过来源核验，本次未生成可用于学习的回答',
      color: AppColors.red,
    );
  }
  if (label == '历史记录未审计') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.history,
      label: '历史记录未审计',
      message: '这条旧记录没有主张级证据审计，不能视为证据合格',
      color: AppColors.purpleDark,
    );
  }
  if (label == '缺少主张审计') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.fact_check_outlined,
      label: '缺少主张审计',
      message: '回答状态存在，但没有保存可复核的主张记录',
      color: AppColors.purpleDark,
    );
  }
  if (label == '可补证') {
    return const _EvidenceQualityBadgeData(
      icon: Icons.build,
      label: '可补证',
      message: '可以继续检索依据来修复这条回答',
      color: AppColors.goldDark,
    );
  }
  return _EvidenceQualityBadgeData(
    icon: Icons.rule,
    label: label,
    message: '这条回答有质量债，但暂时没有直接补证动作',
    color: AppColors.purpleDark,
  );
}

class _EvidenceQualityBadge extends StatelessWidget {
  final _EvidenceQualityBadgeData data;

  const _EvidenceQualityBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: data.message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 13, color: data.color),
            const SizedBox(width: 4),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: data.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
