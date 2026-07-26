# Anchor Learning - 部署指南

## ✅ 已完成的步骤

### 1. Cloudflare Pages 项目创建
- **项目名称**: `anchor-learning`
- **默认 URL**: https://anchor-learning.pages.dev
- **最新部署**: https://0fdf4957.anchor-learning.pages.dev
- **状态**: ✅ 部署成功

### 2. 本地配置文件
- ✅ `wrangler.toml` 已创建
- ✅ `landing/` 目录包含完整的静态网站

---

## 🔧 接下来的步骤

### 步骤 1: 配置自定义域名

通过 Cloudflare 控制台配置 `anchor.playlab.eu.cc`:

1. **打开 Pages 项目**
   - 访问: https://dash.cloudflare.com/2741446a7478f2d8a5ff31df7e077f17/pages/view/anchor-learning

2. **添加自定义域名**
   ```
   进入: Custom domains 标签
   点击: "Set up a custom domain"
   输入: anchor.playlab.eu.cc
   点击: "Continue"
   ```

3. **DNS 配置**
   
   Cloudflare 会自动检测到 `playlab.eu.cc` 域名在同一账户下,并提示:
   
   ```
   ✅ We'll automatically add the DNS records for you
   ```
   
   它会创建以下 CNAME 记录:
   ```
   CNAME  anchor  anchor-learning.pages.dev
   ```

4. **等待激活**
   - 预计时间: 1-5 分钟
   - 状态显示: "Active" 表示配置成功

---

### 步骤 2: 验证部署

配置完成后,访问以下 URL 验证:

1. **Cloudflare Pages 默认域名**
   ```
   https://anchor-learning.pages.dev
   ```

2. **自定义域名**
   ```
   https://anchor.playlab.eu.cc
   ```

3. **检查项目**
   - ✅ 页面加载正常
   - ✅ CSS 样式生效
   - ✅ 所有链接可点击
   - ✅ GitHub 链接指向正确仓库

---

## 📝 后续维护

### 更新网站内容

1. **修改本地文件**
   ```bash
   cd D:/workspace4Cursor/learn/duoduo/web/landing
   # 编辑 index.html 或其他文件
   ```

2. **重新部署**
   ```bash
   cd D:/workspace4Cursor/learn/duoduo/web
   wrangler pages deploy landing --project-name=anchor-learning
   ```

3. **查看部署历史**
   ```bash
   wrangler pages deployment list --project-name=anchor-learning
   ```

### 自动化部署 (可选)

如果你希望每次推送到 GitHub 时自动部署,可以:

1. **在 Cloudflare Pages 控制台中**
   ```
   Settings → Builds & deployments → Connect to Git
   ```

2. **连接 GitHub 仓库**
   ```
   Repository: Drew-Z/anchor
   Production branch: main
   Build directory: web/landing
   ```

3. **配置构建设置**
   ```
   Framework preset: None (static site)
   Build command: (留空)
   Build output directory: /
   ```

---

## 🔗 重要链接

### Cloudflare 控制台
- **Pages 项目**: https://dash.cloudflare.com/2741446a7478f2d8a5ff31df7e077f17/pages/view/anchor-learning
- **域名管理**: https://dash.cloudflare.com/2741446a7478f2d8a5ff31df7e077f17/playlab.eu.cc/dns

### 项目 URL
- **临时 URL**: https://0fdf4957.anchor-learning.pages.dev
- **生产 URL**: https://anchor-learning.pages.dev
- **自定义域名**: https://anchor.playlab.eu.cc (待配置)

### GitHub
- **仓库**: https://github.com/Drew-Z/anchor
- **网站源码**: `/web/landing/`

---

## 🎯 快速命令参考

```bash
# 查看当前认证状态
wrangler whoami

# 列出所有 Pages 项目
wrangler pages project list

# 部署到生产环境
wrangler pages deploy landing --project-name=anchor-learning

# 查看部署历史
wrangler pages deployment list --project-name=anchor-learning

# 查看项目详情
# (需通过控制台查看)
```

---

## ✅ 检查清单

在 GitHub README 中更新网站链接前,请确认:

- [ ] 自定义域名 `anchor.playlab.eu.cc` 配置成功
- [ ] HTTPS 证书已激活
- [ ] 网站可以正常访问
- [ ] 所有页面元素加载正确
- [ ] GitHub 仓库链接指向正确
- [ ] README.md 和 GITHUB_SETUP.md 中的 URL 已更新

---

## 🚀 完成后的最终步骤

1. **更新 README.md**
   ```markdown
   **Website**: `https://anchor.playlab.eu.cc`
   ```

2. **更新 GITHUB_SETUP.md**
   ```markdown
   **Website**: https://anchor.playlab.eu.cc
   ```

3. **提交更改**
   ```bash
   git add .
   git commit -m "docs: update website URL to anchor.playlab.eu.cc"
   git push origin main
   ```

---

**状态**: 🟡 等待自定义域名配置

**下一步**: 在 Cloudflare 控制台添加 `anchor.playlab.eu.cc` 作为自定义域名
