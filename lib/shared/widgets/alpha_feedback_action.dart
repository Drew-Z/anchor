import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../services/privacy/alpha_feedback_service.dart';

class AlphaFeedbackIconButton extends ConsumerWidget {
  final String screenId;
  final String? stableErrorCode;
  final List<String> diagnosticLines;

  const AlphaFeedbackIconButton({
    super.key,
    required this.screenId,
    this.stableErrorCode,
    this.diagnosticLines = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '提交私测反馈',
      onPressed: () => showAlphaFeedbackFlow(
        context,
        ref,
        screenId: screenId,
        stableErrorCode: stableErrorCode,
        diagnosticLines: diagnosticLines,
      ),
      icon: const Icon(Icons.feedback_outlined),
    );
  }
}

class AlphaFeedbackButton extends ConsumerWidget {
  final String screenId;
  final String? stableErrorCode;
  final List<String> diagnosticLines;

  const AlphaFeedbackButton({
    super.key,
    required this.screenId,
    this.stableErrorCode,
    this.diagnosticLines = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => showAlphaFeedbackFlow(
        context,
        ref,
        screenId: screenId,
        stableErrorCode: stableErrorCode,
        diagnosticLines: diagnosticLines,
      ),
      icon: const Icon(Icons.feedback_outlined, size: 18),
      label: const Text('提交反馈'),
    );
  }
}

Future<void> showAlphaFeedbackFlow(
  BuildContext context,
  WidgetRef ref, {
  required String screenId,
  String? stableErrorCode,
  List<String> diagnosticLines = const [],
}) async {
  final draft = await showDialog<AlphaFeedbackDraft>(
    context: context,
    builder: (_) => _AlphaFeedbackDialog(
      screenId: screenId,
      stableErrorCode: stableErrorCode,
      diagnosticLines: diagnosticLines,
    ),
  );
  if (draft == null || !context.mounted) return;

  try {
    final saved = await ref.read(alphaFeedbackServiceProvider).submit(draft);
    if (!context.mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反馈未导出，本地事件未记录')),
      );
      return;
    }
    ref.invalidate(productEventListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('反馈已导出，可将该文件发送给私测负责人'),
        backgroundColor: AppColors.green,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('反馈导出失败: $error')),
    );
  }
}

class _AlphaFeedbackDialog extends StatefulWidget {
  final String screenId;
  final String? stableErrorCode;
  final List<String> diagnosticLines;

  const _AlphaFeedbackDialog({
    required this.screenId,
    required this.stableErrorCode,
    required this.diagnosticLines,
  });

  @override
  State<_AlphaFeedbackDialog> createState() => _AlphaFeedbackDialogState();
}

class _AlphaFeedbackDialogState extends State<_AlphaFeedbackDialog> {
  final TextEditingController _detailsController = TextEditingController();
  AlphaFeedbackCategory? _category;
  AlphaFeedbackSeverity _severity = AlphaFeedbackSeverity.medium;
  bool _diagnosticConsent = false;

  bool get _canSubmit =>
      _category != null && _detailsController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('提交 Private Alpha 反馈'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<AlphaFeedbackCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '反馈类型'),
              items: AlphaFeedbackCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AlphaFeedbackSeverity>(
              initialValue: _severity,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '严重程度'),
              items: AlphaFeedbackSeverity.values
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Text(severity.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _severity = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              minLines: 3,
              maxLines: 5,
              maxLength: AlphaFeedbackService.maxDetailsLength,
              decoration: const InputDecoration(
                labelText: '发生了什么？',
                hintText: '请描述预期、实际结果和你停下来的位置。不要填写 API Key 或源码。',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _diagnosticConsent,
              title: const Text('附加脱敏诊断'),
              subtitle: const Text(
                '包含版本、数据库计数、模型验收摘要和稳定错误信息；不包含 API Key、源码、回答或模型原文。',
              ),
              onChanged: (value) {
                setState(() => _diagnosticConsent = value ?? false);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _diagnosticConsent
                  ? '将导出：反馈类型、严重程度、当前页面、App/数据库版本、你的描述，以及脱敏诊断。'
                  : '将导出：反馈类型、严重程度、当前页面、App/数据库版本和你的描述。不会附加诊断。',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit
              ? () => Navigator.of(context).pop(
                    AlphaFeedbackDraft(
                      category: _category!,
                      severity: _severity,
                      screenId: widget.screenId,
                      details: _detailsController.text,
                      diagnosticConsent: _diagnosticConsent,
                      stableErrorCode: widget.stableErrorCode,
                      diagnosticLines: widget.diagnosticLines,
                    ),
                  )
              : null,
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('导出反馈'),
        ),
      ],
    );
  }
}
