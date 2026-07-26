# Git 命令速查手册

> Git 常用命令和工作流程

## 基础配置

### 设置用户信息

首次使用 Git 需要配置用户名和邮箱:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

查看配置:
```bash
git config --list
```

### 初始化仓库

创建新仓库:
```bash
git init
```

克隆远程仓库:
```bash
git clone <repository-url>
```

## 基本工作流

### 查看状态

查看当前工作区状态:
```bash
git status
```

简洁模式:
```bash
git status -s
```

### 添加文件

添加单个文件:
```bash
git add filename.txt
```

添加所有修改:
```bash
git add .
```

添加所有 .js 文件:
```bash
git add *.js
```

### 提交更改

提交暂存区的文件:
```bash
git commit -m "commit message"
```

跳过暂存区直接提交已跟踪文件:
```bash
git commit -a -m "commit message"
```

修改最后一次提交:
```bash
git commit --amend
```

### 查看历史

查看提交历史:
```bash
git log
```

简洁的单行格式:
```bash
git log --oneline
```

查看最近 5 条:
```bash
git log -5
```

图形化显示分支:
```bash
git log --graph --oneline --all
```

## 分支管理

### 创建和切换分支

创建新分支:
```bash
git branch feature-login
```

切换到分支:
```bash
git checkout feature-login
```

创建并切换(一步完成):
```bash
git checkout -b feature-login
```

新版本命令:
```bash
git switch -c feature-login
```

### 查看分支

查看所有本地分支:
```bash
git branch
```

查看所有分支(包括远程):
```bash
git branch -a
```

查看分支最后提交:
```bash
git branch -v
```

### 合并分支

将 feature-login 合并到当前分支:
```bash
git merge feature-login
```

取消合并:
```bash
git merge --abort
```

### 删除分支

删除已合并的分支:
```bash
git branch -d feature-login
```

强制删除分支:
```bash
git branch -D feature-login
```

## 远程仓库

### 添加远程仓库

添加远程仓库:
```bash
git remote add origin <repository-url>
```

查看远程仓库:
```bash
git remote -v
```

### 推送代码

推送到远程分支:
```bash
git push origin main
```

首次推送并设置上游分支:
```bash
git push -u origin main
```

推送所有分支:
```bash
git push --all
```

强制推送(危险):
```bash
git push -f origin main
```

### 拉取代码

拉取并合并:
```bash
git pull origin main
```

只拉取不合并:
```bash
git fetch origin
```

## 撤销操作

### 撤销工作区修改

撤销单个文件的修改:
```bash
git checkout -- filename.txt
```

新版本命令:
```bash
git restore filename.txt
```

撤销所有修改:
```bash
git checkout -- .
```

### 撤销暂存区

将文件从暂存区移除(保留修改):
```bash
git reset HEAD filename.txt
```

新版本命令:
```bash
git restore --staged filename.txt
```

### 撤销提交

撤销最后一次提交,保留修改:
```bash
git reset --soft HEAD^
```

撤销最后一次提交,不保留修改:
```bash
git reset --hard HEAD^
```

撤销到指定提交:
```bash
git reset --hard <commit-hash>
```

### 回退文件到历史版本

回退单个文件到指定提交:
```bash
git checkout <commit-hash> -- filename.txt
```

## 标签管理

### 创建标签

创建轻量标签:
```bash
git tag v1.0.0
```

创建附注标签:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
```

为历史提交打标签:
```bash
git tag -a v0.9.0 <commit-hash> -m "Version 0.9.0"
```

### 查看标签

查看所有标签:
```bash
git tag
```

查看标签信息:
```bash
git show v1.0.0
```

### 推送标签

推送单个标签:
```bash
git push origin v1.0.0
```

推送所有标签:
```bash
git push --tags
```

### 删除标签

删除本地标签:
```bash
git tag -d v1.0.0
```

删除远程标签:
```bash
git push origin :refs/tags/v1.0.0
```

## 高级技巧

### 储藏工作区

储藏当前修改:
```bash
git stash
```

查看储藏列表:
```bash
git stash list
```

恢复最近的储藏:
```bash
git stash pop
```

应用指定储藏:
```bash
git stash apply stash@{0}
```

删除储藏:
```bash
git stash drop stash@{0}
```

### 变基

将当前分支变基到 main:
```bash
git rebase main
```

交互式变基(整理提交):
```bash
git rebase -i HEAD~3
```

取消变基:
```bash
git rebase --abort
```

### 查看差异

查看工作区与暂存区的差异:
```bash
git diff
```

查看暂存区与最后提交的差异:
```bash
git diff --staged
```

查看两个提交之间的差异:
```bash
git diff <commit1> <commit2>
```

### Cherry-pick

将其他分支的提交应用到当前分支:
```bash
git cherry-pick <commit-hash>
```

## 常见场景

### 场景1: 提交了敏感信息怎么办?

如果还没推送:
```bash
git reset --soft HEAD^
# 修改文件,移除敏感信息
git add .
git commit -m "remove sensitive data"
```

如果已推送,需要改写历史(危险):
```bash
git filter-branch --tree-filter 'rm -f passwords.txt' HEAD
git push -f
```

### 场景2: 合并冲突如何解决?

1. 执行合并遇到冲突:
```bash
git merge feature-branch
# 提示冲突
```

2. 查看冲突文件:
```bash
git status
```

3. 手动编辑冲突文件,解决冲突标记:
```
<<<<<<< HEAD
current branch content
=======
feature branch content
>>>>>>> feature-branch
```

4. 标记为已解决:
```bash
git add <resolved-file>
```

5. 完成合并:
```bash
git commit
```

### 场景3: 不小心在 main 分支开发了

将当前修改移到新分支:
```bash
git stash
git checkout -b feature-branch
git stash pop
```

### 场景4: 想要放弃本地所有修改

完全重置到远程状态:
```bash
git fetch origin
git reset --hard origin/main
git clean -fd  # 删除未跟踪的文件
```

---

**命令数量**: 约 50 个  
**难度**: 初级-中级  
**适合**: 日常开发使用
