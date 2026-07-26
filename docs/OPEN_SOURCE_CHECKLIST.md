# Anchor Learning (锚学) 开源准备清单

本文档记录项目开源前需完成的所有准备工作。

---

## ✅ 已完成

### 📝 文档完善

- [x] **README.md**: 项目介绍、特性、快速开始
- [x] **LICENSE**: MIT 许可证
- [x] **CONTRIBUTING.md**: 贡献指南和代码规范
- [x] **CODE_OF_CONDUCT.md**: 社区行为准则
- [x] **CHANGELOG.md**: 版本变更记录
- [x] **ROADMAP.md**: 产品路线图
- [x] **docs/DEV_SETUP.md**: 开发环境配置指南
- [x] **docs/TESTING.md**: 测试指南
- [x] **docs/architecture/SYSTEM_OVERVIEW.md**: 系统架构概览
- [x] **docs/architecture/AI_PIPELINE.md**: AI Pipeline 详细设计
- [x] **docs/architecture/DATABASE_SCHEMA.md**: 数据库 Schema 设计
- [x] **docs/guides/QUICK_START.md**: 快速上手指南
- [x] **docs/guides/IMPORT_YOUR_DOCS.md**: 文档导入指南
- [x] **docs/guides/CUSTOMIZE_PROMPTS.md**: Prompt 自定义指南

### 🔧 代码质量

- [x] **代码格式化**: 所有文件已格式化
- [x] **静态分析**: `flutter analyze` 无错误
- [x] **pubspec.yaml**: 资源路径修复 (`assets/examples/`)
- [x] **GitHub Actions CI**: 自动化测试和构建配置

### 🔒 安全检查

- [x] **.gitignore**: 排除敏感文件 (`.env`, `*.jks`, API keys)
- [x] **示例配置**: `.env.example` 提供模板
- [x] **API Key 配置**: 文档中明确说明如何配置

### 📦 示例资源

