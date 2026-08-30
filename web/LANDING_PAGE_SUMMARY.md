# Anchor Web Delivery Summary

## Delivered Surfaces

- `web/landing/index.html`: bilingual product site with persistent locale, responsive navigation, accurate metadata, and CTAs to `/app/`.
- `web/landing/app/index.html`: static learning workspace with a toolbar, dataset sidebar, responsive mobile drawer, answer feedback, explanations, source evidence, scripted tutor hints, completion, recovery, and reset.
- `web/landing/assets/social-preview.png`: production social preview generated from the real demo surface.

Cloudflare Pages publishes `web/landing`, so the product site and demo ship together. The old `web/app` placeholder is not a deployment source.

## Evidence-Bound Claims

- Three bundled datasets contain twelve questions across single-choice, multiple-choice, and boolean formats.
- The demo persists five `localStorage` keys on this browser and device: locale (`anchor.locale`), versioned quiz progress (`anchor.demo.progress.v1`), the library imported from local files (`anchor.demo.library.v1`), the guided Agent session (`anchor.demo.agent.v1`), and the theme preference (`anchor.demo.theme.v1`). All five are listed with their measured sizes in the Profile surface, where progress, library, and the Agent session each have their own confirmed delete control and "clear all local data" removes exactly these five keys.
- Local file import is supported for browser-local reading and storage: a Markdown or text file is parsed in the page and kept in `anchor.demo.library.v1`. Files are not uploaded to a backend or an AI provider.
- No backend, analytics, or live AI provider is part of the demo. Backup export writes a JSON file to the browser's own download folder.
- Scripted tutor hints are explicitly labeled and never presented as a live model response.
- Marketing statistics without versioned experiment evidence were removed.

## Verification

`web/package.json` provides deterministic Node data/state tests plus a Playwright browser suite for the local or deployed site. Together they cover both languages, metadata, every bundled question, citations, tutor disclosure, completion review, library import and search, the guided Agent session, the Profile storage inventory, backup and restore, scoped deletion, theme, recovery/reset, keyboard and ARIA state, desktop/tablet/mobile screenshots, overflow, and the no-off-origin-request boundary. Read test counts from the runner, not from this document.

## 交付摘要（中文）

- 三个内置数据集共十二道题，涵盖单选、多选和判断三种题型。
- 演示在当前浏览器和设备上保存五个 `localStorage` 键：语言选择（`anchor.locale`）、带版本的答题进度（`anchor.demo.progress.v1`）、从本地文件导入的资料库（`anchor.demo.library.v1`）、引导式 Agent 会话（`anchor.demo.agent.v1`）以及主题偏好（`anchor.demo.theme.v1`）。五个键都会在「个人」页面中列出并显示实际占用大小；答题进度、资料库和 Agent 会话各有独立的删除按钮并需确认，「清除全部本地数据」也只删除这五个键。
- 支持导入本地文件，用于在浏览器内读取和保存：Markdown 或文本文件在页面内解析，并保存到 `anchor.demo.library.v1`。文件不会上传到任何后端或 AI 服务。
- 演示不包含后端、分析统计或实时 AI 服务。备份导出只是由浏览器将 JSON 文件写入你自己的下载目录。
- 脚本化的辅导提示都有明确标注，不会被当作实时模型回复呈现。
- 缺少版本化实验证据的营销数据已移除。
- 验证由 `web/package.json` 提供：先运行 Node 的数据与状态测试，再运行 Playwright 浏览器套件。具体测试数量请以运行结果为准，不要以本文档为准。

Production deployment and rollback instructions live in [DEPLOYMENT.md](./DEPLOYMENT.md).
