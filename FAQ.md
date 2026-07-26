# 常见问题 (FAQ)

本文档收集 Anchor Learning (锚学) 使用过程中的常见问题和解答。

---

## 📱 基础使用

### Q1: Anchor Learning 是什么?

Anchor Learning (锚学) 是一个**来源可溯源的 AI 学习代理系统**。它可以:
- 导入你的学习资料 (Markdown、代码项目等)
- 自动生成可溯源的练习题
- 使用间隔重复算法安排复习
- 提供 AI Agent 对话式学习辅导

**核心特点**:
- ✅ 每个知识点和题目都能追溯到源文档
- ✅ 三层防幻觉机制,确保内容准确性
- ✅ 100% 本地存储,保护隐私

### Q2: 为什么选择本地优先 (Local-first)?

**优势**:
- 🔒 **隐私保护**: 你的学习资料和进度不会上传到任何服务器
- ⚡ **快速响应**: 除 AI 调用外,所有操作都在本地完成
- 📴 **离线可用**: 答题和复习可完全离线进行
- 💰 **无订阅费**: 除了 OpenAI API 费用,无其他成本

**代价**:
- ⚠️ 需要自行备份数据
- ⚠️ 多设备同步需要手动导出/导入 (云同步规划中)

### Q3: 需要哪些前置条件?

- **必须**: OpenAI API Key (用于 AI 功能)
- **推荐**: 
  - Android 7.0+ 或 iOS 12.0+
  - 至少 500MB 可用存储空间
  - 稳定的网络连接 (用于 AI 调用)

### Q4: 如何获取 OpenAI API Key?

