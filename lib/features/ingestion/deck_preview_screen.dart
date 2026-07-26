import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/question.dart';
import '../../data/models/question_type.dart';
import '../../services/content_analyzer.dart';
import '../../shared/widgets/duo_button.dart';

/// 题目预览页 — AI 生成后让用户预览，确认后保存
class DeckPreviewScreen extends ConsumerStatefulWidget {
  final AnalysisResult result;
  final String? sourceText;
  final String? sourceImage;

  const DeckPreviewScreen({
    super.key,
    required this.result,
    this.sourceText,
    this.sourceImage,
  });

  @override
  ConsumerState<DeckPreviewScreen> createState() => _DeckPreviewScreenState();
}

class _DeckPreviewScreenState extends ConsumerState<DeckPreviewScreen> {
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(deckOperationsProvider).saveAnalysisResult(
            widget.result,
            sourceText: widget.sourceText,
            sourceImage: widget.sourceImage,
          );
      if (mounted) {
        // 提示保存成功，返回首页
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('题包已保存'),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('题目预览'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 题包标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.greenLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI 已生成 ${widget.result.questions.length} 道题，预览确认后保存',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.sourceImage != null) ...[
                  const SizedBox(height: 10),
                  const _SourceWarningBlock(),
                ],
              ],
            ),
          ),
          // 题目列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.result.questions.length,
              itemBuilder: (context, index) {
                return _QuestionPreviewCard(
                  question: widget.result.questions[index],
                  index: index + 1,
                ).animate().fadeIn(
                      duration: 200.ms,
                      delay: (index * 50).ms,
                    );
              },
            ),
          ),
          // 保存按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: SafeArea(
              child: DuoButton(
                label: _isSaving ? '保存中...' : '保存题包',
                color: AppColors.green,
                width: double.infinity,
                height: 56,
                icon: Icons.check,
                fontSize: 18,
                enabled: !_isSaving,
                onPressed: _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceWarningBlock extends StatelessWidget {
  const _SourceWarningBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.goldDark, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '图片导入暂未进入来源核验流程，保存后题目会标记为无来源，不会进入正式练习。',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单题预览卡片
class _QuestionPreviewCard extends StatelessWidget {
  final Question question;
  final int index;

  const _QuestionPreviewCard({
    required this.question,
    required this.index,
  });

  List<_MatchPair> _matchingPreviewPairs() {
    final answerPairs = <String, String>{};
    for (final pair in question.answer.split('|')) {
      final separatorIndex = pair.indexOf('-');
      if (separatorIndex <= 0) continue;

      final left = pair.substring(0, separatorIndex).trim();
      final right = pair.substring(separatorIndex + 1).trim();
      if (left.isNotEmpty && right.isNotEmpty) {
        answerPairs[left] = right;
      }
    }

    final leftItems = question.matchLeft ?? [];
    final result = <_MatchPair>[];
    for (final left in leftItems) {
      final right = answerPairs[left.trim()];
      if (right != null) {
        result.add(_MatchPair(left, right));
      }
    }

    if (result.isNotEmpty) return result;

    final rightItems = question.matchRight ?? [];
    return List.generate(
      leftItems.length < rightItems.length
          ? leftItems.length
          : rightItems.length,
      (i) => _MatchPair(leftItems[i], rightItems[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchingPairs = _matchingPreviewPairs();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：序号 + 题型
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.type.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 题干
          Text(
            question.content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // 选项（选择题/判断题/排序题）
          if (question.options.isNotEmpty &&
              question.type != QuestionType.ordering) ...[
            ...question.options.map((option) {
              final isAnswer = option == question.answer;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAnswer ? AppColors.greenLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAnswer ? AppColors.green : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAnswer ? Icons.check_circle : Icons.circle_outlined,
                      color: isAnswer ? AppColors.green : AppColors.textLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isAnswer ? FontWeight.w700 : FontWeight.w500,
                          color: isAnswer
                              ? AppColors.greenDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // 填空题答案
          if (question.options.isEmpty &&
              question.type == QuestionType.fillBlank) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '答案: ${question.answer}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 匹配题
          if (question.type == QuestionType.matching &&
              question.matchLeft != null &&
              question.matchRight != null) ...[
            ...matchingPairs.map((pair) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        pair.left,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: AppColors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        pair.right,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // 排序题
          if (question.type == QuestionType.ordering) ...[
            ...question.answer.split('|').asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // 解析
          if (question.explanation != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, size: 16, color: AppColors.blue),
                      SizedBox(width: 4),
                      Text(
                        '解析',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.explanation!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchPair {
  final String left;
  final String right;

  const _MatchPair(this.left, this.right);
}
