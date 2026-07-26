import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/question.dart';
import '../../../data/models/question_type.dart';

/// 选择题 Widget
class MultipleChoiceWidget extends StatefulWidget {
  final Question question;
  final bool showResult;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    this.showResult = false,
    this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedAnswer;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        final isSelected = _selected == option;
        final isCorrect = option == widget.question.answer;
        final showCorrect = widget.showResult && isCorrect;
        final showWrong = widget.showResult && isSelected && !isCorrect;

        Color borderColor = AppColors.border;
        Color bgColor = Colors.white;
        Color textColor = AppColors.textPrimary;
        Color? iconColor;

        if (isSelected && !widget.showResult) {
          borderColor = AppColors.blue;
          bgColor = AppColors.blueLight;
          textColor = AppColors.blueDark;
        }
        if (showCorrect) {
          borderColor = AppColors.green;
          bgColor = AppColors.greenLight;
          textColor = AppColors.greenDark;
          iconColor = AppColors.green;
        }
        if (showWrong) {
          borderColor = AppColors.red;
          bgColor = AppColors.redLight;
          textColor = AppColors.redDark;
          iconColor = AppColors.red;
        }

        final optionLetter = String.fromCharCode(65 + options.indexOf(option));

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: widget.showResult
                ? null
                : () {
                    setState(() => _selected = option);
                    widget.onAnswerSelected(option);
                  },
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: iconColor != null
                          ? Icon(
                              iconColor == AppColors.green
                                  ? Icons.check
                                  : Icons.close,
                              color: iconColor,
                              size: 20)
                          : Text(
                              optionLetter,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 填空题 Widget
class FillBlankWidget extends StatefulWidget {
  final Question question;
  final bool showResult;
  final ValueChanged<String> onAnswerChanged;

  const FillBlankWidget({
    super.key,
    required this.question,
    this.showResult = false,
    required this.onAnswerChanged,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 将题干中的 ___ 替换为输入框
    final parts = widget.question.content.split('___');
    final isCorrect = widget.showResult &&
        _controller.text.trim() == widget.question.answer.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(parts.length * 2 - 1, (index) {
            if (index.isEven) {
              return Text(
                parts[index ~/ 2],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              );
            } else {
              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _controller,
                  enabled: !widget.showResult,
                  onChanged: widget.onAnswerChanged,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: widget.showResult
                        ? (isCorrect ? AppColors.green : AppColors.red)
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '输入答案',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.showResult
                            ? (isCorrect ? AppColors.green : AppColors.red)
                            : AppColors.blue,
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.showResult
                            ? (isCorrect ? AppColors.green : AppColors.red)
                            : AppColors.blue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              );
            }
          }),
        ),
        if (widget.showResult && !isCorrect) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '正确答案: ${widget.question.answer}',
                    style: const TextStyle(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 判断题 Widget
class TrueFalseWidget extends StatefulWidget {
  final Question question;
  final bool showResult;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const TrueFalseWidget({
    super.key,
    required this.question,
    this.showResult = false,
    this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['正确', '错误'].map((option) {
        final isSelected = _selected == option;
        final isCorrect = option == widget.question.answer;
        final showCorrect = widget.showResult && isCorrect;
        final showWrong = widget.showResult && isSelected && !isCorrect;

        Color color = AppColors.blue;
        if (showCorrect) color = AppColors.green;
        if (showWrong) color = AppColors.red;
        if (!isSelected && !widget.showResult) color = AppColors.surface;

        Color textColor = AppColors.textSecondary;
        if (isSelected || showCorrect) textColor = Colors.white;
        if (showWrong) textColor = Colors.white;
        if (!isSelected && !widget.showResult)
          textColor = AppColors.textSecondary;

        Color borderColor = AppColors.border;
        if (isSelected && !widget.showResult) borderColor = AppColors.blue;
        if (showCorrect) borderColor = AppColors.green;
        if (showWrong) borderColor = AppColors.red;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: widget.showResult
                  ? null
                  : () {
                      setState(() => _selected = option);
                      widget.onAnswerSelected(option);
                    },
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      option == '正确' ? Icons.check : Icons.close,
                      size: 36,
                      color: textColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 匹配题 Widget
class MatchingWidget extends StatefulWidget {
  final Question question;
  final bool showResult;
  final ValueChanged<Map<String, String>> onMatchComplete;

  const MatchingWidget({
    super.key,
    required this.question,
    this.showResult = false,
    required this.onMatchComplete,
  });

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> {
  String? _selectedLeft;
  final Map<String, String> _matches = {};

  // 每对使用不同颜色，让用户直观看到配对关系
  static const List<Color> _pairBgColors = [
    Color(0xFFE3F2FD),
    Color(0xFFFCE4EC),
    Color(0xFFE8F5E9),
    Color(0xFFFFF8E1),
    Color(0xFFF3E5F5),
    Color(0xFFE0F7FA),
  ];
  static const List<Color> _pairBorderColors = [
    Color(0xFF1E88E5),
    Color(0xFFEC407A),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
  ];
  static const List<Color> _pairTextColors = [
    Color(0xFF0D47A1),
    Color(0xFFAD1457),
    Color(0xFF1B5E20),
    Color(0xFFE65100),
    Color(0xFF4A148C),
    Color(0xFF006064),
  ];

  int _getColorIndex(String leftItem) {
    final leftItems = widget.question.matchLeft ?? [];
    return leftItems.indexOf(leftItem) % _pairBgColors.length;
  }

  String? _getMatchedLeft(String rightItem) {
    for (final entry in _matches.entries) {
      if (entry.value == rightItem) return entry.key;
    }
    return null;
  }

  Map<String, String> get _correctMatches {
    final result = <String, String>{};
    for (final pair in widget.question.answer.split('|')) {
      final idx = pair.indexOf('-');
      if (idx > 0) {
        result[pair.substring(0, idx)] = pair.substring(idx + 1);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final leftItems = widget.question.matchLeft ?? [];
    final rightItems = widget.question.matchRight ?? [];
    final usedRights = _matches.values.toSet();
    final correct = _correctMatches;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧
        Expanded(
          child: Column(
            children: leftItems.map((item) {
              final matchedRight = _matches[item];
              final isMatched = matchedRight != null;
              final isSelected = _selectedLeft == item && !isMatched;
              final colorIndex = _getColorIndex(item);
              final isCorrect = widget.showResult &&
                  isMatched &&
                  correct[item] == matchedRight;
              final isWrong = widget.showResult &&
                  isMatched &&
                  correct[item] != matchedRight;

              Color bgColor = Colors.white;
              Color borderColor = AppColors.border;
              Color textColor = AppColors.textPrimary;
              Color? iconColor;

              if (isCorrect) {
                bgColor = AppColors.greenLight;
                borderColor = AppColors.green;
                textColor = AppColors.greenDark;
                iconColor = AppColors.green;
              } else if (isWrong) {
                bgColor = AppColors.redLight;
                borderColor = AppColors.red;
                textColor = AppColors.redDark;
                iconColor = AppColors.red;
              } else if (isMatched) {
                bgColor = _pairBgColors[colorIndex];
                borderColor = _pairBorderColors[colorIndex];
                textColor = _pairTextColors[colorIndex];
                iconColor = _pairBorderColors[colorIndex];
              } else if (isSelected) {
                bgColor = AppColors.blueLight;
                borderColor = AppColors.blue;
                textColor = AppColors.blueDark;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: widget.showResult
                      ? null
                      : () {
                          if (isMatched) {
                            // 点击已匹配项可取消配对
                            setState(() => _matches.remove(item));
                          } else {
                            setState(
                                () => _selectedLeft = isSelected ? null : item);
                          }
                        },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        if (isMatched) ...[
                          Icon(
                            widget.showResult
                                ? (isCorrect ? Icons.check : Icons.close)
                                : Icons.link,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        // 右侧
        Expanded(
          child: Column(
            children: rightItems.map((item) {
              final isUsed = usedRights.contains(item);
              final matchedLeft = _getMatchedLeft(item);
              final colorIndex =
                  matchedLeft != null ? _getColorIndex(matchedLeft) : 0;
              final isCorrect = widget.showResult &&
                  isUsed &&
                  matchedLeft != null &&
                  correct[matchedLeft] == item;
              final isWrong = widget.showResult &&
                  isUsed &&
                  matchedLeft != null &&
                  correct[matchedLeft] != item;

              Color bgColor = Colors.white;
              Color borderColor = AppColors.border;
              Color textColor = AppColors.textPrimary;
              Color? iconColor;

              if (isCorrect) {
                bgColor = AppColors.greenLight;
                borderColor = AppColors.green;
                textColor = AppColors.greenDark;
                iconColor = AppColors.green;
              } else if (isWrong) {
                bgColor = AppColors.redLight;
                borderColor = AppColors.red;
                textColor = AppColors.redDark;
                iconColor = AppColors.red;
              } else if (isUsed && matchedLeft != null) {
                bgColor = _pairBgColors[colorIndex];
                borderColor = _pairBorderColors[colorIndex];
                textColor = _pairTextColors[colorIndex];
                iconColor = _pairBorderColors[colorIndex];
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: widget.showResult || _selectedLeft == null || isUsed
                      ? null
                      : () {
                          setState(() {
                            _matches[_selectedLeft!] = item;
                            _selectedLeft = null;
                          });
                          if (_matches.length == leftItems.length) {
                            widget.onMatchComplete(_matches);
                          }
                        },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        if (isUsed) ...[
                          Icon(
                            widget.showResult
                                ? (isCorrect ? Icons.check : Icons.close)
                                : Icons.link,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 排序题 Widget
class OrderingWidget extends StatefulWidget {
  final Question question;
  final bool showResult;
  final ValueChanged<List<String>> onOrderChanged;

  const OrderingWidget({
    super.key,
    required this.question,
    this.showResult = false,
    required this.onOrderChanged,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.question.options);
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _items.removeAt(index);
        _items.insert(index - 1, item);
      });
      widget.onOrderChanged(_items);
    }
  }

  void _moveDown(int index) {
    if (index < _items.length - 1) {
      setState(() {
        final item = _items.removeAt(index);
        _items.insert(index + 1, item);
      });
      widget.onOrderChanged(_items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctOrder = widget.question.answer.split('|');

    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        final isCorrect = widget.showResult &&
            index < correctOrder.length &&
            item == correctOrder[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: widget.showResult
                  ? (isCorrect ? AppColors.greenLight : AppColors.redLight)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.showResult
                    ? (isCorrect ? AppColors.green : AppColors.red)
                    : AppColors.border,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.showResult
                        ? (isCorrect ? AppColors.green : AppColors.red)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: widget.showResult
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!widget.showResult) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    color: index > 0
                        ? AppColors.textSecondary
                        : AppColors.textLight,
                    onPressed: index > 0 ? () => _moveUp(index) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    color: index < _items.length - 1
                        ? AppColors.textSecondary
                        : AppColors.textLight,
                    onPressed: index < _items.length - 1
                        ? () => _moveDown(index)
                        : null,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// 根据题型渲染对应 Widget
class QuestionWidget extends StatelessWidget {
  final Question question;
  final bool showResult;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    this.showResult = false,
    this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(
          question: question,
          showResult: showResult,
          selectedAnswer: selectedAnswer,
          onAnswerSelected: onAnswerSelected,
        );
      case QuestionType.fillBlank:
        return FillBlankWidget(
          question: question,
          showResult: showResult,
          onAnswerChanged: onAnswerSelected,
        );
      case QuestionType.trueFalse:
        return TrueFalseWidget(
          question: question,
          showResult: showResult,
          selectedAnswer: selectedAnswer,
          onAnswerSelected: onAnswerSelected,
        );
      case QuestionType.matching:
        return MatchingWidget(
          question: question,
          showResult: showResult,
          onMatchComplete: (matches) {
            final answerStr =
                matches.entries.map((e) => '${e.key}-${e.value}').join('|');
            onAnswerSelected(answerStr);
          },
        );
      case QuestionType.ordering:
        return OrderingWidget(
          question: question,
          showResult: showResult,
          onOrderChanged: (items) {
            onAnswerSelected(items.join('|'));
          },
        );
    }
  }
}
