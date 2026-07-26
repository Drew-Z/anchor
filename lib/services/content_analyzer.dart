import 'dart:convert';
import 'openai_service.dart';
import '../data/models/question.dart';

/// 分析结果
class AnalysisResult {
  final String title;
  final List<Question> questions;

  AnalysisResult({required this.title, required this.questions});
}

/// 内容拆解引擎 - 将用户输入的文本/图片转化为结构化题目
class ContentAnalyzer {
  final OpenAIService _openai;

  ContentAnalyzer(this._openai);

  static const String _systemPrompt =
      '''你是一个专业的教育内容分析专家。你的任务是分析用户提供的文本或图片内容，提取关键知识点，并生成多种类型的题目。

## 要求：
1. 仔细阅读/分析内容，提取 5-10 个核心知识点
2. 为每个知识点生成合适类型的题目
3. 题目类型要多样化：选择题、填空题、判断题、匹配题、排序题
4. 题目难度适中，能检验对内容的理解
5. 每道题都要有详细的解析说明

## 题型格式说明：

### 选择题 (multiple_choice)
- options: 4个选项 ["选项A", "选项B", "选项C", "选项D"]
- answer: 正确答案的文本，必须与options中的某一项完全一致
- 选项要有迷惑性但不能有歧义

### 填空题 (fill_blank)
- answer: 正确答案的文本
- content 中用 ___ 表示空缺处

### 判断题 (true_false)
- options: ["正确", "错误"]
- answer: "正确" 或 "错误"

### 匹配题 (matching)
- match_left: 左侧条目列表 ["条目1", "条目2", "条目3"]
- match_right: 右侧条目列表（顺序打乱）["匹配A", "匹配B", "匹配C"]
- answer: 正确匹配关系，格式 "条目1-匹配A|条目2-匹配B|条目3-匹配C"
- 左右两侧数量必须相等

### 排序题 (ordering)
- options: 打乱顺序的条目列表
- answer: 正确顺序，用 | 分隔，如 "第一步|第二步|第三步"

## 输出格式（严格 JSON）：
```json
{
  "title": "题包标题（简短概括内容主题）",
  "questions": [
    {
      "type": "multiple_choice",
      "content": "题干文本",
      "options": ["选项A", "选项B", "选项C", "选项D"],
      "answer": "选项B",
      "explanation": "解析说明"
    },
    {
      "type": "fill_blank",
      "content": "内容中的___是什么",
      "answer": "正确答案",
      "explanation": "解析说明"
    },
    {
      "type": "true_false",
      "content": "判断以下说法是否正确：...",
      "options": ["正确", "错误"],
      "answer": "正确",
      "explanation": "解析说明"
    },
    {
      "type": "matching",
      "content": "将左侧概念与右侧解释匹配",
      "match_left": ["概念1", "概念2"],
      "match_right": ["解释A", "解释B"],
      "answer": "概念1-解释A|概念2-解释B",
      "explanation": "解析说明"
    },
    {
      "type": "ordering",
      "content": "按正确顺序排列以下步骤",
      "options": ["步骤C", "步骤A", "步骤B"],
      "answer": "步骤A|步骤B|步骤C",
      "explanation": "解析说明"
    }
  ]
}
```

## 注意事项：
- title 要简洁有力，概括内容主题
- 至少生成 5 道题，最多 10 道
- 尽量包含至少 2 种题型
- 解析要清楚说明为什么这个答案是对的
- 如果内容是图片，仔细识别图片中的文字和图表信息
- 所有文本使用中文''';

  /// 分析内容并生成题目
  /// [text] - 用户输入的文本
  /// [imageBase64] - 可选的图片(base64编码)
  Future<AnalysisResult> analyze({
    required String text,
    String? imageBase64,
  }) async {
    final userContent = StringBuffer();
    userContent.writeln('请分析以下内容并生成题目：');
    userContent.writeln();
    if (text.isNotEmpty) {
      userContent.writeln('--- 文本内容 ---');
      userContent.writeln(text);
      userContent.writeln();
    }
    if (imageBase64 != null) {
      userContent.writeln('--- 图片内容 ---');
      userContent.writeln('请同时分析上方提供的图片，识别其中的文字和图表信息。');
    }

    final response = await _openai.chatCompletion(
      systemPrompt: _systemPrompt,
      userContent: userContent.toString(),
      imageBase64: imageBase64,
      temperature: 0.7,
    );

    return _parseResponse(response);
  }

  /// 解析 GPT 返回的 JSON
  AnalysisResult _parseResponse(String response) {
    // 尝试直接解析
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      // 尝试提取 JSON 块
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      } else {
        throw Exception('无法解析 AI 返回的内容: $response');
      }
    }

    final title = json['title'] as String? ?? '未命名题包';
    final questionsJson = json['questions'] as List<dynamic>? ?? [];

    final questions = <Question>[];
    for (final qJson in questionsJson) {
      try {
        final q = Question.fromJson(qJson as Map<String, dynamic>, '');
        questions.add(q);
      } catch (e) {
        // 跳过格式错误的题目
        continue;
      }
    }

    if (questions.isEmpty) {
      throw Exception('AI 未生成有效题目');
    }

    return AnalysisResult(title: title, questions: questions);
  }
}
