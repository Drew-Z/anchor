# Security Policy

## Reporting a Vulnerability

如果你发现 Anchor Learning (锚学) 存在安全漏洞,请负责任地报告。

### 报告方式

**请不要公开创建 GitHub Issue 报告安全漏洞。**

请通过以下方式私密报告:

1. **GitHub Security Advisories** (推荐):
   - 访问 [Security Advisories](https://github.com/Drew-Z/anchor/security/advisories)
   - 点击 "Report a vulnerability"
   - 填写详细信息

2. **邮件报告**:
   - 发送至: security@example.com
   - 主题: `[Security] Anchor Learning Vulnerability Report`
   - 包含详细的漏洞描述、复现步骤和影响范围

### 报告内容应包含

- 漏洞描述和影响范围
- 详细的复现步骤
- 概念验证 (PoC) 代码或截图
- 可能的修复建议 (可选)
- 你的联系方式 (以便跟进)

---

## 响应流程

1. **确认收到**: 24 小时内确认收到报告
2. **初步评估**: 3 个工作日内评估漏洞严重程度
3. **修复开发**: 根据严重程度制定修复计划
4. **发布修复**: 修复后发布安全更新
5. **公开披露**: 修复发布后 7-14 天公开漏洞详情

### 严重程度分级

| 级别 | 修复时间 | 示例 |
|------|---------|------|
| **Critical** | 1-3 天 | 远程代码执行、数据泄露 |
| **High** | 1-2 周 | 权限提升、SQL 注入 |
| **Medium** | 2-4 周 | XSS、CSRF |
| **Low** | 下个版本 | 信息泄露、UI 欺骗 |

---

## 支持的版本

我们仅为最新的稳定版本提供安全更新:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x: (预发布版本)   |

**建议**: 始终使用最新稳定版本。

---

## 安全最佳实践

### 用户端

1. **保护 API Keys**:
   - 不要将 `.env` 文件提交到版本控制
   - 不要在公共场所截图暴露 API Key
   - 定期轮换 OpenAI API Key

2. **数据备份**:
   - 定期备份本地数据库 (`app_database.db`)
   - 导出重要的学习记录

3. **更新应用**:
   - 关注 GitHub Releases 的安全更新
   - 及时升级到最新版本

### 开发者端

1. **代码审查**:
   - 所有 PR 需经过代码审查
   - 关注 OWASP Top 10 安全问题

2. **依赖管理**:
   - 定期运行 `flutter pub outdated`
   - 及时更新有安全漏洞的依赖

3. **敏感数据处理**:
   - 不在日志中输出 API Key
   - 使用 `flutter_secure_storage` 存储敏感配置

---

## 已知安全考虑

### 1. API Key 安全

**风险**: 用户的 OpenAI API Key 存储在本地。

**缓解措施**:
- 使用 SharedPreferences (Android) 和 Keychain (iOS) 存储
- 建议用户设置 API Key 使用限额
- 计划支持用户自建后端代理

### 2. 本地数据存储

**风险**: 数据库未加密,设备被物理访问时可读取。

**缓解措施**:
- Android/iOS 系统级沙箱保护
- 计划在未来版本支持数据库加密

### 3. AI 生成内容

**风险**: AI 生成的题目可能包含错误信息。

**缓解措施**:
- 三层防幻觉验证机制
- 用户最终审核流程
- 引用溯源到源文档

---

## 安全更新通知

安全更新将通过以下渠道发布:

- **GitHub Security Advisories**: [链接](https://github.com/Drew-Z/anchor/security/advisories)
- **GitHub Releases**: 标记为 "Security" 标签
- **README.md**: 置顶安全公告

建议所有用户:
- Watch 本仓库的 Releases
- 订阅 GitHub Security Advisories

---

## 漏洞赏金计划

目前我们是开源项目,暂无资金支持漏洞赏金计划。

但我们会:
- 在 Release Notes 中感谢报告者
- 在 README.md 的 Contributors 中列出
- 提供项目贡献者身份

---

## 联系方式

- **安全问题**: security@example.com
- **一般问题**: [GitHub Issues](https://github.com/Drew-Z/anchor/issues)
- **功能讨论**: [GitHub Discussions](https://github.com/Drew-Z/anchor/discussions)

---

## 致谢

感谢所有负责任地报告安全漏洞的研究者和用户!

**已报告漏洞记录**:
- 暂无 (首次发布)

---

**最后更新**: 2024-01-XX
