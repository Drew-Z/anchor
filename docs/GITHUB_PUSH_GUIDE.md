# GitHub 推送配置指南

## 问题

推送代码时遇到权限错误:
```
remote: Permission to bill/duoduo.git denied to ciallo-bill.
fatal: unable to access 'https://github.com/bill/anchor.git/': The requested URL returned error: 403
```

**原因**: 本地 git 凭据是 `ciallo-bill`,但远程仓库属于 `bill`

---

## 解决方案

### 选项 1: 使用 bill 账号 (推荐)

#### 步骤 1: 创建 GitHub 仓库
1. 访问 https://github.com/bill
2. 点击 "New repository"
3. 仓库名: `duoduo`
4. 描述: "来源可溯源的 AI 学习助手"
5. Public
6. 不要初始化 README (我们已经有了)
7. 创建仓库

#### 步骤 2: 推送代码
```bash
# 如果仓库是新的
cd D:/workspace4Cursor/learn/duoduo
git push -u origin main

# 如果需要输入凭据,使用 bill 的 GitHub Personal Access Token
```

#### 步骤 3: 生成 Personal Access Token (如果需要)
1. GitHub 右上角头像 → Settings
2. Developer settings → Personal access tokens → Tokens (classic)
3. Generate new token
4. 勾选 `repo` 权限
5. 生成后复制 token (只显示一次)
6. 推送时用 token 作为密码

---

### 选项 2: 使用当前的 ciallo-bill 账号

如果 `ciallo-bill` 就是你的主账号,修改远程仓库地址:

```bash
cd D:/workspace4Cursor/learn/duoduo
git remote set-url origin https://github.com/ciallo-bill/duoduo.git
```

然后在 GitHub 上创建 `ciallo-bill/duoduo` 仓库,再推送。

**注意**: 这样的话需要更新所有文档中的 GitHub 链接。

---

### 选项 3: 添加 ciallo-bill 为协作者

如果 `bill` 是组织/团队账号,可以将 `ciallo-bill` 添加为协作者:

1. 在 GitHub 仓库页面
2. Settings → Collaborators
3. 添加 `ciallo-bill`

---

## 推荐做法

**如果 bill 是你的主 GitHub 账号**:
1. 在 GitHub 上创建 `bill/duoduo` 仓库
2. 生成 Personal Access Token
3. 推送时使用 token

**如果 ciallo-bill 是你的主账号**:
1. 修改远程地址为 `ciallo-bill/duoduo`
2. 批量替换文档中的用户名
3. 推送代码

---

## 你需要做什么

告诉我:
1. **bill** 和 **ciallo-bill** 哪个是你想用于开源项目的主账号?
2. 你是否已经在 GitHub 上创建了 `duoduo` 仓库?

然后我会帮你完成推送和后续配置。
