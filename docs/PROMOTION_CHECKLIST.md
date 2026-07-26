# 开源推广行动清单

> 基于 docs-to-book 理念优化的推广计划

---

## ✅ 已完成

### 文档体系 (2026-07-26)
- [x] README.md - 项目首页
- [x] 用户指南 3 篇 (快速开始/导入文档/自定义 Prompts)
- [x] 架构文档 3 篇 (系统概览/数据模型/AI Pipeline)
- [x] CONTRIBUTING.md - 贡献指南
- [x] ROADMAP.md - 开发路线图
- [x] CHANGELOG.md - 版本历史
- [x] READING_GUIDE.md - 阅读路径 ✨ 新增
- [x] DRIFT_LOG.md - 文档-代码漂移清单 ✨ 新增
- [x] BLOG_POST.md - 技术博客草稿 ✨ 新增
- [x] GitHub 用户名已更新 (xuanli199)
- [x] 所有文档已提交到 git

---

## 🎯 第一阶段:快速推广 (预计 1-2 天)

### 1. 视觉素材制作 🔴 高优先级

#### 应用截图 (4-6 张)
```bash
需要截图的场景:
□ 导入文档界面 (展示文件选择)
□ AI 分析进度 (展示处理过程)
□ 题目练习界面 (展示题目和选项)
□ 答题后的解析页面 (展示来源溯源链接)
□ 知识点列表 (展示学习进度)
□ 设置页面 (展示 API 配置)
```

**执行方式**:
1. 在 Android Studio / Xcode 中运行应用
2. 使用模拟器截图功能
3. 裁剪为统一尺寸 (建议 1080x2340)
4. 保存到 `docs/images/screenshots/`

#### Demo 视频 (3-5 分钟) 🔴 关键
```
脚本大纲:
0:00-0:30  问题场景 (现有学习工具的痛点)
0:30-1:00  导入一份 Markdown 文档
1:00-2:00  AI 分析过程 + 生成题目
2:00-3:00  答题演示 + 点击"查看来源"跳转原文
3:00-3:30  展示 Agent 辅导功能
3:30-4:00  总结核心价值 (可溯源 + 防幻觉)
4:00-4:30  开源链接 + 如何贡献
```

**工具推荐**:
- 录屏: OBS Studio (免费)
- 剪辑: DaVinci Resolve (免费) / 剪映
- 字幕: 必须添加中文字幕

**发布平台**:
- B站 (主要)
- YouTube (国际)
- 嵌入 README.md

#### Logo 和封面图
```bash
□ 设计项目 Logo (或使用 AI 生成)
□ 制作 GitHub 社交预览图 (1280x640)
□ 更新 README.md 顶部的 logo 占位符
```

---

### 2. 示例数据准备 🟡 中优先级

```bash
准备 3-5 个示例数据集:
□ Flutter Widget 基础 (10 个知识点)
□ React Hooks 教程 (8 个知识点)
□ 算法题解集合 (15 个知识点)
□ Git 命令手册 (12 个知识点)
□ TypeScript 类型系统 (10 个知识点)

位置: assets/examples/
格式: Markdown 文件 + 配套的说明 README
```

**目的**: 新用户下载后立即体验,无需自己准备文档

---

### 3. README 优化 🟢 低优先级

```bash
□ 添加 Demo 视频嵌入
□ 添加应用截图
□ 添加 GIF 动图 (导入→生成→答题流程)
□ 优化 Badge (添加构建状态/测试覆盖率)
```

---

### 4. 社区发布 🔴 关键

#### 中文社区
```bash
□ 掘金
  标题: "开源 | 用 Flutter + AI 打造可溯源的学习助手"
  标签: #Flutter #AI #开源项目 #学习工具
  
□ 思否 (SegmentFault)
  标题: "多多学习:防止 AI 幻觉的个人知识助手"
  
□ V2EX
  节点: /share
  标题: "[开源] 把你的文档和代码变成练习题,支持来源溯源"
  
□ 知乎
  专栏: 技术/开源
  标题: "我开源了一个 AI 学习助手,这是防止幻觉的技术方案"
```

#### 国际社区
```bash
□ Reddit
  subreddit: r/FlutterDev, r/opensource, r/learnprogramming
  标题: "I built an AI learning assistant with citation verification"
  
□ Hacker News
  类型: Show HN
  标题: "Show HN: Duoduo Learning – AI Study Assistant with Source Traceability"
  
□ Product Hunt
  需要准备: Logo, 3 张截图, 视频, 详细描述
```

**发布文案模板** (已准备好的技术博客可作为基础):
- 使用 `docs/BLOG_POST.md` 作为详细技术说明
- 社区发布时提炼为 300-500 字摘要
- 突出"可溯源"和"防幻觉"两个核心卖点