- [x] **assets/examples/**: 示例文档和项目
  - Flutter 官方文档示例
  - Riverpod 示例项目
  - Dart 基础示例

---

## 🚧 待完成

### 📝 文档补充

- [ ] **SECURITY.md**: 安全漏洞报告指南
  ```markdown
  # Security Policy
  
  ## Reporting a Vulnerability
  
  如果你发现安全漏洞,请通过以下方式报告:
  - 邮件: security@example.com
  - 不要公开创建 Issue
  
  ## Supported Versions
  
  | Version | Supported          |
  | ------- | ------------------ |
  | 0.1.x   | :white_check_mark: |
  ```

- [ ] **FAQ.md**: 常见问题解答
  - 为什么选择本地优先?
  - 如何备份数据?
  - 支持哪些 AI 模型?
  - 如何贡献翻译?

- [ ] **ARCHITECTURE_DECISIONS.md**: 架构决策记录 (ADR)
  - 为什么用 Drift 而非 sqflite?
  - 为什么用 Riverpod 而非 Provider?
  - 为什么不用向量数据库?

### 🧪 测试覆盖

- [ ] **单元测试**: 核心业务逻辑测试
  - [ ] AI Tasks (KnowledgeExtractionTask, QuestionGenerationTask)
  - [ ] SemanticChunker
  - [ ] QuestionValidator
  - [ ] MasteryService
  - [ ] ReviewSchedulerService

- [ ] **集成测试**: 数据库和 Repository 测试
  - [ ] QuestionRepository
  - [ ] KnowledgePointRepository
  - [ ] SourceRepository

- [ ] **Widget 测试**: 关键 UI 组件测试
  - [ ] QuizCard
  - [ ] KnowledgePointCard
  - [ ] AgentSessionLaunchScreen

- [ ] **测试覆盖率**: 达到 70% 以上

### 🔧 代码优化

- [ ] **移除调试代码**: 清理 `print()` 语句
- [ ] **移除未使用的导入**: 运行 `dart fix --apply`
- [ ] **优化性能**: Profile 模式测试关键流程
- [ ] **减少包体积**: 移除未使用的资源和依赖

### 📦 发布准备

- [ ] **版本号**: 确认为 `0.1.0-alpha`
- [ ] **构建测试**:
  - [ ] Android APK 构建成功
  - [ ] iOS 构建成功 (如有 macOS)
  - [ ] 在真机上测试核心流程

- [ ] **Release Notes**: 编写首个版本的发布说明
  ```markdown
  ## v0.1.0-alpha - 2024-01-XX
  
  ### 🎉 首个公开预览版
  
  **核心功能**:
  - ✅ 文档导入与语义切分
  - ✅ AI 自动生成题目 + 防幻觉验证
  - ✅ 间隔重复复习调度
  - ✅ Learning Agent 对话式学习
  - ✅ 知识库问答 + 引用溯源
  
  **技术特性**:
  - 100% 本地存储,隐私优先
  - 可溯源的知识点和题目
  - 三层防幻觉机制
  
  **已知限制**:
  - 仅支持 OpenAI API (计划支持更多模型)
  - UI 仅中文 (计划国际化)
  - 无云同步 (规划中)
  ```

### 🌐 社区建设

- [ ] **GitHub 仓库设置**:
  - [ ] 添加 Topics: `flutter`, `education`, `ai`, `learning`, `spaced-repetition`
  - [ ] 启用 Discussions
  - [ ] 创建 Issue 模板
  - [ ] 创建 PR 模板
  - [ ] 设置分支保护规则

- [ ] **Issue 模板**:
  - Bug Report
  - Feature Request
  - Documentation Improvement

- [ ] **PR 模板**:
  ```markdown
  ## 变更说明
  
  <!-- 描述本 PR 的变更内容 -->
  
  ## 变更类型
  
  - [ ] Bug 修复
  - [ ] 新功能
  - [ ] 文档更新
  - [ ] 代码重构
  - [ ] 性能优化
  
  ## 测试
  
  - [ ] 已添加单元测试
  - [ ] 已添加集成测试
  - [ ] 已在真机测试
  
  ## Checklist
  
  - [ ] 代码已格式化 (`dart format .`)
  - [ ] 通过静态分析 (`flutter analyze`)
  - [ ] 所有测试通过 (`flutter test`)
  - [ ] 已更新相关文档
  ```

### 📢 推广准备

- [ ] **项目主页**: 创建 GitHub Pages 或独立网站
- [ ] **演示视频**: 录制 3-5 分钟功能演示
- [ ] **截图**: 准备 5-8 张高质量截图
- [ ] **博客文章**: 编写技术博客介绍项目
- [ ] **社交媒体**: 准备推广文案

### 🔍 代码审查

- [ ] **安全审查**: 检查是否有敏感信息泄露
- [ ] **许可证审查**: 确认所有依赖的许可证兼容
- [ ] **代码注释**: 核心算法添加详细注释
- [ ] **API 稳定性**: 标记实验性 API

---

## 🚀 发布流程

### 1. 最终检查

```bash
# 代码质量检查
flutter analyze
dart format --output=none --set-exit-if-changed .

# 运行测试
flutter test --coverage

# 构建 APK
flutter build apk --release

# 构建 iOS (如有)
flutter build ios --release
```

### 2. 打标签

```bash
git tag -a v0.1.0-alpha -m "First public alpha release"
git push origin v0.1.0-alpha
```

### 3. 创建 GitHub Release

- 标题: `v0.1.0-alpha - First Public Preview`
- 描述: 复制 Release Notes
- 附件: 
  - Android APK
  - 源代码 (自动生成)

### 4. 推广

- [ ] 在 GitHub 上发布
- [ ] 在 Reddit (r/FlutterDev) 发帖
- [ ] 在 Twitter/X 发推
- [ ] 在掘金/知乎发文章
- [ ] 在 Flutter 社区分享

---

## 📊 指标追踪

发布后关注以下指标:

- **GitHub**:
  - ⭐ Stars
  - 👁️ Watchers
  - 🍴 Forks
  - 🐛 Issues
  - 🔀 Pull Requests

- **下载量**:
  - APK 下载次数
  - GitHub Release 下载量

- **社区反馈**:
  - 用户反馈 (Issue, Discussion)
  - 社交媒体讨论
  - 博客评论

---

## 🎯 优先级

### P0 - 必须完成 (阻塞发布)

- [ ] SECURITY.md
- [ ] 移除调试代码和敏感信息
- [ ] Android APK 构建测试
- [ ] GitHub 仓库基本设置

### P1 - 强烈建议 (影响体验)

- [ ] 核心业务逻辑单元测试 (≥60% 覆盖率)
- [ ] FAQ.md
- [ ] Issue/PR 模板
- [ ] 演示视频和截图

### P2 - 可推迟 (逐步完善)

- [ ] Widget 测试
- [ ] 性能优化
- [ ] 国际化支持
- [ ] 项目主页

---

## 📝 备注

- **发布时间预估**: 完成 P0 和 P1 任务后 1-2 周
- **维护计划**: 每周检查 Issue,每月发布小版本更新
- **长期目标**: 参考 ROADMAP.md

---

## 🤝 贡献者

感谢所有为本项目做出贡献的开发者!

- 项目发起人: [@yourname](https://github.com/yourname)
- 贡献者列表: 见 [Contributors](https://github.com/Drew-Z/anchor/graphs/contributors)

---

**最后更新**: 2024-01-XX

**下次审查**: 完成 P0 任务后
