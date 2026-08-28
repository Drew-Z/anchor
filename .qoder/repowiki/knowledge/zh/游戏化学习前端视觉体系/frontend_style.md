该应用采用 Flutter 框架实现跨平台 UI，通过高度定制化的主题系统和组件库形成 Anchor Learning 自有的高反馈游戏化学习视觉风格。

### 1. 核心系统与工具
- **UI 框架**: Flutter (Material Design 基础，但进行了深度定制)。
- **字体系统**: 使用 `google_fonts` 包引入 `Nunito` 字体，以匹配 Anchor Learning 圆润、活泼的视觉特征。
- **状态管理**: 结合 `flutter_riverpod` 管理 UI 状态，确保视觉反馈（如按钮按压、进度条更新）与业务逻辑同步。

### 2. 设计令牌 (Design Tokens)
在 `lib/core/constants/app_colors.dart` 中定义了严格的品牌色板：
- **主色调**: 品牌绿 (`#58CC02`)、品牌蓝 (`#1CB0F6`)、警示红 (`#FF4B4B`)、奖励金 (`#FFC800`)。
- **中性色**: 背景白 (`#FFFFFF`)、浅灰表面 (`#F7F7F7`)、深灰文本 (`#4B4B4B`)。
- **交互色**: 每个主色都配有 `Dark` (用于边框/阴影) 和 `Light` (用于背景/高亮) 变体，以构建 3D 质感。

### 3. 架构与组件规范
- **主题配置**: `lib/core/theme/app_theme.dart` 统一定义了全局样式。禁用 Material 3 默认效果 (`useMaterial3: false`)，转而使用圆角半径 `16px`、无阴影扁平化卡片以及自定义的输入框边框。
- **3D 凸起按钮**: `lib/shared/widgets/anchor_button.dart` 实现了核心的 Anchor 风格按钮。通过 `GestureDetector` 监听按压状态，动态调整 `AnimatedContainer` 的底部边框宽度（4px -> 2px）和垂直位移，模拟真实的物理按压反馈。
- **游戏化 HUD**: `lib/shared/widgets/stats_widgets.dart` 提供了顶部状态栏和答题进度条，统一使用粗体字重 (`FontWeight.w800`) 和高饱和度图标，强化学习应用的 gamification 氛围。

### 4. 开发者准则
- **圆角一致性**: 所有卡片、按钮、输入框及进度条必须使用 `BorderRadius.circular(16)`（小元素如进度条可用 8px）。
- **字重规范**: 标题和关键数据必须使用 `FontWeight.w800` (ExtraBold)，正文使用 `w500` 或 `w600`，避免使用细体字。
- **交互反馈**: 任何可点击元素都应具备明确的视觉反馈（如颜色变深或位置下沉），严禁使用默认的 Material Ripple 效果代替品牌特有的 3D 按压动效。
- **色彩使用**: 严禁直接使用 `Colors.green` 等原生色，必须引用 `AppColors` 中定义的品牌色值，以确保全平台视觉一致性。
