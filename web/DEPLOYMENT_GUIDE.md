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

## 缓存策略

缓存策略写在 `web/landing/_headers`，只有两类，并以保守的那一类为默认：

- `/assets/*` 使用 `public, max-age=86400, stale-while-revalidate=604800, no-transform`。图片和图标通过发布新文件替换，而不是原地修改已发布文件，因此缓存副本不会与加载它的页面自相矛盾。
- 所有发布的 HTML 文档、脚本和样式表使用 `public, max-age=0, must-revalidate, no-transform`。响应仍然可缓存，但缓存只能在源站确认其仍为最新之后才可复用：代价是一次条件请求，内容未变时返回 `304`。

第二类之所以严格，是因为这些文件都没有内容哈希，而现有的 `?v=` 版本号并不完整：`app.js` 带版本号，但它导入的 `data.js` 没有；`i18n.js` 既被带版本号地请求，也被不带版本号地请求。若不强制重新验证，浏览器可能把过期模块与新文档搭配运行，而这种组合从未作为整体发布过。

这些规则显式列出路径，而不依赖后缀通配：`/`、`/index.html`、`/404.html`、`/app/`、`/app/index.html`，以及 `/assets/*` 已经验证过的前缀写法 `/scripts/*`、`/styles/*`、`/app/scripts/*`、`/app/styles/*`。每个块都写出完整的 `Cache-Control` 值，因此没有任何路径依赖从 `/*` 基线继承；每个值都以 `no-transform` 结尾，使基线自身的 `Cache-Control` 始终是它的子集。

该策略是纯静态、不依赖任何服务方：没有 Service Worker，没有运行时缓存，也没有 cache-busting 代码。向发布物新增文档、脚本或样式表时必须同时新增对应规则。`npm run test:unit` 会从磁盘读取已发布的 `_headers`，断言必需的路径与指令，并在某个已发布文件缺少规则时失败。

`npm run serve` 同样不读取 `_headers`，本地请求无法呈现这些响应头。发布文件即契约，实际响应头由下面的线上验收核对。

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

for path in / /app/ /app/scripts/app.js /app/scripts/data.js /app/styles/app.css /scripts/main.js /scripts/i18n.js /styles/main.css /assets/anchor-icon.svg; do
  printf '%s ' "$path"
  curl -sI "https://anchor.playlab.eu.cc$path" | grep -i '^cache-control:'
done
```

必须满足：

- `/` 返回 `200`。
- `/app/` 返回 `200`。
- `/app/index.html` 返回永久重定向（`301` 或 `308`），且 `Location: /app/`。返回 `200` 说明重定向没有发布到线上；返回 `302` 或 `307` 说明发布成了临时重定向，不能让 `/app/` 成为规范地址。
- 循环里的每个路径都返回 `Cache-Control`。`/assets/anchor-icon.svg` 返回 `max-age=86400` 且带 `stale-while-revalidate=604800`；其余路径返回 `max-age=0` 且带 `must-revalidate`；所有路径都带 `no-transform`。
- 缺少 `Cache-Control`、缺少 `must-revalidate`，或 `/assets/` 之外出现大于零的 `max-age`，都说明该路径的 `_headers` 规则没有发布到线上。本仓库没有观测过这些线上响应，请在部署后执行上述循环并记录实际结果。

还需在真实浏览器确认：

- 官网与 Demo 返回不同页面。
- 打开 `/app/index.html` 后地址栏停在 `/app/`。
- 语言选择能在两个页面之间持久化。
- 三个数据集都可进入，答题后能看到解释、locator、原文和预置导师提示。
- Demo 不发起模型、分析、上传或后端请求。
- 桌面、平板和手机没有横向溢出或控件遮挡。

## 回滚

从 Cloudflare Pages 部署历史恢复上一个生产版本，并回滚独立的 Web 提交。本次发布不迁移数据库、Android 包名或本地存储标识。
