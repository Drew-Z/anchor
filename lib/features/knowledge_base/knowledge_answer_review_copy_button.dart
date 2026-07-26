import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/agent/knowledge_answer_session_summary.dart';

class KnowledgeAnswerReviewCopyButton extends StatelessWidget {
  final KnowledgeAnswerSessionSummaryRecord record;
  final String completedText;
  final String? recordStatusText;
  final List<String> citationContextLines;
  final double iconSize;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final String tooltip;
  final String successMessage;

  const KnowledgeAnswerReviewCopyButton({
    super.key,
    required this.record,
    required this.completedText,
    this.recordStatusText,
    this.citationContextLines = const [],
    this.iconSize = 20,
    this.color,
    this.padding,
    this.constraints,
    this.tooltip = '复制含证据状态的复盘',
    this.successMessage = '已复制问答复盘，包含证据状态',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _copyReviewText(context),
      icon: Icon(Icons.copy_all, size: iconSize),
      color: color,
      padding: padding,
      constraints: constraints,
    );
  }

  Future<void> _copyReviewText(BuildContext context) async {
    final text = buildKnowledgeAnswerReviewText(
      record,
      completedText: completedText,
      recordStatusText: recordStatusText,
      citationContextLines: citationContextLines,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }
}
