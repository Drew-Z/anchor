# 快速开始指南

## 5 分钟快速体验

跟随本指南,你将在 5 分钟内运行多多学习,并导入第一份学习资料。

---

## 前置要求

- **Flutter SDK**: 3.0 或更高版本
- **操作系统**: Windows / macOS / Linux
- **OpenAI API Key**: 用于 AI 功能(如果没有,参见下方说明)

### 检查 Flutter 安装

```bash
flutter --version
```

如果未安装,访问 [Flutter 官网](https://flutter.dev/docs/get-started/install) 下载。

---

## 步骤 1: 克隆项目

```bash
git clone https://github.com/你的用户名/duoduo.git
cd duoduo
```

---

## 步骤 2: 安装依赖

```bash
flutter pub get
```

**预计耗时**: 30-60 秒

---

## 步骤 3: 配置 OpenAI API Key

### 方式 1: 使用环境变量(推荐)

创建 `.env` 文件:

```bash
cp .env.example .env
```

编辑 `.env`,填入你的 API Key:

```env
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-3.5-turbo
```

### 方式 2: 在应用内设置

首次运行时,应用会引导你输入 API Key。

### 如何获取 API Key?

1. 访问 [OpenAI Platform](https://platform.openai.com/api-keys)
2. 注册账号并绑定支付方式
3. 创建新的 API Key
4. **费用**: 生成 10 道题约 $0.01-0.05

⚠️ **没有 API Key?** 你仍可以:
- 手动创建题目
- 导入示例数据体验其他功能
- 使用本地模型(见[高级配置](#使用本地模型))

---

## 步骤 4: 运行应用

### 在模拟器/真机上运行

```bash
# 查看可用设备
flutter devices

# 启动应用(会自动选择设备)
flutter run
```

### 在桌面上运行

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

**首次运行**: 可能需要 2-3 分钟编译,请耐心等待。

---

## 步骤 5: 导入第一份学习资料

### 选项 A: 导入示例数据(推荐首次体验)

1. 应用启动后,点击右下角的 **"+"** 按钮
2. 选择 **"导入示例数据"**
3. 等待 5-10 秒,系统会自动导入:
   - Flutter 基础知识
   - 10 道预生成的练习题

**优势**: 无需 API Key,立即体验核心功能。

### 选项 B: 导入自己的 Markdown 文档

1. 准备一份 Markdown 文件(如 `flutter_notes.md`)
2. 点击右下角的 **"+"** 按钮
3. 选择 **"导入文档"**
4. 选择你的 Markdown 文件
5. 等待 AI 分析(约 30-60 秒):
   - 提取知识点
   - 生成练习题
   - 验证引用链

### 选项 C: 导入代码项目

1. 点击右下角的 **"+"** 按钮
2. 选择 **"导入项目"**
3. 选择项目根目录
4. 勾选要分析的文件(自动过滤 `.git`, `node_modules` 等)
5. 等待 AI 分析(约 1-2 分钟):
   - 理解项目架构
   - 提取关键代码概念
   - 生成代码理解题

---

## 步骤 6: 开始学习

### 答题

1. 在主页点击 **"开始学习"**
2. 系统会推荐题目(基于间隔重复算法)
3. 答题后查看解析
4. 点击 **"查看来源"** 可追溯到原文档

### 查看知识库

1. 点击底部导航的 **"知识库"**
2. 浏览提取的知识点
3. 点击任意知识点查看:
   - 详细描述
   - 来源文档引用
   - 相关练习题
   - 前置依赖关系

### 使用 AI 辅导

1. 点击底部导航的 **"AI 助手"**
2. 三种模式:
   - **知识问答**: 问"什么是 StatefulWidget?"
   - **项目面试**: 选择已导入的项目,AI 引导你理解代码
   - **苏格拉底式辅导**: AI 通过反问帮你思考

---

## 常见问题

### Q1: 运行时报错 "OpenAI API Key not found"

**解决方案**:
1. 确认 `.env` 文件存在且包含 `OPENAI_API_KEY`
2. 重启应用
3. 或在设置中手动输入 API Key

### Q2: 生成题目失败 "Rate limit exceeded"

**原因**: OpenAI API 限流  
**解决方案**:
1. 等待 1 分钟后重试
2. 或升级 OpenAI 账号额度
3. 或减少一次生成的题目数量(在设置中调整)

### Q3: 导入大项目时应用卡住

**原因**: 文件过多,AI 处理时间长  
**解决方案**:
1. 只选择核心代码文件(如 `lib/` 目录)
2. 排除测试文件和自动生成代码
3. 分批导入不同模块

### Q4: 想使用本地 AI 模型,不想花钱

参见 [使用本地模型](#使用本地模型) 部分。

### Q5: 如何备份我的数据?

1. 点击 **设置 → 隐私与数据 → 导出数据**
2. 选择保存位置
3. 生成 JSON 文件,包含所有题目和学习记录

**数据位置**:
- Android: `/data/data/com.example.dlg_q/databases/`
- iOS: `~/Library/Containers/.../Documents/`
- macOS/Windows/Linux: 应用数据目录

---

## 高级配置

### 使用本地模型

如果你有本地运行的 LLM(如 Ollama),可以替换 OpenAI:

1. 编辑 `lib/services/openai_service.dart`
2. 修改 `baseUrl`:
   ```dart
   final baseUrl = 'http://localhost:11434/v1'; // Ollama 地址
   ```
3. 设置模型名:
   ```dart
   final model = 'llama3.1:8b';
   ```

**兼容的本地方案**:
- [Ollama](https://ollama.ai/): 简单易用
- [LM Studio](https://lmstudio.ai/): 图形界面
- [Text Generation WebUI](https://github.com/oobabooga/text-generation-webui)

### 调整生成题目数量

编辑 `lib/services/ingestion/source_grounded_ingestion_service.dart`:

```dart
int questionCountFor(int knowledgePointCount) {
  return knowledgePointCount * 2; // 默认每个知识点生成 2 道题
}
```

### 自定义题型分布

在 `lib/services/ai/tasks/question_generation_task.dart` 修改 Prompt 中的:

```
题型分布: 50% 单选, 30% 多选, 20% 填空/判断
```

---

## 下一步

✅ **恭喜!** 你已经成功运行了多多学习。

**推荐阅读**:
- [导入自己的文档](./IMPORT_YOUR_DOCS.md) - 最佳实践和技巧
- [自定义 AI Prompt](./CUSTOMIZE_PROMPTS.md) - 调整题目生成策略
- [系统架构](../architecture/SYSTEM_OVERVIEW.md) - 理解内部工作原理

**遇到问题?**
- 查看 [常见问题文档](./TROUBLESHOOTING.md)
- 提交 [GitHub Issue](https://github.com/你的用户名/duoduo/issues)
- 加入 [Discord 社区](https://discord.gg/你的邀请链接)

---

## 致谢

感谢使用多多学习! 如果觉得有帮助,请:
- ⭐ Star 本项目
- 📢 分享给朋友
- 🐛 反馈问题和建议

**一起打造更好的学习工具!** 🚀
