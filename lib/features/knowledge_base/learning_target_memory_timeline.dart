import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/agent/learning_agent_memory_record.dart';

class LearningTargetMemoryTimeline extends StatelessWidget {
  final LearningAgentMemorySnapshot snapshot;
  final int visibleRecordLimit;

  const LearningTargetMemoryTimeline({
    super.key,
    required this.snapshot,
    this.visibleRecordLimit = 8,
  });

  @override
  Widget build(BuildContext context) {
    final visibleRecords =
        snapshot.records.take(visibleRecordLimit).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '连续学习历史',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${snapshot.recordCount} 条',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (snapshot.isEmpty)
          const _MemoryEmptyState()
        else ...[
          _MemoryHighlights(snapshot: snapshot),
          const SizedBox(height: 8),
          for (var index = 0; index < visibleRecords.length; index += 1)
            _MemoryTimelineRow(
              record: visibleRecords[index],
              openFollowUpCount: snapshot.openFollowUps
                  .where((item) => item.recordId == visibleRecords[index].id)
                  .length,
              isLast: index == visibleRecords.length - 1,
            ),
          if (snapshot.records.length > visibleRecords.length) ...[
            const SizedBox(height: 8),
            Text(
              '另有 ${snapshot.records.length - visibleRecords.length} 条较早记录',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _MemoryHighlights extends StatelessWidget {
  final LearningAgentMemorySnapshot snapshot;

  const _MemoryHighlights({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final stableMisconceptions = snapshot.stableMisconceptions
        .take(2)
        .map((item) => '${item.label} ×${item.occurrenceCount}')
        .join('、');
    final weakDimensions = snapshot.weakDimensions
        .take(3)
        .map((item) => '${item.label} ×${item.occurrenceCount}')
        .join('、');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HighlightLine(
            icon: Icons.help_outline,
            color: snapshot.openFollowUps.isEmpty
                ? AppColors.greenDark
                : AppColors.goldDark,
            text: snapshot.openFollowUps.isEmpty
                ? '开放追问：0'
                : '开放追问：${snapshot.openFollowUps.length}',
          ),
          if (stableMisconceptions.isNotEmpty) ...[
            const SizedBox(height: 6),
            _HighlightLine(
              icon: Icons.error_outline,
              color: AppColors.redDark,
              text: '稳定误区：$stableMisconceptions',
            ),
          ],
          if (weakDimensions.isNotEmpty) ...[
            const SizedBox(height: 6),
            _HighlightLine(
              icon: Icons.analytics_outlined,
              color: AppColors.purpleDark,
              text: '薄弱维度：$weakDimensions',
            ),
          ],
          if (snapshot.nextReviewAt != null) ...[
            const SizedBox(height: 6),
            _HighlightLine(
              icon: Icons.event_repeat,
              color: AppColors.blueDark,
              text: '下次复习：${_formatDateTime(snapshot.nextReviewAt!)}',
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _HighlightLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemoryTimelineRow extends StatelessWidget {
  final LearningAgentMemoryRecord record;
  final int openFollowUpCount;
  final bool isLast;

  const _MemoryTimelineRow({
    required this.record,
    required this.openFollowUpCount,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleForType(record.type);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(style.icon, size: 19, color: style.foreground),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(record.occurredAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  record.type.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: style.foreground,
                  ),
                ),
                if (record.summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    record.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_metadataItems(record, openFollowUpCount).isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    children: _metadataItems(record, openFollowUpCount),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _metadataItems(
  LearningAgentMemoryRecord record,
  int openFollowUpCount,
) {
  return [
    if (record.citationIds.isNotEmpty)
      _MetadataItem(
        icon: Icons.link,
        text: '${record.citationIds.length} 条来源',
      ),
    if (!record.evidenceSufficient)
      const _MetadataItem(
        icon: Icons.gpp_maybe_outlined,
        text: '证据待核查',
        color: AppColors.redDark,
      ),
    if (openFollowUpCount > 0)
      _MetadataItem(
        icon: Icons.help_outline,
        text: '$openFollowUpCount 条待追问',
        color: AppColors.goldDark,
      ),
    if (record.hasOpenReview)
      _MetadataItem(
        icon: Icons.event_repeat,
        text: '复习 ${_formatDateTime(record.reviewDueAt!)}',
        color: AppColors.blueDark,
      ),
    if (record.usesLegacyTargetInference)
      const _MetadataItem(
        icon: Icons.history,
        text: '历史归属',
      ),
  ];
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetadataItem({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MemoryEmptyState extends StatelessWidget {
  const _MemoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.history, size: 19, color: AppColors.textLight),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '还没有与这个知识点关联的学习记录',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_MemoryTypeStyle _styleForType(LearningAgentMemoryRecordType type) {
  switch (type) {
    case LearningAgentMemoryRecordType.knowledgeAnswer:
      return const _MemoryTypeStyle(
        icon: Icons.menu_book_outlined,
        foreground: AppColors.greenDark,
        background: AppColors.greenLight,
      );
    case LearningAgentMemoryRecordType.tutor:
      return const _MemoryTypeStyle(
        icon: Icons.school_outlined,
        foreground: AppColors.blueDark,
        background: AppColors.blueLight,
      );
    case LearningAgentMemoryRecordType.interview:
      return const _MemoryTypeStyle(
        icon: Icons.record_voice_over_outlined,
        foreground: AppColors.purpleDark,
        background: Color(0xFFF3E5FF),
      );
    case LearningAgentMemoryRecordType.programmingExercise:
      return const _MemoryTypeStyle(
        icon: Icons.code,
        foreground: Color(0xFF087F8C),
        background: Color(0xFFDDF6F7),
      );
    case LearningAgentMemoryRecordType.agentReflection:
      return const _MemoryTypeStyle(
        icon: Icons.psychology_outlined,
        foreground: AppColors.redDark,
        background: AppColors.redLight,
      );
    case LearningAgentMemoryRecordType.reviewAction:
      return const _MemoryTypeStyle(
        icon: Icons.event_repeat,
        foreground: Color(0xFF9A6A00),
        background: Color(0xFFFFF3C4),
      );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

class _MemoryTypeStyle {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _MemoryTypeStyle({
    required this.icon,
    required this.foreground,
    required this.background,
  });
}
