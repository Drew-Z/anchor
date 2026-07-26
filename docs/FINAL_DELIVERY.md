# Anchor Learning 当前交付状态

> 更新于 2026-07-27

## 已具备

- Flutter 本地优先学习应用，覆盖来源导入、知识提取、题目生成、引用校验、答案核验、学习会话和隐私工具。
- Android Private Alpha 的发布检查、测试与运维证据；其他平台不应描述为已经正式支持。
- 公开仓库 `https://github.com/Drew-Z/anchor` 和 MIT 许可证。
- 中英文产品官网与纯前端交互 Demo。
- Demo 提供 Flutter、Git、JavaScript 三套内置数据，共 12 道单选、多选和判断题。
- 每道 Demo 题包含答案解释、稳定 locator、来源摘录和明确标注的预置导师提示。
- Cloudflare Pages 发布目录统一为 `web/landing`，官网与 `/app/` 随同一次静态部署发布。

## 交付边界

- Web Demo 是产品流程样例，不是完整 Flutter Web 版本。
- Demo 不支持上传用户文档，不调用真实 AI，不提供登录、云同步或分析服务。
- Flutter 应用仍保留历史 applicationId、数据库名、Secure Storage key 和环境变量，以保护升级兼容性。
- 官网不再展示缺少可复现实验依据的幻觉率、代码量或文档字数。

## 发布前门禁

```bash
cd web
npm ci
npm test
git diff --check
```

Flutter 客户端发布仍按 `docs/private-alpha-release-checklist.md` 执行，不能用 Web Demo 验收代替原生应用测试。

## 后续工作

- 为 Android Private Alpha 准备正式签名、分发和人工验收材料。
- 在具备真实跨平台兼容证据后，再扩大 Web、iOS、Windows、macOS 或 Linux 的支持声明。
- 如未来进行完整技术改名，必须单独设计 applicationId、数据库和安全存储的兼容迁移。
