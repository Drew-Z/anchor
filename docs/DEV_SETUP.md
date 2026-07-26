# 开发环境配置

本文档详细说明如何在本地配置 **Anchor Learning (锚学)** 的开发环境。

---

## 前置要求

### 1. Flutter SDK

- **版本**: Flutter 3.24.0 或更高
- **安装**: [Flutter 官方安装指南](https://flutter.dev/docs/get-started/install)
- **验证安装**:
  ```bash
  flutter doctor -v
  ```

### 2. Dart SDK

- Flutter 3.24.0 已包含 Dart 3.5.0+
- 无需单独安装

### 3. IDE / 编辑器

推荐以下任一工具:

- **VS Code** + Flutter 扩展
- **Android Studio** + Flutter 插件
- **IntelliJ IDEA** + Flutter 插件

### 4. Web Demo 工具链

- Node.js 20 或更高版本
- npm 10 或更高版本
- Chromium (可由 Playwright 自动安装)

### 5. 平台特定要求

#### Android 开发
- Android Studio (推荐)
- Android SDK (API 21+)
- Java JDK 11 或更高

#### iOS 开发 (仅 macOS)
- Xcode 15.0 或更高
- CocoaPods: `sudo gem install cocoapods`
- iOS 模拟器或真机

---

## 项目设置

### 1. 克隆仓库

```bash
git clone https://github.com/Drew-Z/anchor.git
cd anchor
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 本地数据层

项目使用 sqflite 持久化本地 SQLite 数据，并通过手写 repository 管理读写；当前分支不依赖 Drift 或 build_runner 生成数据库代码。数据库文件名保留为 `dlg_q.db`，这是兼容既有安装数据的持久化技术标识，不随 Anchor 品牌名迁移。

### 4. 配置 API Keys

创建 `.env` 文件 (参考 `.env.example`):

```bash
cp .env.example .env
```

编辑 `.env`,填入你的 OpenAI API Key:

```env
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1  # 可选: 自定义 API 端点
```

> ⚠️ **安全提示**: `.env` 已加入 `.gitignore`,不会被提交到 Git。

---

## 运行应用

### 1. 检查设备

```bash
flutter devices
```

### 2. 启动应用

```bash
# 默认设备
flutter run

# 指定设备
flutter run -d <device_id>

# Debug 模式 (默认)
flutter run --debug

# Release 模式 (性能测试)
flutter run --release
```

### 3. 热重载

应用运行时按 `r` 热重载代码,按 `R` 热重启应用。

### 4. 运行 Web Demo

Web Demo 是位于 `web/landing/` 的静态站点，使用预置数据和脚本导师，不会调用 AI 服务或后端。

```bash
cd web
npm ci
npm run serve
```

本地官网位于 `http://127.0.0.1:4173/`，Demo 位于 `http://127.0.0.1:4173/app/`。

---

## 开发工具

### 1. 代码格式化

```bash
# 格式化所有 Dart 文件
dart format .

# 检查格式但不修改
dart format --output=none --set-exit-if-changed .
```

### 2. 静态分析

```bash
# 运行代码分析
flutter analyze --no-fatal-infos

# 修复可自动修复的问题
dart fix --apply
```

### 3. 运行测试

```bash
# 运行所有测试
flutter test

# 生成测试覆盖率
flutter test --coverage

# 查看覆盖率报告 (需要 lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Web 单元测试和浏览器回归测试：

```bash
cd web
npm ci
npx playwright install chromium
npm test

# 对已部署站点运行 12 个 Playwright 用例
ANCHOR_BASE_URL=https://anchor.playlab.eu.cc npm run test:e2e
```

### 4. 调试工具

#### Flutter DevTools
```bash
# 启动 DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

然后在应用运行时访问显示的 URL。

#### 数据库检查

使用 [DB Browser for SQLite](https://sqlitebrowser.org/) 查看本地数据库。实际路径由 sqflite 的 `getDatabasesPath()` 决定，文件名为 `dlg_q.db`；不要依赖文档中写死的应用沙箱绝对路径。

---

## 常见问题

### 1. 依赖冲突

```bash
# 清理缓存后重新安装
flutter clean
flutter pub get
```

### 2. SQLite 本地数据异常

先确认设备存储空间和应用沙箱权限，再检查 `DatabaseHelper` 的 schema migration。开发环境如需从空库复现，可卸载调试应用或清除其本地数据；不要直接修改用户已有的 `dlg_q.db`。

### 3. OpenAI API 调用失败

检查:
- `.env` 文件是否存在且配置正确
- API Key 是否有效
- 网络连接是否正常
- 是否设置了代理 (国内用户)

### 4. iOS 构建失败

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### 5. Android 签名配置 (Release)

创建 `android/key.properties`:

```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=<path-to-keystore.jks>
```

生成 Keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

---

## 项目结构

```
lib/
├── core/               # 核心配置和常量
│   ├── config/
│   ├── constants/
│   └── providers/      # 全局 Riverpod Providers
├── data/               # 数据层
│   ├── database/       # sqflite 数据库与 schema migration
│   ├── models/         # 数据模型
│   └── repositories/   # 数据访问层
├── features/           # 功能模块 (按屏幕/功能分组)
│   ├── agent/          # Agent 工作台
│   ├── home/           # 主页
│   ├── ingestion/      # 文档导入
│   ├── knowledge_base/ # 知识库
│   ├── quiz/           # 答题
│   └── sources/        # 源文档管理
├── services/           # 业务逻辑层
│   ├── ai/             # AI Tasks
│   ├── agent/          # Learning Agent Runtime
│   ├── ingestion/      # 文档处理
│   ├── scheduling/     # 复习调度
│   └── validation/     # 数据验证
└── shared/             # 共享组件和工具
    ├── utils/
    └── widgets/
```

---

## Git 工作流

### 1. 创建功能分支

```bash
git checkout -b feature/your-feature-name
```

### 2. 提交代码

```bash
# 暂存更改
git add .

# 提交 (遵循 Conventional Commits)
git commit -m "feat: 添加新功能"
git commit -m "fix: 修复 bug"
git commit -m "docs: 更新文档"
git commit -m "refactor: 重构代码"
```

### 3. 推送到远程

```bash
git push -u origin feature/your-feature-name
```

### 4. 创建 Pull Request

在 GitHub 上创建 PR,等待代码审查。

---

## CI/CD

项目使用 GitHub Actions 自动化:

- **代码分析**: `flutter analyze --no-fatal-infos` (error 和 warning 阻断，info 级 lint 保留在日志中)
- **格式检查**: `dart format --output=none --set-exit-if-changed .`
- **运行测试**: `flutter test --coverage`
- **Web Demo**: Node 单元测试和 12 个 Chromium Playwright 用例
- **构建 APK**: 仅在 `main` 分支

查看 `.github/workflows/ci.yml` 了解详情。

---

## 性能优化

### 1. Profile 模式运行

```bash
flutter run --profile
```

### 2. 性能分析

使用 DevTools 的 Performance 面板分析:
- Widget 重建频率
- 渲染性能
- 内存使用

### 3. 构建分析

```bash
flutter build apk --analyze-size
```

---

## 下一步

- 阅读 [架构概览](./architecture/SYSTEM_OVERVIEW.md) 了解系统设计
- 查看 [AI Pipeline 设计](./architecture/AI_PIPELINE.md) 了解 AI Tasks
- 参考 [贡献指南](../CONTRIBUTING.md) 了解代码规范

---

## 获取帮助

遇到问题?

1. 查看 [常见问题](#常见问题)
2. 搜索 [GitHub Issues](https://github.com/Drew-Z/anchor/issues)
3. 提交新 Issue 并附上:
   - `flutter doctor -v` 输出
   - 错误日志
   - 复现步骤
