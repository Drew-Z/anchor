import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/question.dart';
import '../../data/models/source_chunk.dart';

/// 题目质量验证服务 - 防止 AI 生成事实性错误的题目
///
/// **为什么需要验证**:
/// AI 在生成题目时常见的三大问题:
/// 1. **编造数字**: "Flutter 有 7 个核心组件" (实际文档说 5 个)
/// 2. **瞎断言**: "Vue 不支持 TypeScript" (实际支持)
/// 3. **抄过时代码**: 从文档中抄了一段已废弃的 API 写法
///
/// **验证维度**:
/// 1. **事实准确性**: 题目中的关键词、数字、术语是否在原文中存在
/// 2. **引用完整性**: 正确答案是否有原文支撑
/// 3. **逻辑一致性**: 选项设计是否合理,排序是否符合原文顺序
///
/// **置信度评分** (0.0-1.0):
/// - **1.0**: 完全通过,无任何问题
/// - **0.7**: 发现 1 个小问题,可能需要人工复核
/// - **0.5**: 发现 2 个问题,建议人工复核
/// - **0.3**: 发现 3+ 个问题,强烈建议删除或重新生成
///
/// **使用示例**:
/// ```dart
/// final validator = QuestionValidator();
///
/// final result = await validator.validate(
///   question: question,
///   sourceChunks: relatedChunks,
/// );
///
/// if (result.needsManualReview) {
///   print('需要人工复核: ${result.issues.join(", ")}');
/// }
/// ```
///
/// **参考**: aicoding-cookbook/docs-to-book 的 quality-checks 策略
class QuestionValidator {
  /// 验证单个题目的事实准确性
  ///
  /// **验证流程**:
  /// 1. 根据题型调用对应的验证方法
  /// 2. 收集所有发现的问题
  /// 3. 计算置信度分数
  ///
  /// **参数**:
  /// - [question]: 待验证的题目
  /// - [sourceChunks]: 题目对应的原文片段(用于回源验证)
  ///
  /// **返回**: QuestionValidationResult 包含:
  /// - `isValid`: 是否通过验证
  /// - `issues`: 发现的问题列表
  /// - `confidence`: 置信度(0-1)
  Future<QuestionValidationResult> validate({
    required Question question,
    required List<SourceChunk> sourceChunks,
  }) async {
    final issues = <String>[];

    switch (question.type) {
      case QuestionType.multipleChoice:
        issues.addAll(await _validateMultipleChoice(question, sourceChunks));
        break;

      case QuestionType.fillInBlank:
        issues.addAll(await _validateFillInBlank(question, sourceChunks));
        break;

      case QuestionType.trueFalse:
        issues.addAll(await _validateTrueFalse(question, sourceChunks));
        break;

      case QuestionType.matching:
        issues.addAll(await _validateMatching(question, sourceChunks));
        break;

      case QuestionType.ordering:
        issues.addAll(await _validateOrdering(question, sourceChunks));
        break;
    }

    return QuestionValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      confidence: _calculateConfidence(issues.length),
    );
  }

  /// 批量验证题目
  ///
  /// **适用场景**: 一次性验证导入流程生成的所有题目
  ///
  /// **参数**:
  /// - [questions]: 待验证的题目列表
  /// - [sourceChunks]: 对应的原文片段
  ///
  /// **返回**: Map<题目ID, 验证结果>
  Future<Map<String, QuestionValidationResult>> validateBatch({
    required List<Question> questions,
    required List<SourceChunk> sourceChunks,
  }) async {
    final results = <String, QuestionValidationResult>{};

    for (final question in questions) {
      final result = await validate(
        question: question,
        sourceChunks: sourceChunks,
      );
      results[question.id] = result;
    }

    return results;
  }

  /// 验证选择题
  ///
  /// **检查点**:
  /// 1. 题干关键词是否在原文中(防止 AI 凭空创造问题)
  /// 2. 选项中的数字/术语是否在原文中(AI 最容易编造数字)
  /// 3. 正确答案是否有原文明确支撑
  ///
  /// **常见问题示例**:
  /// - 题干: "Flutter 有几个核心 Widget?" (原文根本没提数量)
  /// - 选项: "7个" (AI 编造的数字,原文是 5 个)
  Future<List<String>> _validateMultipleChoice(
    Question question,
    List<SourceChunk> chunks,
  ) async {
    final issues = <String>[];
    final allContent = chunks.map((c) => c.content).join('\n\n');

    // 检查题干中的关键词是否在原文中
    final stemKeywords = _extractKeywords(question.content);
    for (final keyword in stemKeywords) {
      if (!allContent.contains(keyword)) {
        issues.add('题干关键词 "$keyword" 未在原文找到');
      }
    }

    // 检查每个选项
    for (int i = 0; i < question.options.length; i++) {
      final option = question.options[i];
      final isCorrect = option == question.answer;

      // 检查选项中的数字(AI 最容易编造数字)
      final numbers = _extractNumbers(option);
      for (final number in numbers) {
        if (!allContent.contains(number)) {
          issues.add(
            '选项 ${i + 1} 中的数字/术语 "$number" 在原文中不存在(可能是 AI 编造的)',
          );
        }
      }

      // 检查正确答案是否有原文支撑
      if (isCorrect) {
        final answerKeywords = _extractKeywords(option);
        bool foundSupport = false;
        for (final chunk in chunks) {
          if (answerKeywords.every((kw) => chunk.content.contains(kw))) {
            foundSupport = true;
            break;
          }
        }
        if (!foundSupport) {
          issues.add('正确答案 "$option" 在原文中找不到明确支撑');
        }
      }
    }

    return issues;
  }

  /// 验证填空题
  ///
  /// **检查点**:
  /// 1. 答案必须在原文中逐字出现(填空题答案不容模糊)
  /// 2. 题干中的代码片段必须来自原文(防止 AI 抄过时代码)
  ///
  /// **常见问题示例**:
  /// - 答案: "StatefulWidget" (原文中是 "StatelessWidget")
  /// - 题干包含代码: `setState(() {})` (但原文已改用 hooks)
  Future<List<String>> _validateFillInBlank(
    Question question,
    List<SourceChunk> chunks,
  ) async {
    final issues = <String>[];
    final allContent = chunks.map((c) => c.content).join('\n\n');

    // 填空题的答案必须在原文中出现
    final answer = question.answer.trim();
    if (answer.isEmpty) {
      issues.add('填空题答案为空');
      return issues;
    }

    // 检查答案是否在原文中
    if (!allContent.contains(answer)) {
      // 尝试模糊匹配(去除空格、标点)
      final normalizedAnswer = _normalize(answer);
      final normalizedContent = _normalize(allContent);

      if (!normalizedContent.contains(normalizedAnswer)) {
        issues.add('填空题答案 "$answer" 在原文中不存在');
      }
    }

    // 检查题干中的代码片段是否来自原文
    if (question.content.contains('```') || question.content.contains('`')) {
      final codeSnippets = _extractCodeSnippets(question.content);
      for (final snippet in codeSnippets) {
        if (!allContent.contains(snippet) && snippet.length > 10) {
          issues.add('题干中的代码片段不在原文中(可能是 AI 从文档抄的过时版本)');
        }
      }
    }

    return issues;
  }

  /// 验证判断题
  ///
  /// **检查点**:
  /// 1. 陈述的关键词在原文中的匹配率(要求 ≥ 70%)
  /// 2. 警惕否定性陈述(AI 容易瞎断言 "不支持"、"无法")
  ///
  /// **常见问题示例**:
  /// - "Vue 不支持 TypeScript" (实际支持,AI 瞎断言)
  /// - "Flutter 无法进行热重载" (实际可以,AI 理解错误)
  Future<List<String>> _validateTrueFalse(
    Question question,
    List<SourceChunk> chunks,
  ) async {
    final issues = <String>[];
    final allContent = chunks.map((c) => c.content).join('\n\n');

    // 判断题的陈述必须在原文中找到对应段落
    final statement = question.content.trim();
    final keywords = _extractKeywords(statement);

    // 至少 70% 的关键词要在原文中
    int foundCount = 0;
    for (final keyword in keywords) {
      if (allContent.contains(keyword)) {
        foundCount++;
      }
    }

    final matchRate = keywords.isEmpty ? 0.0 : foundCount / keywords.length;
    if (matchRate < 0.7) {
      issues.add('判断题陈述的关键词在原文中匹配率过低(${(matchRate * 100).toStringAsFixed(0)}%)');
    }

    // 检查否定性陈述(AI 容易瞎断言 "无 X" / "不支持 Y")
    final negativePatterns = [
      '不支持',
      '无法',
      '没有',
      '不能',
      '不会',
      '不是',
      '不存在',
    ];

    for (final pattern in negativePatterns) {
      if (statement.contains(pattern)) {
        issues.add(
          '判断题包含否定性陈述 "$pattern",需人工复核(AI 容易瞎断言)',
        );
        break;
      }
    }

    return issues;
  }

  /// 验证匹配题
  ///
  /// **检查点**:
  /// 1. 左右两侧的所有条目都必须在原文中
  /// 2. 匹配关系必须在原文中有依据(同时出现在同一 chunk 中)
  ///
  /// **示例**: "Widget - UI组件" 这对匹配,要求原文同一段落中
  /// 既提到 Widget 又提到 UI组件,且说明了它们的关系
  Future<List<String>> _validateMatching(
    Question question,
    List<SourceChunk> chunks,
  ) async {
    final issues = <String>[];
    final allContent = chunks.map((c) => c.content).join('\n\n');

    // 检查左右两侧的条目是否在原文中
    final leftItems = question.matchLeft ?? [];
    final rightItems = question.matchRight ?? [];

    for (final item in [...leftItems, ...rightItems]) {
      if (!allContent.contains(item)) {
        issues.add('匹配项 "$item" 在原文中不存在');
      }
    }

    // 检查匹配关系是否在原文中有依据
    final pairs = _parseMatchingAnswer(question.answer);
    for (final pair in pairs) {
      // 查找同时包含左右两项的 chunk(说明它们有关联)
      bool foundRelation = false;
      for (final chunk in chunks) {
        if (chunk.content.contains(pair.left) &&
            chunk.content.contains(pair.right)) {
          foundRelation = true;
          break;
        }
      }
      if (!foundRelation) {
        issues.add('匹配关系 "${pair.left} - ${pair.right}" 在原文中找不到依据');
      }
    }

    return issues;
  }

  /// 验证排序题
  ///
  /// **检查点**:
  /// 1. 每个步骤都必须在原文中
  /// 2. 排序顺序应与原文中的出现顺序一致
  ///
  /// **示例**: "安装 → 配置 → 运行" 的排序,要求原文中
  /// 这三个词的出现位置也是这个顺序
  Future<List<String>> _validateOrdering(
    Question question,
    List<SourceChunk> chunks,
  ) async {
    final issues = <String>[];
    final allContent = chunks.map((c) => c.content).join('\n\n');

    // 检查每个步骤是否在原文中
    final steps = question.answer.split('|');
    for (final step in steps) {
      if (!allContent.contains(step.trim())) {
        issues.add('排序步骤 "$step" 在原文中不存在');
      }
    }

    // 检查顺序是否符合原文(简单策略:检查在原文中的出现顺序)
    final stepPositions = <int>[];
    for (final step in steps) {
      final pos = allContent.indexOf(step.trim());
      if (pos >= 0) {
        stepPositions.add(pos);
      }
    }

    if (stepPositions.length == steps.length) {
      // 检查是否递增(说明顺序与原文一致)
      bool isOrdered = true;
      for (int i = 1; i < stepPositions.length; i++) {
        if (stepPositions[i] < stepPositions[i - 1]) {
          isOrdered = false;
          break;
        }
      }
      if (!isOrdered) {
        issues.add('排序题的步骤顺序与原文中的出现顺序不一致,需人工复核');
      }
    }

    return issues;
  }

  /// 提取关键词(去除停用词)
  List<String> _extractKeywords(String text) {
    final stopWords = {
      '的', '了', '在', '是', '和', '与', '或', '等', '如', '但',
      '可以', '能够', '需要', '要求', '必须', '应该', '可能',
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    };

    return text
        .split(RegExp(r'[\s,。,;;\.:?!?、\[\]()（）《》「」]'))
        .where((word) => word.length > 1 && !stopWords.contains(word.toLowerCase()))
        .toList();
  }

  /// 提取数字和专有名词(首字母大写的词)
  List<String> _extractNumbers(String text) {
    final numbers = <String>[];

    // 提取数字(含单位)
    final numberMatches = RegExp(r'\d+(\.\d+)?[%kKmMgGtTbB]*').allMatches(text);
    numbers.addAll(numberMatches.map((m) => m.group(0)!));

    // 提取专有名词(连续大写字母或首字母大写的词)
    final properNouns = RegExp(r'\b[A-Z][a-z]+\b|\b[A-Z]{2,}\b').allMatches(text);
    numbers.addAll(properNouns.map((m) => m.group(0)!));

    return numbers.toSet().toList();
  }

  /// 提取代码片段
  List<String> _extractCodeSnippets(String text) {
    final snippets = <String>[];

    // 提取反引号包裹的代码
    final inlineCode = RegExp(r'`([^`]+)`').allMatches(text);
    snippets.addAll(inlineCode.map((m) => m.group(1)!.trim()));

    // 提取代码块
    final codeBlocks = RegExp(r'```[\s\S]*?```').allMatches(text);
    for (final match in codeBlocks) {
      final block = match.group(0)!;
      final code = block
          .replaceAll(RegExp(r'^```\w*\n'), '')
          .replaceAll(RegExp(r'\n```$'), '')
          .trim();
      if (code.isNotEmpty) {
        snippets.add(code);
      }
    }

    return snippets;
  }

  /// 规范化文本(去除空格、标点,便于模糊匹配)
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_.,;:!?，。、；：！？]'), '');
  }

  /// 解析匹配题答案
  List<_MatchPair> _parseMatchingAnswer(String answer) {
    final pairs = <_MatchPair>[];
    for (final pair in answer.split('|')) {
      final parts = pair.split('-');
      if (parts.length == 2) {
        pairs.add(_MatchPair(
          left: parts[0].trim(),
          right: parts[1].trim(),
        ));
      }
    }
    return pairs;
  }

  /// 计算置信度(0-1)
  double _calculateConfidence(int issueCount) {
    if (issueCount == 0) return 1.0;
    if (issueCount == 1) return 0.7;
    if (issueCount == 2) return 0.5;
    return 0.3;
  }
}

/// 题目验证结果
///
/// **字段说明**:
/// - [isValid]: 是否通过验证(无任何问题)
/// - [issues]: 发现的具体问题列表
/// - [confidence]: 置信度评分 (0.0-1.0)
///   - 1.0: 完全通过
///   - 0.7: 1个问题
///   - 0.5: 2个问题
///   - 0.3: 3+问题
/// - [needsManualReview]: 是否需要人工复核(派生属性)
class QuestionValidationResult {
  final bool isValid;
  final List<String> issues;
  final double confidence; // 0-1,越高越可信

  QuestionValidationResult({
    required this.isValid,
    required this.issues,
    required this.confidence,
  });

  bool get needsManualReview => !isValid || confidence < 0.7;
}

/// 匹配对
class _MatchPair {
  final String left;
  final String right;

  _MatchPair({required this.left, required this.right});
}
