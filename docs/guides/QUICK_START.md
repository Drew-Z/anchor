# 快速开始指南

> 5 分钟让多多学习 APP 在你的设备上跑起来

## 📋 前置要求

- **Flutter SDK**: 3.0 或更高版本
- **设备**: Android/iOS/macOS 任一平台
- **OpenAI API Key**: 用于 AI 功能(可在设置中配置)

---

## 🚀 安装步骤

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/duoduo.git
cd duoduo
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置 API Key(可选)

首次运行后,在 APP 内通过以下路径配置:

```
设置 → API 配置 → 输入你的 OpenAI API Key
```

如果没有 API Key,可以到 [OpenAI Platform](https://platform.openai.com/api-keys) 申请。

### 4. 运行应用

```bash
# Android/iOS
flutter run

# macOS
flutter run -d macos

# 查看可用设备
flutter devices
```

---

## 🎯 第一次使用

### 导入学习资料

1. **点击"导入"按钮**
2. **选择 Markdown 文件或项目代码**
3. **等待 AI 分析**(大约 30 秒 - 2 分钟)
4. **查看生成的知识点和练习题**

### 开始学习

#### 方式 1: 刷题模式(类似多邻国)
- 进入"练习"页面
- 支持选择题/填空题/判断题
- 即时反馈 + 错题记录

#### 方式 2: AI 面试模式
- 进入"Agent 工作台"
- 选择"对话式面试"
- AI 逐个询问知识点,评估你的答案

#### 方式 3: 知识点问答
- 进入"Agent 工作台"
- 选择"知识点问答"
- 向 AI 提问,获得有原文依据的讲解

---

## 📚 示例内容

项目内置了 Flutter 基础教程示例,首次运行时自动导入。你也可以:

1. **导入自己的 Markdown 笔记**
   - 学习文档
   - 技术博客
   - 课程讲义

2. **导入项目代码**
   - 支持扫描整个项目目录
   - AI 自动提取架构知识点
   - 生成代码理解练习题

---

## ⚙️ 常见问题

### Q: 为什么生成的题目很少?
**A**: 可能原因:
- 文档内容太短(建议 > 1000 字)
- 没有明确的知识点(尝试添加章节标题)
- API Key 配额不足(检查 OpenAI 账户余额)

### Q: 如何删除导入的内容?
**A**: 在"知识库"页面长按条目 → 选择删除

### Q: 数据存储在哪里?
**A**: 所有数据存储在本地 SQLite 数据库,不会上传到云端

### Q: 如何导出学习记录?
**A**: 设置 → 隐私与数据 → 导出学习数据(JSON 格式)

---

## 🔧 进阶配置

### 自定义 AI 模型

编辑 `lib/services/openai_service.dart`:

```dart
static const String defaultModel = 'gpt-4o-mini'; // 改为 gpt-4 等
```

### 调整题目生成数量

编辑 `lib/services/content_analyzer.dart`:

```dart
final questionsPerPoint = 3; // 每个知识点生成的题目数
```

---

## 📖 下一步

- [导入你的文档](IMPORT_YOUR_DOCS.md)
- [自定义 AI Prompts](CUSTOMIZE_PROMPTS.md)
- [了解系统架构](../architecture/SYSTEM_OVERVIEW.md)
- [贡献代码](../../CONTRIBUTING.md)

---

**遇到问题?** 在 [GitHub Issues](https://github.com/yourusername/duoduo/issues) 提出,或查看 [常见问题文档](FAQ.md)