1. 访问 [OpenAI Platform](https://platform.openai.com/)
2. 注册/登录账号
3. 进入 [API Keys](https://platform.openai.com/api-keys) 页面
4. 点击 "Create new secret key" 创建密钥
5. 复制密钥并保存 (仅显示一次)
6. 在应用的 "设置" 中填入

**费用说明**: 
- GPT-4: ~$0.03/1k tokens (输入) + $0.06/1k tokens (输出)
- GPT-3.5-turbo: ~$0.001/1k tokens
- 生成 10 道题大约消耗 5k-10k tokens (~$0.3-0.6)

---

## 📚 文档导入

### Q5: 支持哪些文档格式?

当前支持:
- ✅ Markdown (`.md`)
- ✅ Dart 代码 (`.dart`)
- ✅ JavaScript/TypeScript (`.js`, `.ts`)
- ✅ Python (`.py`)
- ✅ 纯文本 (`.txt`)

**计划支持**:
- 📋 PDF
- 📋 Word (`.docx`)
- 📋 Notion 导出
- 📋 Obsidian Vault

### Q6: 如何导入整个项目/代码库?

1. 在主页点击 "导入文档"
2. 选择 "导入项目文件夹"
3. 选择项目根目录
4. 应用会自动扫描并导入支持的文件类型

**注意**:
- 自动排除 `node_modules`, `build`, `.git` 等目录
- 大型项目 (>1000 文件) 建议分批导入

### Q7: 导入的文档会被上传吗?

**不会**。所有导入的文档都存储在你的设备本地 SQLite 数据库中,不会上传到任何服务器。

只有在调用 OpenAI API 时,会将相关的文档片段发送给 OpenAI 用于生成题目/回答问题,但这些数据:
- 不会被 OpenAI 用于训练模型 (API 政策)
- 传输过程使用 HTTPS 加密
- 你可以在设置中查看每次 API 调用的内容

---

## 🎯 题目生成

### Q8: AI 生成的题目准确吗?

Anchor Learning 使用**三层防幻觉机制**确保准确性:

1. **Semantic Chunker**: 保持文档结构完整,不切断上下文
2. **Citation Verification**: AI 必须引用具体的文档片段,系统验证引用有效性
3. **Question Validator**: 二次核验答案是否与源文档一致

**最终审核**: 生成的题目会进入 "知识库审核" 界面,你可以:
- 查看题目和引用的源文档
- 编辑题目内容
- 标记不准确的题目
- 批准后才进入题库

### Q9: 为什么有些题目被标记 "需要审核"?

可能原因:
- **引用无效**: AI 引用了不存在的文档片段
- **低置信度**: Question Validator 检测到答案可能与源文档不一致
- **缺少引用**: 题目的解析中没有引用源文档

**建议**: 仔细审核这些题目,或者直接丢弃重新生成。

### Q10: 可以自己手动添加题目吗?

**当前版本**: 不支持直接添加,但你可以:
1. 创建一个 Markdown 文件,写入你的知识点
2. 导入这个 Markdown
3. 让 AI 基于它生成题目
4. 在审核时编辑成你想要的样子

**计划功能**: 下个版本将支持完全手动创建题目。

---

## 📖 复习系统

### Q11: 复习算法是怎样的?

基于 **SuperMemo 间隔重复算法** 的变体:

- **新题**: 首次答题后 1 天复习
- **答对**: 间隔 = 上次间隔 × ease (ease 每次 +0.1)
- **答错**: 间隔重置为 1 天,ease 减少 0.2

**示例**:
```
第1次 (答对) → 1天后
第2次 (答对) → 1.1天后  (ease=1.1)
第3次 (答对) → 1.3天后  (ease=1.2)
第4次 (答错) → 1天后    (ease=1.0)
```

### Q12: 如何调整复习频率?

**当前版本**: 算法参数固定,但你可以:
- 答错题目会立即重新进入复习队列
- 手动在 "题库" 中重做任何题目
- 标记 "重点关注" 的题目 (计划功能)

**计划功能**: 自定义复习参数 (初始间隔、ease 增量等)。

### Q13: 可以导出复习记录吗?

**当前版本**: 不支持导出。

**计划功能**: 
- 导出为 CSV (用于数据分析)
- 导出为 Anki 格式 (迁移到 Anki)
- 云同步 (自动备份)

---

## 🤖 Learning Agent

### Q14: Learning Agent 是什么?

Learning Agent 是一个**对话式学习辅导系统**,支持多种学习模式:

- **知识问答**: 基于你的知识库回答问题,带引用链
- **项目面试**: 引导式提问帮助你理解代码项目
- **苏格拉底式**: 不直接给答案,反问启发思考
- **编程实践**: 生成代码练习题 + 自动评测

### Q15: Agent 的回答准确吗?

Agent 遵循**来源约束**:
- 只基于你导入的文档回答
- 每个回答都标注引用的源文档
- 无法回答时会明确说 "当前知识库中没有相关内容"

**注意**: 
- Agent 使用 GPT-4,可能产生幻觉
- 请结合引用链验证答案
- 发现错误可通过 "反馈" 报告

### Q16: Agent 会话会保存吗?

**是的**。所有 Agent 会话都会保存:
- 问题和回答
- 引用的源文档
- 用户评价和反馈

你可以在 "Agent 工作台" 的 "历史记录" 中查看和继续之前的会话。

---

## 🔧 技术问题

### Q17: 应用占用多少存储空间?

- **应用本体**: ~50MB (Android APK)
- **空数据库**: ~1MB
- **每 1000 道题**: ~5-10MB
- **每 100 个文档**: ~2-5MB (取决于文档大小)

**建议**: 至少预留 500MB 空间。

### Q18: 如何备份数据?

**方法 1: 手动备份数据库文件**

Android:
```bash
adb pull /data/data/com.anchorlearning.app/databases/app_database.db ./backup.db
```

iOS: 使用 iTunes 文件共享或 iMazing 等工具。

**方法 2: 导出功能 (计划中)**

将支持一键导出所有数据为 ZIP 文件。

### Q19: 多设备如何同步?

**当前版本**: 不支持自动同步。

**临时方案**:
1. 在设备 A 备份数据库文件
2. 复制到设备 B
3. 替换设备 B 的数据库文件

**计划功能**: 
- 云同步 (Supabase/Firebase)
- 自动冲突解决

### Q20: 应用崩溃/卡顿怎么办?

**排查步骤**:
1. 检查是否是最新版本
2. 重启应用
3. 清理缓存 (设置 > 存储)
4. 查看日志: `flutter logs` 或系统日志

**报告 Bug**:
请在 [GitHub Issues](https://github.com/Drew-Z/anchor/issues) 创建 Bug 报告,包含:
- 设备型号和系统版本
- 应用版本
- 复现步骤
- 错误日志

---

## 💰 费用和隐私

### Q21: 使用 Anchor Learning 需要付费吗?

**应用本身**: 完全免费开源 (MIT 许可证)

**OpenAI API 费用**: 
- 按实际使用量计费
- 生成 10 道题 ≈ $0.3-0.6
- Agent 对话 ≈ $0.02-0.1/轮

**建议**: 在 OpenAI 账户中设置每月用量限制。

### Q22: 我的数据会被收集吗?

**不会**。Anchor Learning:
- ❌ 不收集任何用户数据
- ❌ 不包含任何分析/追踪代码
- ❌ 不上传你的文档和学习记录

**唯一的网络请求**: 调用 OpenAI API (你可以使用代理自建)。

### Q23: OpenAI 会用我的数据训练模型吗?

根据 [OpenAI API 数据使用政策](https://openai.com/policies/api-data-usage-policies):

- **API 数据不会被用于训练模型** (自 2023-03-01 起)
- 数据会保留 30 天用于滥用监控
- 你可以申请零保留 (Zero Retention)

---

## 🌍 社区和贡献

### Q24: 如何参与贡献?

欢迎各种形式的贡献:

- 🐛 **报告 Bug**: [创建 Issue](https://github.com/Drew-Z/anchor/issues/new?template=bug_report.yml)
- 💡 **提出建议**: [创建 Feature Request](https://github.com/Drew-Z/anchor/issues/new?template=feature_request.yml)
- 📝 **改进文档**: 提交文档 PR
- 💻 **贡献代码**: 阅读 [贡献指南](../CONTRIBUTING.md)
- 🌐 **翻译**: 帮助国际化 (计划中)

### Q25: 如何获取帮助?

- 📖 **文档**: 先查看 [README](../README.md) 和本 FAQ
- 💬 **Discussions**: [GitHub Discussions](https://github.com/Drew-Z/anchor/discussions)
- 🐛 **Bug 报告**: [GitHub Issues](https://github.com/Drew-Z/anchor/issues)
- 📧 **邮件**: support@example.com

### Q26: 项目的未来规划是什么?

查看 [ROADMAP.md](../ROADMAP.md) 了解详细规划,亮点包括:

- **v0.2**: 云同步、多模型支持、国际化
- **v0.3**: 插件系统、自定义 Prompt、协作学习
- **v1.0**: 完善的学习分析、智能推荐、社区题库

---

## 🔄 更新和版本

### Q27: 如何更新到最新版本?

- **Android**: 
  - 通过 GitHub Releases 下载最新 APK
  - 安装覆盖旧版本
  - 数据会自动迁移

- **iOS**: 
  - 等待 App Store 上架 (计划中)
  - 或通过 TestFlight 测试版

### Q28: 旧版本数据兼容吗?

**向前兼容**: 新版本会自动迁移旧版本数据。

**向后不兼容**: 不建议用新版本数据降级到旧版本。

**建议**: 更新前先备份数据库文件。

---

## ❓ 其他问题

### 没找到答案?

1. 搜索 [GitHub Issues](https://github.com/Drew-Z/anchor/issues)
2. 在 [GitHub Discussions](https://github.com/Drew-Z/anchor/discussions) 提问
3. 加入社区讨论群 (计划中)

---

**最后更新**: 2024-01-XX

**反馈建议**: 如果你觉得某个问题应该加入 FAQ,请创建 [Documentation Issue](https://github.com/Drew-Z/anchor/issues/new?template=documentation.yml)。
