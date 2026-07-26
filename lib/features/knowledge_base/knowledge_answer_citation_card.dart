import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';

typedef KnowledgeAnswerSourceChunkOpener = Future<void> Function(
  BuildContext context,
  Source source,
  SourceChunk chunk,
);

class KnowledgeAnswerCitationCard extends StatelessWidget {
  final Source? source;
  final SourceChunk chunk;
  final KnowledgeAnswerSourceChunkOpener? onOpenSourceChunk;
  final VoidCallback? onCopySourceId;
  final VoidCallback? onCopyChunkId;

  const KnowledgeAnswerCitationCard({
    super.key,
    required this.source,
    required this.chunk,
    this.onOpenSourceChunk,
    this.onCopySourceId,
    this.onCopyChunkId,
  });

  @override
  Widget build(BuildContext context) {
    final source = this.source;
    final openSourceChunk = onOpenSourceChunk;
    final canOpen = source != null && openSourceChunk != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: source == null || openSourceChunk == null
              ? null
              : () => openSourceChunk(context, source, chunk),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        source == null
                            ? '未知来源 · source ${chunk.sourceId}'
                            : '${source.title} · ${source.trustLevel.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (canOpen) ...[
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: '打开来源并定位片段',
                        child: Icon(
                          Icons.open_in_new,
                          size: 15,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                    if (source == null && onCopySourceId != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '复制 source id',
                        onPressed: onCopySourceId,
                        icon: const Icon(Icons.copy_all, size: 15),
                        color: AppColors.goldDark,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ],
                    if (onCopyChunkId != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '复制片段 id',
                        onPressed: onCopyChunkId,
                        icon: const Icon(Icons.copy, size: 15),
                        color: AppColors.textLight,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  chunk.locator == null || chunk.locator!.trim().isEmpty
                      ? '片段 ${chunk.chunkIndex + 1}'
                      : chunk.locator!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  chunk.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
