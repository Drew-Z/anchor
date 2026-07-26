import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/source_chunk.dart';

class SourceCitationBlock extends ConsumerWidget {
  final SourceChunk chunk;
  final Color backgroundColor;
  final BoxBorder? border;
  final EdgeInsetsGeometry margin;
  final int maxContentLines;
  final double contentLineHeight;
  final String fallbackLocator;

  const SourceCitationBlock({
    super.key,
    required this.chunk,
    this.backgroundColor = Colors.white,
    this.border,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.maxContentLines = 5,
    this.contentLineHeight = 1.4,
    this.fallbackLocator = 'source chunk',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locator = chunk.locator == null || chunk.locator!.isEmpty
        ? fallbackLocator
        : chunk.locator!;
    final sourceAsync = ref.watch(sourceProvider(chunk.sourceId));

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sourceAsync.when(
            data: (source) => source == null
                ? _SourceCitationStatusLine(
                    label: '来源已缺失',
                    icon: Icons.link_off,
                    color: AppColors.red,
                    onRetry: () => ref.invalidate(
                      sourceProvider(chunk.sourceId),
                    ),
                    onCopyDiagnostic: () => _copyCitationSourceDiagnostic(
                      context,
                      chunk: chunk,
                      locator: locator,
                      title: '引用片段缺失来源记录',
                      status: '已读取引用片段，但没有找到对应来源记录',
                    ),
                  )
                : Text(
                    '${source.title} · ${source.trustLevel.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
            loading: () => const _SourceCitationStatusLine(
              label: '正在读取来源...',
              icon: Icons.source,
              color: AppColors.textSecondary,
            ),
            error: (error, _) => _SourceCitationStatusLine(
              label: '来源读取失败',
              icon: Icons.error_outline,
              color: AppColors.red,
              onRetry: () => ref.invalidate(
                sourceProvider(chunk.sourceId),
              ),
              onCopyDiagnostic: () => _copyCitationSourceDiagnostic(
                context,
                chunk: chunk,
                locator: locator,
                title: '引用片段来源读取失败',
                status: '来源读取失败',
                error: error,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locator,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chunk.content,
            maxLines: maxContentLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: contentLineHeight,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCitationStatusLine extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onRetry;
  final VoidCallback? onCopyDiagnostic;

  const _SourceCitationStatusLine({
    required this.label,
    required this.icon,
    required this.color,
    this.onRetry,
    this.onCopyDiagnostic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        if (onRetry != null)
          IconButton(
            tooltip: '重试读取来源',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh, size: 15),
            color: color,
            onPressed: onRetry,
          ),
        if (onCopyDiagnostic != null)
          IconButton(
            tooltip: '复制来源诊断',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.copy, size: 15),
            color: color,
            onPressed: onCopyDiagnostic,
          ),
      ],
    );
  }
}

Future<void> _copyCitationSourceDiagnostic(
  BuildContext context, {
  required SourceChunk chunk,
  required String locator,
  required String title,
  required String status,
  Object? error,
}) async {
  final errorText = error?.toString().trim();
  final copiedAtText = _dateTimeText(DateTime.now());
  final text = [
    '# $title',
    '',
    '来源 ID: ${chunk.sourceId}',
    '片段 ID: ${chunk.id}',
    '片段位置: $locator',
    '状态: $status',
    if (errorText != null && errorText.isNotEmpty) '错误: $errorText',
    '复制时间: $copiedAtText',
  ].join('\n');
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已复制来源诊断')),
  );
}

String _dateText(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _dateTimeText(DateTime value) {
  return '${_dateText(value)} ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
