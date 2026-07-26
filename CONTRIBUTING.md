# 贡献指南

感谢你考虑为**多多学习**项目做出贡献! 🎉

本指南将帮助你快速上手开发流程。

---

## 🌟 贡献方式

你可以通过以下方式参与:

- 🐛 **报告 Bug** - 发现问题请创建 Issue
- 💡 **提出功能建议** - 分享你的想法
- 📝 **改进文档** - 修正错误或补充说明
- 💻 **提交代码** - 修复 Bug 或实现新功能
- 🌍 **翻译** - 帮助项目支持更多语言
- 🎨 **设计改进** - 优化 UI/UX

---

## 🚀 快速开始

### 1. Fork 并克隆项目

```bash
# Fork 项目到你的 GitHub 账户
# 然后克隆到本地
git clone https://github.com/your-username/duoduo.git
cd duoduo

# 添加上游仓库
git remote add upstream https://github.com/xuanli199/duoduo.git
```

### 2. 安装开发环境

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test

# 启动应用
flutter run
```

### 3. 创建分支

```bash
# 从 main 分支创建功能分支
git checkout -b feature/your-feature-name

# 或修复分支
git checkout -b fix/bug-description
```

### 4. 开发和测试

- 编写代码
- 添加测试(如果适用)
- 确保所有测试通过: `flutter test`
- 检查代码格式: `flutter analyze`

### 5. 提交代码

```bash
# 暂存修改
git add .

# 提交(遵循 Commit 规范,见下文)
git commit -m "feat: add new feature"

# 推送到你的 Fork
git push origin feature/your-feature-name
```

### 6. 创建 Pull Request

1. 访问你 Fork 的仓库页面
2. 点击 **"New Pull Request"**
3. 填写 PR 描述(使用模板)
4. 等待代码审查

---

## 📝 Commit 规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式(不影响功能)
- `refactor`: 重构(不新增功能,不修复 Bug)
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建流程、依赖更新等

### 示例

```bash
# 新功能
git commit -m "feat: add PDF import support"

# Bug 修复
git commit -m "fix: correct answer validation in fill-in questions"

# 文档
git commit -m "docs: update QUICK_START guide with screenshots"

# 重构
git commit -m "refactor: extract AI task base class"
```

---

## 🧪 测试要求

### 必须编写测试的情况

- ✅ 新增核心业务逻辑(如 AI 任务、题目验证)
- ✅ 修复 Bug(添加回归测试)
- ✅ 数据模型变更

### 测试类型

```dart
// 单元测试 - test/unit/
test('QuestionValidator should reject questions without source', () {
  final validator = QuestionValidator();
  final result = validator.validate(invalidQuestion);
  expect(result.isValid, false);
});

// Widget 测试 - test/widgets/
testWidgets('QuizScreen displays question text', (tester) async {
  await tester.pumpWidget(QuizScreen(question: mockQuestion));
  expect(find.text(mockQuestion.questionText), findsOneWidget);
});

// 集成测试 - integration_test/
testWidgets('Full import workflow', (tester) async {
  // 测试完整的导入流程
});
```

### 运行测试

```bash
# 所有单元测试
flutter test

# 特定文件
flutter test test/services/content_analyzer_test.dart

# 带覆盖率
flutter test --coverage
```

---

## 📂 项目结构

```
lib/
├── core/               # 核心配置和工具
│   ├── constants/      # 常量定义
│   ├── providers/      # Riverpod 提供者
│   └── theme/          # 主题配置
├── data/               # 数据层
│   ├── database/       # SQLite 数据库
│   ├── models/         # 数据模型
│   └── repositories/   # 数据仓库
├── features/           # 功能模块
│   ├── home/           # 首页
│   ├── ingestion/      # 内容导入
│   ├── learning/       # 学习功能
│   ├── knowledge_base/ # 知识库
│   └── agent/          # AI Agent
└── services/           # 业务服务
    ├── ai/             # AI 相关
    │   └── tasks/      # AI 任务定义
    ├── openai_service.dart
    └── content_analyzer.dart

test/
├── unit/               # 单元测试
├── widgets/            # Widget 测试
└── fixtures/           # 测试数据

docs/
├── guides/             # 用户指南
├── architecture/       # 架构文档
└── images/             # 图片资源
```

---

## 🎯 寻找合适的任务

### Good First Issues

适合新手贡献者的任务标记为 `good first issue`:

- [ ] 添加更多题型(如匹配题、排序题)
- [ ] 改进 Markdown 代码块解析
- [ ] 为核心服务补充单元测试
- [ ] 添加多语言支持(i18n)

### Help Wanted

需要帮助的任务标记为 `help wanted`:

- [ ] PDF 文档导入支持
- [ ] 支持本地 LLM(Ollama, LM Studio)
- [ ] 知识图谱可视化
- [ ] 离线模式优化

查看所有 Issue: https://github.com/xuanli199/duoduo/issues

---

## 🎨 代码风格

### Dart 代码规范

我们遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 规范:

```dart
// ✅ 好的命名
class QuestionGenerator {
  Future<List<Question>> generateFromKnowledge(KnowledgePoint point) async {
    // ...
  }
}

