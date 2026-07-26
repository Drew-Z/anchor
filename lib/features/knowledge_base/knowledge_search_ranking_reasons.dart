import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class KnowledgeSearchRankingReasons extends StatelessWidget {
  final List<String> reasons;
  final int maxVisible;

  const KnowledgeSearchRankingReasons({
    super.key,
    required this.reasons,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final visibleReasons = reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .take(maxVisible)
        .toList(growable: false);
    if (visibleReasons.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.insights_outlined,
            size: 14,
            color: AppColors.blueDark,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '排序依据：${visibleReasons.join(' · ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