---

## 🚀 第二阶段:技术博客 (预计 2-3 天)

### 博客发布

```bash
□ 润色 docs/BLOG_POST.md
  - 添加更多实测数据
  - 补充代码示例
  - 添加架构图
  
□ 发布到个人博客 (https://biau.playlab.eu.cc)
  
□ 同步发布到技术社区
  - 掘金专栏
  - 思否专栏
  - Medium (英文版)
  - Dev.to
```

**SEO 关键词**:
- AI hallucination prevention
- Citation verification
- Flutter AI application
- Learning assistant
- Source traceability

---

## 🎨 第三阶段:质量提升 (预计 3-5 天)

### 测试覆盖

```bash
□ 核心服务单元测试
  - ContentAnalyzer (语义切分)
  - OpenAIService (API 调用)
  - CitationVerificationTask (引用核验)
  - QuestionValidatorTask (事实验证)
  
□ Widget 测试
  - QuizScreen
  - IngestionScreen
  
□ 集成测试
  - 完整的导入→生成→答题流程
```

### CI/CD 配置

```bash
□ GitHub Actions 工作流
  - Flutter analyze (代码检查)
  - Flutter test (运行测试)
  - Build APK/IPA (自动构建)
  
□ 代码质量徽章
  - 添加到 README.md
```

---

## 📊 第四阶段:用户反馈迭代 (持续)

### 社区运营

```bash
□ 创建 GitHub Discussions 分类
  - 💬 General (一般讨论)
  - 💡 Ideas (功能建议)
  - 🙏 Q&A (问题解答)
  - 🎨 Show and tell (用户案例)
  
□ 准备 FAQ 文档
  
□ 设置 Issue 模板
  - Bug report ✅ (已完成)
  - Feature request ✅ (已完成)
  - Documentation improvement (新增)
  
□ 及时回复 Issues 和 Discussions
```

### 数据追踪

```bash
□ 统计指标
  - GitHub Stars 数量
  - 每周下载量
  - Issue/PR 活跃度
  
□ 用户反馈收集
  - 最常见的功能请求
  - 最常见的 Bug
  - 文档哪里不清楚
```

---

## 🎯 里程碑目标

### 短期 (1 个月内)
- [ ] 获得 100+ GitHub Stars
- [ ] 发布首个 Release (v0.1.0)
- [ ] 完成 Demo 视频
- [ ] 发布到 3+ 技术社区

### 中期 (3 个月内)
- [ ] 获得 500+ GitHub Stars
- [ ] 收到 10+ 外部贡献的 PR
- [ ] 实现路线图中的 PDF 导入功能
- [ ] 实现本地 LLM 支持

### 长期 (6 个月内)
- [ ] 获得 1000+ GitHub Stars
- [ ] 建立活跃的用户社区
- [ ] 发布 Web 版本
- [ ] 被技术媒体报道

---

## 🛠️ 执行建议

### 推荐顺序

**Week 1** (关键周):
1. ✅ Day 1-2: 文档完善 (已完成)
2. 🔴 Day 3-4: 录制 Demo 视频 + 截图
3. 🔴 Day 5-6: 发布到中文社区 (掘金/V2EX/知乎)
4. 🟡 Day 7: 准备示例数据

**Week 2** (扩散周):
1. 发布技术博客
2. 发布到国际社区 (Reddit/HN)
3. 优化 README (嵌入视频和截图)

**Week 3-4** (质量周):
1. 根据社区反馈改进文档
2. 补充单元测试
3. 配置 CI/CD

---

## 💰 预算 (如需)

### 可选但推荐的投入

```
□ Logo 设计 (Fiverr/猪八戒): $20-50
□ Demo 视频剪辑外包 (如果自己不会): $50-100
□ Product Hunt 推广 (可选): $0 (免费) 或购买推广位
```

### 完全免费的替代方案
- Logo: 使用 Canva/Figma 自己设计
- 视频: OBS Studio + DaVinci Resolve 免费版
- 社区推广: 完全免费

---

## 📞 下一步行动

### 立即可做的 TOP 3

1. **录制 Demo 视频** (最关键)
   - 时长: 3-5 分钟
   - 重点展示: 溯源功能
   - 工具: OBS Studio

2. **截图 6 张**
   - 场景覆盖完整流程
   - 保存到 docs/images/screenshots/

3. **发布到掘金**
   - 使用 docs/BLOG_POST.md 提炼摘要
   - 附上 GitHub 链接
   - 标签: #Flutter #AI #开源

---

**维护者**: bill  
**最后更新**: 2026-07-26  
**下次检查**: 录制完 Demo 视频后更新