// ❌ 避免
class QGen {
  Future<List<Question>> gen(KnowledgePoint kp) async {
    // ...
  }
}
```

### 文件命名

- 使用小写 + 下划线: `question_generator.dart`
- 测试文件加 `_test` 后缀: `question_generator_test.dart`
- 模型类使用单数: `question.dart` 而非 `questions.dart`

### 注释规范

```dart
/// 从知识点生成练习题
///
/// [knowledgePoint] 必须包含有效的 sourceText
/// 返回生成的题目列表,如果失败返回空列表
///
/// 示例:
/// ```dart
/// final questions = await generator.generate(knowledgePoint);
/// ```
Future<List<Question>> generate(KnowledgePoint knowledgePoint) async {
  // 实现逻辑...
}
```

---

## 🔍 Code Review 流程

### PR 会检查以下内容

- ✅ 代码功能是否符合描述
- ✅ 测试是否充分
- ✅ 是否遵循代码规范
- ✅ 性能是否合理
- ✅ 文档是否更新

### 如何响应审查意见

1. **认真阅读**审查意见
2. **讨论**不清楚的地方
3. **修改**代码并推送
4. **回复**每条评论(即使只是"已修复")

```bash
# 修改后推送
git add .
git commit -m "refactor: address review comments"
git push origin feature/your-feature-name
```

---

## 📚 开发资源

### 必读文档

- [系统架构](docs/architecture/SYSTEM_OVERVIEW.md) - 理解核心设计
- [数据模型](docs/architecture/DATA_MODEL.md) - 了解数据结构
- [AI Pipeline](docs/architecture/AI_PIPELINE.md) - AI 任务流程

### 技术栈文档

- [Flutter](https://docs.flutter.dev/)
- [Riverpod](https://riverpod.dev/)
- [SQLite](https://www.sqlite.org/docs.html)
- [OpenAI API](https://platform.openai.com/docs/api-reference)

---

## 🐛 报告 Bug

### 创建有效的 Bug 报告

使用 [Bug Report 模板](https://github.com/xuanli199/duoduo/issues/new?template=bug_report.md),包含:

1. **Bug 描述**: 简洁明了地说明问题
2. **复现步骤**:
   ```
   1. 打开应用
   2. 导入文档 X
   3. 点击"开始学习"
   4. 看到错误 Y
   ```
3. **期望行为**: 应该发生什么
4. **实际行为**: 实际发生了什么
5. **环境信息**:
   - Flutter 版本: `flutter --version`
   - 操作系统: Windows 11 / macOS 14 / Android 13
   - 设备型号: iPhone 15 / Pixel 8

6. **截图/日志**(如果适用)

---

## 💡 提出新功能

### 使用 Feature Request 模板

使用 [Feature Request 模板](https://github.com/xuanli199/duoduo/issues/new?template=feature_request.md),说明:

1. **问题陈述**: 你遇到了什么问题?
2. **建议方案**: 你希望如何解决?
3. **替代方案**: 还有其他可能的方案吗?
4. **使用场景**: 举例说明使用场景

### 讨论新功能

在实现前,建议先在 [Discussions](https://github.com/xuanli199/duoduo/discussions) 讨论:

- 功能是否符合项目方向?
- 实现复杂度如何?
- 有无更简单的方案?

---

## 🌍 翻译贡献

### 当前支持的语言

- 简体中文 (zh-CN) ✅
- English (en-US) 🚧

### 添加新语言

1. 复制 `lib/l10n/app_zh.arb` 为 `app_<locale>.arb`
2. 翻译所有字符串
3. 更新 `lib/l10n.yaml`
4. 运行 `flutter gen-l10n`
5. 提交 PR

---

## 📜 许可协议

通过贡献代码,你同意你的贡献将按照 [MIT License](LICENSE) 授权。

---

## 🙏 感谢

每一个贡献,无论大小,都让这个项目变得更好! ❤️

你的名字将出现在 [Contributors](https://github.com/xuanli199/duoduo/graphs/contributors) 列表中。

---

## 📞 需要帮助?

- 💬 在 [Discussions](https://github.com/xuanli199/duoduo/discussions) 提问
- 📧 发送邮件至 your-email@example.com
- 🐛 对于 Bug,请创建 Issue

祝你编码愉快! 🚀
