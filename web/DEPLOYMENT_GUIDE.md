# Anchor Learning Web 部署指南

## 发布边界

- Cloudflare Pages 输出目录：`web/landing`
- 产品官网：`https://anchor.playlab.eu.cc/`
- 交互演示：`https://anchor.playlab.eu.cc/app/`
- 直接页面：`https://anchor.playlab.eu.cc/app/index.html`

Demo 必须保存在 `web/landing/app`。同级的 `web/app` 不会进入 Pages 发布物，也不能作为线上入口。

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
```

还需在真实浏览器确认：

- 官网与 Demo 返回不同页面。
- 语言选择能在两个页面之间持久化。
- 三个数据集都可进入，答题后能看到解释、locator、原文和预置导师提示。
- Demo 不发起模型、分析、上传或后端请求。
- 桌面、平板和手机没有横向溢出或控件遮挡。

## 回滚

从 Cloudflare Pages 部署历史恢复上一个生产版本，并回滚独立的 Web 提交。本次发布不迁移数据库、Android 包名或本地存储标识。
