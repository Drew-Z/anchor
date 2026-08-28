该 Flutter 应用采用**代码驱动（Code-First）**的配置策略，结合 **Riverpod** 进行全局状态与服务依赖管理。系统未使用传统的 `.env` 文件或外部配置文件，而是通过以下方式实现配置的层级化管理：

### 1. 核心配置体系
*   **依赖注入与服务定位**：使用 `flutter_riverpod` 作为核心框架。在 `lib/core/providers/providers.dart` 中定义了全局单例服务（如 `DatabaseHelper`, `OpenAIService`）以及派生状态（如 `deckListProvider`）。这种模式确保了配置逻辑的集中化与可测试性。
*   **视觉与主题配置**：采用硬编码常量类管理 UI 配置。`lib/core/constants/app_colors.dart` 定义了 Anchor Learning 游戏化风格的颜色系统；`lib/core/theme/app_theme.dart` 基于 `google_fonts` 和 Material Design 规范构建了统一的 `ThemeData`，并在 `main.dart` 入口处注入。
*   **运行时用户配置**：针对敏感或可变配置（如 OpenAI API Key、模型选择），利用 `shared_preferences` 实现本地持久化存储。`OpenAIService` 封装了读取与写入逻辑，实现了配置与业务逻辑的解耦。

### 2. 关键文件分布
*   `pubspec.yaml`: 定义项目元数据、SDK 约束及第三方依赖版本。
*   `lib/main.dart`: 应用启动入口，负责初始化 `ProviderScope` 并加载全局主题。
*   `lib/core/providers/providers.dart`: 全局状态管理中心，负责服务的实例化与生命周期管理。
*   `lib/core/theme/app_theme.dart` & `lib/core/constants/app_colors.dart`: 视觉表现层的核心配置源。
*   `lib/services/openai_service.dart`: 演示了如何通过本地存储动态管理外部服务配置。

### 3. 开发规范与建议
*   **禁止硬编码敏感信息**：严禁在代码中直接写入 API Key 等敏感数据，必须通过 `SharedPreferences` 或安全的原生渠道获取。
*   **统一通过 Provider 访问状态**：业务组件应通过 `ref.watch` 或 `ref.read` 访问配置与服务，避免直接实例化服务类，以维持依赖注入的一致性。
*   **UI 配置集中化**：所有颜色、字体、间距等视觉参数必须在 `core/constants` 或 `core/theme` 中定义，禁止在 Widget 树中直接使用魔术数字或颜色值。
