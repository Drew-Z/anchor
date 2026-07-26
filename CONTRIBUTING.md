# 贡献指南

感谢你考虑为多多学习做出贡献! 🎉

本文档将帮助你了解如何参与项目开发。

---

## 行为准则

在参与本项目时,请遵守以下原则:

- ✅ 尊重所有贡献者
- ✅ 接受建设性批评
- ✅ 专注于对社区最有利的事情
- ❌ 不使用性化语言或图像
- ❌ 不进行人身攻击或挑衅

---

## 如何贡献?

### 🐛 报告 Bug

发现问题? 请[创建 Issue](https://github.com/你的用户名/duoduo/issues/new?template=bug_report.md)

**好的 Bug 报告包含**:
- 清晰的标题(如 "导入 Markdown 时应用崩溃")
- 复现步骤(1. 点击... 2. 选择... 3. 崩溃)
- 预期行为 vs 实际行为
- 截图或错误日志
- 环境信息(Flutter 版本, 操作系统)

### 💡 提出新功能

有好点子? 请[创建 Feature Request](https://github.com/你的用户名/duoduo/issues/new?template=feature_request.md)

**好的功能建议包含**:
- 问题描述: 当前缺少什么?
- 解决方案: 你建议如何实现?
- 使用场景: 谁会用?怎么用?
- 可选方案: 还有其他做法吗?

### 📝 改进文档

文档永远可以更好!

- 修正错别字
- 补充遗漏的步骤
- 添加更多示例
- 翻译成其他语言

直接编辑 `docs/` 目录下的文件,提交 PR。

### 💻 贡献代码

参见下方的[开发流程](#开发流程)。

---

## 开发流程

### 1. Fork 并 Clone

```bash
# Fork 本仓库(点击右上角 Fork 按钮)

# Clone 你的 Fork
git clone https://github.com/你的用户名/duoduo.git
cd duoduo

# 添加上游仓库
git remote add upstream https://github.com/原作者/duoduo.git
```

### 2. 创建分支

```bash
# 同步最新代码
git fetch upstream
git checkout main
git merge upstream/main

# 创建功能分支
git checkout -b feature/your-feature-name
# 或修复分支
git checkout -b fix/bug-description
```

**分支命名规范**:
- `feature/` - 新功能
- `fix/` - Bug 修复
- `docs/` - 文档改进
- `refactor/` - 重构
- `test/` - 测试

### 3. 开发

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run

# 运行测试
flutter test
```

### 4. 提交代码

**Commit Message 规范**:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型(type)**:
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档
- `style`: 格式(不影响代码运行)
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

**示例**:

```bash
git commit -m "feat(ingestion): add PDF import support"

git commit -m "fix(quiz): fill-blank answer validation logic

修复填空题在用户答案包含空格时判断错误的问题。

Closes #123"
```

### 5. 推送并创建 PR

```bash
# 推送到你的 Fork
git push origin feature/your-feature-name
```

然后访问 GitHub,点击 "Create Pull Request"。

**PR 描述模板**:

```markdown
## 变更说明

简述本 PR 做了什么。

## 变更类型

- [ ] Bug 修复
- [ ] 新功能
- [ ] 重构
- [ ] 文档改进

## 测试

- [ ] 添加了单元测试
- [ ] 手动测试通过
- [ ] 所有现有测试通过

## 截图(如适用)

[粘贴截图]

## 关联 Issue

Closes #123
```

---

## 代码规范

### Dart 代码风格

遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart)。

**关键点**:
- 使用 `lowerCamelCase` 命名变量和方法
- 使用 `UpperCamelCase` 命名类和枚举
- 使用 `lowercase_with_underscores` 命名文件
- 公开 API 必须有文档注释

**示例**:

```dart
/// 语义切分服务,将文档切分为可引用的最小单元。
///
/// 支持:
/// - Markdown: 按标题层级切分
/// - 代码: 按固定行数切分
class SemanticChunker {
  /// 切分 Markdown 文档。
  ///
  /// [markdown] 原始 Markdown 文本
  /// [baseLocator] 文件路径或标识符
  /// 
  /// 返回切分后的 [SourceChunk] 列表。
  List<SourceChunk> chunkMarkdown({
    required String sourceId,
    required String markdown,
    required DateTime createdAt,
    required String baseLocator,
  }) {
    // 实现...
  }
}
```

### 运行 Linter

```bash
# 分析代码
flutter analyze

# 格式化
flutter format lib/ test/
```

### 项目结构约定

```
lib/
├── core/               # 核心基础设施
│   ├── constants/      # 常量
│   ├── providers/      # Riverpod Providers
│   └── theme/          # 主题配置
├── data/               # 数据层
│   ├── database/       # SQLite
│   ├── models/         # 数据模型
│   └── repositories/   # 数据访问
├── features/           # 功能模块
│   ├── home/           # 主页
│   ├── quiz/           # 答题
│   └── ...
├── services/           # 业务逻辑
│   ├── ai/             # AI Tasks
│   ├── ingestion/      # 导入服务
│   └── ...
└── shared/             # 共享组件
    └── widgets/
```

**命名规范**:
- Screen: `xxx_screen.dart`
- Widget: `xxx_widget.dart`
- Service: `xxx_service.dart`
- Repository: `xxx_repository.dart`
- Model: `xxx.dart` (如 `question.dart`)

---

## 测试要求

### 为新功能添加测试

```dart
// test/services/semantic_chunker_test.dart
void main() {
  group('SemanticChunker', () {
    late SemanticChunker chunker;

    setUp(() {
      chunker = const SemanticChunker();
    });

    test('按标题切分 Markdown', () {
      final markdown = '''
# 标题1
内容1

## 标题2
内容2
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test',
        markdown: markdown,
        createdAt: DateTime.now(),
        baseLocator: 'test.md',
      );

      expect(chunks.length, 2);
      expect(chunks[0].locator, 'test.md:# 标题1');
      expect(chunks[1].locator, 'test.md:## 标题2');
    });
  });
}
```

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定文件
flutter test test/services/semantic_chunker_test.dart

# 测试覆盖率
flutter test --coverage
```

---

## 好的第一个 Issue

寻找标记为 `good first issue` 的 Issue,它们适合新贡献者:

- 文档改进
- 简单 Bug 修复
- 添加单元测试
- UI 微调

**当前 Good First Issues**:
- [ ] 添加 PDF 导入支持
- [ ] 改进 Markdown 表格解析
- [ ] 添加西班牙语翻译
- [ ] 为 `SemanticChunker` 补充测试

---

## PR 审核流程

1. **自动检查**: CI 会运行 Linter 和测试
2. **代码审核**: 维护者会在 1-3 天内审核
3. **修改请求**: 根据反馈修改代码
4. **合并**: 通过后合并到 `main` 分支

**PR 合并标准**:
- ✅ 通过所有自动化检查
- ✅ 代码符合规范
- ✅ 有适当的测试覆盖
- ✅ 文档已更新(如需要)
- ✅ 至少一位维护者批准

---

## 本地开发技巧

### 快速测试 AI 功能(不消耗 API 额度)

创建 Mock OpenAI Service:

```dart
// test/mocks/mock_openai_service.dart
class MockOpenAIService extends OpenAIService {
  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    // 返回预设响应
    return '''
{
  "knowledgePoints": [
    {
      "title": "测试知识点",
      "description": "这是测试数据",
      "category": "核心概念",
      "citedChunkIds": ["chunk_1"]
    }
  ]
}
''';
  }
}
```

在 Provider 中使用:

```dart
final openaiServiceProvider = Provider<OpenAIService>((ref) {
  if (kDebugMode) {
    return MockOpenAIService(); // 开发模式用 Mock
  }
  return OpenAIService();
});
```

### 热重载技巧

- UI 修改: `r` 热重载即可
- 逻辑修改: `R` 完全重启
- Provider 修改: 需要重启应用

### 调试 SQLite

```bash
# 导出数据库
adb exec-out run-as com.example.dlg_q cat databases/app.db > app.db

# 使用 SQLite 工具查看
sqlite3 app.db
sqlite> .schema
sqlite> SELECT * FROM questions LIMIT 5;
```

---

## 发布流程(维护者)

1. **更新版本号**
   - `pubspec.yaml`: `version: 0.2.0+2`
   - `CHANGELOG.md`: 添加版本记录

2. **创建 Release**
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

3. **构建产物**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ipa
   
   # macOS
   flutter build macos --release
   ```

4. **发布到 GitHub Release**
   - 附上 APK / IPA
   - 复制 CHANGELOG 到描述

---

## 社区资源

- **GitHub Discussions**: 功能讨论、使用问题
- **Discord** (计划): 实时交流
- **Twitter**: [@duoduo_learning](https://twitter.com/duoduo_learning)

---

## 许可协议

通过提交代码,你同意你的贡献将遵循本项目的 MIT License。

---

## 致谢

感谢所有贡献者! 🙏

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- 这里会自动生成贡献者列表 -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

---

## 问题?

- 📧 Email: your-email@example.com
- 💬 Discussions: [GitHub Discussions](https://github.com/你的用户名/duoduo/discussions)
- 🐛 Bug: [创建 Issue](https://github.com/你的用户名/duoduo/issues/new)

**期待你的贡献!** ❤️
