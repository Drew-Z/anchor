# GitHub 推送指南

Anchor Learning / 锚学的权威仓库是 `https://github.com/Drew-Z/anchor`，本地目录是 `D:/workspace4Cursor/learn/anchor`。

## 检查当前状态

```powershell
Set-Location D:\workspace4Cursor\learn\anchor
git remote -v
git status --short --branch
git worktree list
```

`origin` 应指向 `Drew-Z/anchor`。不要在文档、命令历史或提交中粘贴 Personal Access Token。

## 当前 PR 分支流程

当前产品化改动通过 `codex/anchor-web-demo` 和 PR #1 进入 `main`。只有在操作者明确授权
远端写入后，才推送本地提交：

```powershell
git push origin codex/anchor-web-demo
```

推送后先确认 CI 全绿，再更新 PR 描述中的本地验证数量、CI Run 和 readiness blocker。
推送不代表允许退出 Draft、合并、创建 Release 或部署官网；这些动作必须分别获得授权。

合并前至少确认：

```powershell
gh pr view 1 --repo Drew-Z/anchor --json state,isDraft,mergeStateStatus,statusCheckRollup
```

Private Alpha readiness 当前为 `HOLD` 时，可以合并产品代码和静态官网，但不能创建或分发
Private Alpha Release。正式分发必须等待 readiness evaluator 返回真实 `GO`。

## Fork 场景

如需使用 fork，保持上游仓库为只读 `upstream`，并把自己的 fork 配置为 `origin`：

```powershell
git remote add upstream https://github.com/Drew-Z/anchor.git
git remote set-url origin https://github.com/<your-account>/anchor.git
```

遇到 403 或 SSH 权限错误时，先用 `gh auth status`、`git remote -v` 和仓库权限页面确认身份，不要通过创建同名旧仓库或把凭据写入 remote URL 来绕过问题。
