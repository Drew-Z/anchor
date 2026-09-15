该项目基于 **Flutter** 框架开发，采用标准的 Flutter 工具链进行编译、测试和打包。构建系统主要由 `pubspec.yaml` 管理 Dart/Flutter 依赖，并通过 Android 原生的 **Gradle (Kotlin DSL)** 处理原生平台的编译与打包。

### 1. 核心构建工具
- **Flutter SDK**: 项目要求 SDK 版本 `^3.5.0`。通过 `flutter run`, `flutter build` 等命令触发跨平台编译。
- **Gradle (Kotlin DSL)**: Android 平台使用 Gradle 9.1.0 进行构建。配置位于 `android/` 目录下，采用 `.kts` 脚本格式。
- **依赖管理**: 
  - Dart 包由 `pubspec.yaml` 定义，锁定文件为 `pubspec.lock`。
  - Android 原生依赖通过 `settings.gradle.kts` 中的插件管理器（Plugin Management）自动加载 Flutter 插件及 Android/Kotlin 插件。

### 2. 关键配置文件
- **`pubspec.yaml`**: 定义应用元数据（名称 `anchor_learning`，版本 `1.0.0+1`）、Dart 依赖（如 `flutter_riverpod`, `dio`）及资源文件路径。
- **`android/build.gradle.kts`**: 根级 Gradle 配置，统一设置仓库源（Google, MavenCentral）并自定义构建输出目录至项目根目录的 `build/` 文件夹。
- **`android/app/build.gradle.kts`**: 应用级配置，指定包名 `cc.eu.playlab.anchor`，编译 SDK 版本跟随 Flutter 配置，Java/Kotlin 编译目标设为 **JVM 17**。
- **`analysis_options.yaml`**: 集成 `flutter_lints` 进行静态代码分析，确保代码规范。

### 3. 构建约定与流程
- **版本管理**: 版本号在 `pubspec.yaml` 中维护（`version: 1.0.0+1`），Android 的 `versionCode` 和 `versionName` 自动从 Flutter 配置中同步。
- **签名配置**: 目前 Release 构建默认使用 Debug 签名（`signingConfigs.getByName("debug")`），正式發布前需在 `android/app/build.gradle.kts` 中配置正式的 Keystore 签名信息。
- **资源管理**: 静态资源（图片、图标）存放于 `assets/images/` 和 `assets/icons/`，并在 `pubspec.yaml` 中声明以便 Flutter 编译器打包。

### 4. 开发者指南
- **环境准备**: 需安装 Flutter SDK (>=3.5.0) 及 Android Studio/NDK。`local.properties` 中需正确配置 `flutter.sdk` 路径。
- **构建命令**:
  - 调试运行: `flutter run`
  - 静态检查: `flutter analyze`
  - Android APK 构建: `flutter build apk --release`
  - 清理构建: `flutter clean` 或 `cd android && ./gradlew clean`
- **注意事项**: 修改 Android 原生配置后，建议执行 `flutter clean` 以避免缓存导致的构建错误。
