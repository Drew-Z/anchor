# GitHub 推送指南

Anchor Learning / 锚学的权威仓库是 `https://github.com/Drew-Z/anchor`，本地目录是 `D:/workspace4Cursor/learn/anchor`。

## 检查当前状态

```bash
cd D:/workspace4Cursor/learn/anchor
git remote -v
git status --short --branch
```

`origin` 应指向 `Drew-Z/anchor`。不要在文档、命令历史或提交中粘贴 Personal Access Token。

## 推送

```bash
git push origin main
```

如需使用 fork，保持上游仓库为只读 `upstream`，并把自己的 fork 配置为 `origin`：

```bash
git remote add upstream https://github.com/Drew-Z/anchor.git
git remote set-url origin https://github.com/<your-account>/anchor.git
```

遇到 403 或 SSH 权限错误时，先用 `gh auth status`、`git remote -v` 和仓库权限页面确认身份，不要通过创建同名旧仓库或把凭据写入 remote URL 来绕过问题。
