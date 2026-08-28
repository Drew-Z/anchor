# GitHub Repository Setup Guide

## 📋 Repository Configuration

### Basic Information

**Repository Name**: `anchor`

**Description** (short):
```
⚓ Anchor your knowledge with full source traceability | Turn docs into AI quizzes that trace back to source
```

**Website**: `https://anchor.playlab.eu.cc`

**Topics** (tags):
```
ai, learning, flutter, education, spaced-repetition, citation-verification, 
knowledge-graph, openai, sqlite, tutoring-system, educational-technology, 
ai-tutor, personal-learning, knowledge-management, study-assistant
```

---

## 🎯 Repository Settings

### About Section

1. Go to your repository on GitHub
2. Click **⚙️ Settings** (top right of About box)
3. Fill in:
   - **Description**: ⚓ Anchor your knowledge with full source traceability | Turn docs into AI quizzes that trace back to source
   - **Website**: https://anchor.playlab.eu.cc
   - **Topics**: (add the tags above one by one)
   - ✅ Check "Use GitHub Pages" if you want to host docs

---

## 📝 Social Preview Image (Optional)

If you want a custom preview image when sharing on social media:

1. Go to **Settings** → **Options**
2. Scroll to **Social preview**
3. Upload an image (1280×640px recommended)

**Suggested text for image**:
```
⚓ Anchor Learning
Turn Docs → AI Quizzes → Traceable Answers
Built with Flutter • MIT License
```

---

## 🏷️ Prepare the Private Alpha Release

The current candidate is `1.0.0+2005`. Do not publish a public release until the
Private Alpha readiness record changes from `HOLD` to `GO` after the real cohort
evidence is complete.

When the cohort gate is approved:

1. Go to **Releases** → **Create a new release**
2. **Tag version**: `v1.0.0`
3. **Release title**: `⚓ Anchor Learning v1.0.0 - Private Alpha`
4. **Description**: Use the approved release notes and `CHANGELOG.md` references; include the supported Android package and known limitations.
5. Attach only the approved, signed release artifact and its SHA-256 from the release evidence.
6. Publish only after the release checklist and rollback owner have been recorded.

---

## 🔗 Quick Links After Setup

- **Repository**: https://github.com/Drew-Z/anchor
- **Issues**: https://github.com/Drew-Z/anchor/issues
- **Discussions**: https://github.com/Drew-Z/anchor/discussions
- **Wiki**: https://github.com/Drew-Z/anchor/wiki (optional)

---

## 📢 Community Post Template

Use this when posting to Chinese communities:

### 掘金/V2EX Title
```
[开源] Anchor Learning - 把你的文档锚定成可溯源的学习内容
```

### Post Content (300-500 words)
```markdown
大家好,我开源了一个 AI 学习助手项目 **Anchor Learning (锚学)**,特色是**来源可溯源**。

**核心功能**:
- 📚 导入 Markdown 文档或代码项目
- 🤖 AI 自动提取知识点,生成练习题
- 🔗 每道题都能追溯到源文档具体位置(可点击跳转)
- 🛡️ 三层防线防止 AI 幻觉
- 🎯 间隔重复算法智能复习
- 💬 AI Agent 辅导(苏格拉底式引导)

**为什么做这个?**
现在的学习 APP 要么内容固定,要么 AI 生成的题目容易"瞎编"。我想要一个工具能把**我自己的笔记和项目**变成学习内容,并且每道题都能追溯来源验证真实性。

**技术亮点**:
- Citation Verification: 强制 AI 引用具体位置
- Question Validator: 二次核验答案准确性  
- Semantic Chunking: 保持语义完整性

**开源地址**: https://github.com/Drew-Z/anchor
**技术栈**: Flutter + SQLite + OpenAI-compatible API
**许可**: MIT

欢迎试用和贡献! 🎉
```

---

## 🌍 International Community Template

For Reddit/HN/Product Hunt:

### Reddit Title (r/FlutterDev, r/opensource)
```
[Open Source] Anchor Learning - Turn your docs into traceable AI quizzes
```

### Post Content
```markdown
Hey everyone! I've open-sourced **Anchor Learning**, an AI-powered study tool that converts your personal docs and code into practice questions—with full source traceability.

**Key Features**:
- 📚 Import Markdown docs or code projects
- 🤖 AI extracts knowledge points & generates quizzes
- 🔗 Every question links back to exact source location
- 🛡️ 3-layer anti-hallucination architecture
- 🎯 Spaced repetition algorithm
- 💬 Socratic-style AI tutoring

**Why I Built This**:
Existing learning apps either have fixed content or AI-generated questions that often hallucinate. I wanted a tool that turns **my own notes and projects** into learning content while ensuring every answer is traceable and verifiable.

**Technical Highlights**:
- Citation Verification: Forces AI to cite specific sources
- Question Validator: Cross-checks answers for accuracy
- Semantic Chunking: Preserves context integrity

**Repo**: https://github.com/Drew-Z/anchor
**Stack**: Flutter + SQLite + OpenAI-compatible API
**License**: MIT

Feedback welcome! 🚀
```

---

## ✅ Checklist Before Publishing

- [x] Repository created on GitHub
- [x] Description and website added
- [x] README.md displays correctly
- [x] LICENSE file present
- [ ] Productization PR reviewed, explicitly authorized, and merged into `main`
- [ ] Productized `web/landing` deployed and production-smoke-tested
- [ ] Private Alpha release (v1.0.0) created after readiness changes to `GO`
- [ ] Demo video recorded (or placeholder added)
- [ ] Screenshots ready (4-6 images)
- [ ] Community post drafted
- [ ] Ready to share!

---

**Created**: 2026-07-26  
**Project**: Anchor Learning  
**Website**: https://anchor.playlab.eu.cc
