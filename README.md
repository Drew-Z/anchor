# 多多学习 - 来源可溯源的 AI 学习代理

<div align="center">

![多多学习 Logo](docs/images/logo.png)

**把你的文档和代码变成个性化学习内容**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[功能特性](#-功能特性) • [快速开始](#-快速开始) • [架构设计](#-架构设计) • [文档](#-文档) • [贡献](#-贡献)

</div>

---

## 📖 项目简介

**多多学习**是一个开源的 AI 学习助手,帮助你从个人文档、技术笔记、代码项目中自动生成**可溯源**的练习题和学习内容。

### 核心亮点

🔗 **完整的引用链**: 每道题目都能追溯到源文档的具体位置  
🤖 **AI Agent 辅导**: 通过面试式引导帮助你理解代码项目  
🛡️ **防幻觉机制**: Citation Verification + Question Validator 双重验证  
🔒 **隐私优先**: 数据本地存储,可选云同步  
📱 **跨平台**: Android / iOS / macOS / Windows / Linux

---

## ✨ 功能特性

### 📚 智能导入

- **Markdown 语义切分**: 按标题层级切分,保持语义完整
- **代码项目理解**: 分析项目架构,提取关键概念
- **精确定位**: 每个知识块都有可读的 locator(如 `README.md:## 快速开始`)

### 🎯 AI 驱动的内容生成

- **知识点提取**: 自动识别文档中的核心概念
- **多样化题型**: 单选/多选/填空/判断/匹配题
- **前置依赖推理**: 自动构建知识图谱
- **质量验证**: AI 二次核验事实准确性

### 🧠 学习功能

- **间隔重复**: 基于遗忘曲线的智能复习调度
- **掌握度追踪**: 实时追踪每个知识点的掌握情况
- **来源溯源**: 点击题目查看原文,理解上下文
- **AI 语义判题**: 填空题支持同义答案判定

### 🤖 AI Agent 辅导

- **知识问答**: 基于知识库回答你的问题,附带引用链
- **项目面试**: 引导式提问帮助你理解大型代码库
- **苏格拉底式**: 通过反问启发思考,而非直接给答案
- **长会话恢复**: 支持中断后继续学习

---

## 🎯 适合谁?

- 📝 **正在学习新技术的开发者** - 把文档变成可练习的知识
- 🏗️ **需要理解大型项目的工程师** - AI 引导你读懂复杂代码
- 🎓 **准备面试的求职者** - 从项目中生成面试题
- 🛠️ **想构建教育 AI 产品的团队** - 参考完整的实现方案

---

## 🚀 快速开始

### 前置要求

- Flutter 3.0+
- OpenAI API Key(或兼容的本地模型)

### 安装步骤

```bash
# 1. 克隆项目
git clone https://github.com/你的用户名/duoduo.git
cd duoduo

# 2. 安装依赖
flutter pub get

# 3. 配置 API Key
cp .env.example .env
# 编辑 .env 填入 OPENAI_API_KEY

# 4. 运行
flutter run
```

### 导入第一份学习资料

1. 点击右下角 **"+"** 按钮
2. 选择 **"导入文档"** 或 **"导入项目"**
3. 等待 AI 分析(30-60 秒)
4. 开始答题! 🎉

📚 **详细指南**: [快速开始文档](docs/guides/QUICK_START.md)

---

## 🏗️ 架构设计

### 核心流程

```
用户上传文档
    ↓
[Semantic Chunker] 语义切分
    ↓
[AI Tasks] 提取知识点 → 生成题目
    ↓
[Citation Verification] 验证引用
    ↓
[Question Validator] 验证事实
    ↓
[人工审核] 最终确认
    ↓
[题库] 开始学习
```

### 防幻觉三层防线

1. **Layer 1: Semantic Chunker**  
   保持源文档的结构完整性,不切断语义边界

2. **Layer 2: Citation Verification**  
   强制 AI 引用具体 chunk ID,验证引用有效性

3. **Layer 3: Question Validator**  
   二次核验生成的答案是否与源文档一致

### 技术栈

- **前端**: Flutter + Riverpod
- **数据**: SQLite(本地优先)
- **AI**: OpenAI API / 兼容的本地模型
- **检索**: BM25 + Semantic Embedding 混合搜索

📖 **深入了解**: [系统架构文档](docs/architecture/SYSTEM_OVERVIEW.md)

---

## 📊 示例效果

### 从 Markdown 到练习题

```markdown
# Flutter Widget 生命周期

StatefulWidget 通过 State 对象管理状态...

## 关键方法

- `initState()`: 初始化,只调用一次
- `build()`: 构建 UI,可能多次调用
- `dispose()`: 清理资源
```

**生成的题目**:

> **题目**: 以下关于 StatefulWidget 生命周期的说法,正确的是?  
> A. initState() 可以多次调用  
> B. dispose() 在 Widget 销毁时调用 ✅  
> C. build() 只调用一次  
> D. setState() 可以在 dispose() 后调用
>
> **解析**: 根据文档 [README.md:## 关键方法],dispose() 方法在 State 对象被永久移除时调用,用于释放资源。
>
> **来源**: `README.md:## 关键方法` (可点击跳转)

### Agent 辅导示例

```
👤 用户: 这个项目是怎么实现间隔重复的?

🤖 AI: 我看到项目中有 ReviewSchedulerService。
      在回答之前,你能先告诉我,你理解的"间隔重复"
      是什么原理吗?

👤 用户: 就是根据记忆曲线,越熟悉的内容复习间隔越长?

🤖 AI: 非常好! 那你觉得系统需要追踪哪些数据,
      才能实现这个算法?
      
      提示: 看看 Question 模型里的字段
      [lib/data/models/question.dart:15-42]
```

---

## 📚 文档

### 使用指南

- [快速开始](docs/guides/QUICK_START.md) - 5 分钟上手
- [导入文档](docs/guides/IMPORT_YOUR_DOCS.md) - 最佳实践和技巧
- [自定义 Prompt](docs/guides/CUSTOMIZE_PROMPTS.md) - 调整 AI 行为

### 架构文档

- [系统概览](docs/architecture/SYSTEM_OVERVIEW.md) - 核心流程和设计理念
- [数据模型](docs/architecture/DATA_MODEL.md) - ER 图和表结构
- [AI Pipeline](docs/architecture/AI_PIPELINE.md) - 每个 AI Task 的设计

### 开发者

- [贡献指南](CONTRIBUTING.md) - 如何参与开发
- [开发路线图](ROADMAP.md) - 未来计划
- [更新日志](CHANGELOG.md) - 版本历史

---

## 🤝 贡献

我们欢迎所有形式的贡献!

- 🐛 [报告 Bug](https://github.com/你的用户名/duoduo/issues/new?template=bug_report.md)
- 💡 [提出新功能](https://github.com/你的用户名/duoduo/issues/new?template=feature_request.md)
- 📝 改进文档
- 💻 提交代码

### 好的第一个 Issue

寻找标记为 `good first issue` 的任务:

- [ ] 添加 PDF 导入支持
- [ ] 改进 Markdown 表格解析
- [ ] 添加西班牙语翻译
- [ ] 为核心服务补充单元测试

📖 **阅读**: [贡献指南](CONTRIBUTING.md)

---

## 🌟 启发来源

本项目受以下项目启发:

- [aicoding-cookbook](https://github.com/lili-luo/aicoding-cookbook) - Claude Code Skills 最佳实践
- [Anki](https://apps.ankiweb.net/) - 间隔重复算法先驱
- [Obsidian](https://obsidian.md/) - 个人知识管理理念

---

## 📄 许可

本项目采用 [MIT License](LICENSE) 开源。

---

## 🙏 致谢

感谢所有贡献者和使用者! ❤️

### 贡献者

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- 这里会自动生成贡献者列表 -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

---

## 📞 联系方式

- **GitHub Issues**: [创建 Issue](https://github.com/你的用户名/duoduo/issues)
- **Discussions**: [讨论区](https://github.com/你的用户名/duoduo/discussions)
- **Email**: your-email@example.com
- **Twitter**: [@duoduo_learning](https://twitter.com/duoduo_learning)

---

<div align="center">

**如果觉得有帮助,请给个 ⭐ Star!**

Made with ❤️ by the Duoduo Learning Team

</div>
