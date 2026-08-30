# Anchor Learning Web 部署指南

## 发布边界

- Cloudflare Pages 输出目录：`web/landing`
- 产品官网：`https://anchor.playlab.eu.cc/`
- 交互演示：`https://anchor.playlab.eu.cc/app/`（唯一规范地址）
- 直接页面：`https://anchor.playlab.eu.cc/app/index.html`（重定向到 `/app/`）

Demo 必须保存在 `web/landing/app`。同级的 `web/app` 不会进入 Pages 发布物，也不能作为线上入口。

## Demo 规范入口

`/app/` 是 Demo 唯一的规范地址。`web/landing/_redirects` 用永久重定向把 `/app` 和 `/app/index.html` 都指向 `/app/`，因此指向该文档的书签或搜索结果会落到规范地址，而不是同一页面的第二份副本。

`npm run serve` 只是普通静态文件服务器，不读取 `_redirects`，本地请求无法验证该行为。这两条规则由 `npm run test:unit` 针对发布文件断言，并由下面的线上验收针对部署结果核对。

## 本地验证

```bash
cd D:/workspace4Cursor/learn/anchor/web
npm ci
npm test
```

浏览器测试覆盖中英文切换、三套数据、答题、解释、来源引用、预置导师提示、移动端菜单、视觉截图和无外部请求约束。

## 生产部署

只有本地验证通过并审查 Git diff 后，才执行：

```bash
cd D:/workspace4Cursor/learn/anchor/web
npx wrangler pages deploy landing --project-name anchor-learning --branch main
```

仓库文档不得记录 Cloudflare 账号 ID、API Token 或带账号标识的控制台 URL。

## 线上验收

```bash
curl -I https://anchor.playlab.eu.cc/
curl -I https://anchor.playlab.eu.cc/app/
curl -I https://anchor.playlab.eu.cc/app/index.html
curl -sI https://anchor.playlab.eu.cc/app/index.html | grep -i '^location:'
```

必须满足：

- `/` 返回 `200`。
- `/app/` 返回 `200`。
- `/app/index.html` 返回永久重定向（`301` 或 `308`），且 `Location: /app/`。返回 `200` 说明重定向没有发布到线上；返回 `302` 或 `307` 说明发布成了临时重定向，不能让 `/app/` 成为规范地址。

还需在真实浏览器确认：

- 官网与 Demo 返回不同页面。
- 打开 `/app/index.html` 后地址栏停在 `/app/`。
- 语言选择能在两个页面之间持久化。
- 三个数据集都可进入，答题后能看到解释、locator、原文和预置导师提示。
- Demo 不发起模型、分析、上传或后端请求。
- 桌面、平板和手机没有横向溢出或控件遮挡。

## 回滚

从 Cloudflare Pages 部署历史恢复上一个生产版本，并回滚独立的 Web 提交。本次发布不迁移数据库、Android 包名或本地存储标识。
