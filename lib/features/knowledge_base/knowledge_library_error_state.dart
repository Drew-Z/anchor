import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../services/privacy/privacy_redactor.dart';
import '../../shared/widgets/alpha_feedback_action.dart';

class KnowledgeLibraryErrorState extends StatelessWidget {
  final String title;
  final String retryLabel;
  final String diagnosticTitle;
  final String diagnosticSuccessMessage;
  final List<String> diagnosticLines;
  final Object error;
  final VoidCallback onRetry;
  final String feedbackScreenId;
  final String? stableErrorCode;

  const KnowledgeLibraryErrorState({
    super.key,
    required this.title,
    required this.retryLabel,
    required this.diagnosticTitle,
    required this.diagnosticSuccessMessage,
    this.diagnosticLines = const [],
    required this.error,
    required this.onRetry,
    this.feedbackScreenId = 'error_state',
    this.stableErrorCode = 'read_failure',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.red,
              size: 44,
            ),
            const SizedBox(height: 10),
            Text(
              '$title: ${const PrivacyRedactor().redactDiagnostic(error.toString())}',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(retryLabel),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyKnowledgeLibraryErrorDiagnostic(
                    context,
                    title: diagnosticTitle,
                    error: error,
                    successMessage: diagnosticSuccessMessage,
                    extraLines: diagnosticLines,
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制诊断'),
                ),
                AlphaFeedbackButton(
                  screenId: feedbackScreenId,
                  stableErrorCode: stableErrorCode,
                  diagnosticLines: [
                    '诊断标题: $diagnosticTitle',
                    ...diagnosticLines,
                    '错误: $error',
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _copyKnowledgeLibraryErrorDiagnostic(
  BuildContext context, {
  required String title,
  required Object error,
  required String successMessage,
  List<String> extraLines = const [],
}) async {
  final errorText =
      error.toString().trim().isEmpty ? '未记录错误' : error.toString().trim();
  final copiedAtText = _dateTimeText(DateTime.now());
  final text = const PrivacyRedactor().redactDiagnostic([
    '# $title',
    '',
    ...extraLines,
    '错误: $errorText',
    '复制时间: $copiedAtText',
  ].join('\n'));
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(successMessage)),
  );
}

String _dateText(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _dateTimeText(DateTime value) {
  return '${_dateText(value)} ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
