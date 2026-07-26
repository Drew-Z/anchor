# 多多学 Duoduo Learn

> 本地优先的编程学习代理 — 导入你的项目代码或技术文档,构建可溯源的知识库,通过 AI 驱动的面试官、导师和练习会话深度学习,所有证据可追溯到原始来源。

## 产品定位

多多学从"多邻国风格的 AI 拆题刷题工具"演进为**来源可溯源的个人学习代理**,主打场景是程序员技术学习与面试准备:

1. **导入可信来源**:本地项目代码、官方技术文档、开源仓库,保留文件路径、行号、SHA-256 哈希等可审计元数据
2. **构建知识库**:AI 从来源中提取知识点,每个知识点关联具体的源代码片段或文档段落
3. **多模式学习**:
   - **面试官模式**:针对项目或知识点提问,评估你的回答,标记薄弱维度
   - **导师模式**:分层讲解概念,追问卡住的位置,所有解释必须引用来源
   - **练习模式**:生成编程练习或刷题,四维评分(正确性/完整性/工程实践/代码风格)
   - **刷题模式**(保留旧功能):多种题型的游戏化刷题
4. **证据门禁**:AI 输出的每条主张必须附带引用,引用的文本必须逐字命中来源,否则降级或拒答;**AI 输出永远不被当作来源**
5. **复习闭环**:面试弱维度、练习弱项、答错的题目自动进入复习队列,间隔复习算法调度

核心设计理念:**只有经过核验、有来源支撑的内容才能进入正式学习路径和掌握度计算**。

## 功能特色

### 来源管理
- 导入本地项目目录或 ZIP 压缩包(Android 走 Storage Access Framework)
- 手动填写官方文档 URL、出版方、版本号、license 信息
- 每个来源片段保留定位符(文件路径 + 行号范围、页码、章节锚点)
- SHA-256 内容哈希校验,防止来源篡改

### 学习代理(Agent)
- **状态机驱动**:plan → retrieve → act → verify → reflect → complete
- **Checkpoint 持久化**:会话可中断恢复,乐观并发控制防止状态冲突
- **确定性规划**:根据证据覆盖、待核验内容、薄弱先修、到期复习自动规划下一步动作
- **全程 Trace**:每个决策和工具调用都记录事件日志,可审计

### 知识库
- 5 个视图:来源列表、源代码片段、知识点、题目、待核验内容
- 知识点先修关系图,DAG 拓扑排序生成学习路径
- 混合检索:词法打分 + 模型改写查询 + RRF 融合排序
- 引用卡片:点击引用跳转到高亮的源代码片段

### AI 任务层
- 12 个结构化任务:知识抽取、出题、引用核验、面试出题/评分、导师讲解、编程练习生成/评估等
- 统一 JSON schema 输出,解析失败直接报错,不静默降级
- 多供应商支持:OpenAI、DeepSeek、千问、Kimi、智谱、Gemini 等 OpenAI 兼容接口
- **模型验收矩阵**:5 个固定用例(结构化 JSON、中文、编程、主张引用绑定、证据不足拒答),未通过验收的模型组合拒绝调用

### 刷题与游戏化(保留旧功能)
- 6 种题型:单选、多选、判断、填空、匹配、排序
- 填空题 AI 语义判题:本地规则不匹配时调用大模型
- 经验值(XP)、连续打卡(Streak)、心数系统(Hearts)
- 21 个成就徽章、月度打卡日历

### 隐私与数据控制
- 纯本地存储(SQLite + flutter_secure_storage),无云同步
- 产品事件记录(schema 版本化,immutable append-only)
- 隐私控制:数据导出(Markdown/JSON)、分类删除(来源/学习记录/全部)、脱敏诊断包
- SQLite 快照备份,删除前自动备份,误删可恢复

## 技术栈

| 分类 | 技术 |
|------|------|
| 框架 | Flutter 3.x (Dart 3.x) |
| 状态管理 | Riverpod 2.5+ |
| 本地存储 | SQLite (sqflite) v23 schema, 18 张表 |
| 安全存储 | flutter_secure_storage (API keys) |
| 网络请求 | Dio 5.7+ |
| AI 服务 | OpenAI 兼容 API(Chat Completions + Responses) |
| 动画 | flutter_animate 4.5+ |
| 字体 | Google Fonts |
| 文件选择 | file_picker + Android SAF |
| 分享接收 | receive_sharing_intent |

## 项目结构

```
lib/
├── main.dart                      # 入口,FirstRunGate 引导
├── app.dart                       # 底部导航 5-tab
├── core/
│   ├── constants/                 # app_metadata, app_colors
│   ├── providers/                 # Riverpod DI 中枢(1500行)
│   └── theme/                     # app_theme
├── data/
│   ├── database/
│   │   └── database_helper.dart   # SQLite v23, 18张表, 线性迁移
│   ├── models/                    # 16 个模型
│   │   ├── source*.dart           # 来源、片段
│   │   ├── knowledge_point*.dart  # 知识点、先修关系
│   │   ├── grounded_*.dart        # 主张、学习上下文
│   │   ├── learning_session.dart  # 会话(6种mode)
│   │   ├── interview_turn.dart    # 面试轮次
│   │   ├── tutor_turn.dart        # 导师对话
│   │   ├── programming_exercise*.dart  # 编程练习+尝试
│   │   ├── programming_review_action.dart
│   │   ├── product_event.dart     # 产品遥测
│   │   └── [deck, question, study_record, user_stats].dart  # 旧体系
│   └── repositories/              # 10 个薄封装 repo
├── features/
│   ├── onboarding/                # 首次启动 7 步引导
│   ├── agent/                     # Agent 工作台(10个屏幕)
│   │   ├── agent_home_screen.dart
│   │   ├── agent_session_launch_screen.dart
│   │   ├── interview_session_*.dart
│   │   ├── tutor_session_screen.dart
│   │   └── review_agent_screen.dart
│   ├── knowledge_base/            # 知识库 5-tab + 检索
│   ├── ingestion/                 # 来源导入向导 + 核验预览
│   ├── home/                      # 学习首页(旧)
│   ├── deck/                      # 题库列表(旧)
│   ├── learning/                  # 刷题界面(旧)
│   ├── profile/                   # 我的页(XP/勋章/打卡)
│   └── settings/                  # 设置(AI配置/隐私/关于)
├── services/
│   ├── ai/                        # AI 任务层
│   │   ├── tasks/                 # 12 个结构化任务
│   │   ├── ai_api_protocol.dart   # chat_completions vs responses
│   │   ├── ai_api_credential_store.dart
│   │   ├── grounded_claim_gate.dart  # 证据门禁核心
│   │   └── ai_model_acceptance.dart  # 5用例验收矩阵
│   ├── agent/                     # Agent 运行时(33个文件)
│   │   ├── learning_agent_state*.dart
│   │   ├── learning_agent_checkpoint*.dart
│   │   ├── learning_agent_resume_policy.dart
│   │   ├── learning_agent_planner_service.dart
│   │   ├── learning_agent_executor.dart
│   │   ├── learning_agent_workspace.dart
│   │   └── [memory, trace, tool_registry, runtime...]
│   ├── ingestion/                 # 来源导入链路
│   ├── scheduling/                # 复习调度+掌握度+闭环
│   ├── evaluation/                # 正确性评测(离线指标)
│   ├── onboarding/                # 首次启动进度状态机
│   ├── privacy/                   # 产品事件+脱敏+备份+导出
│   ├── release/                   # Private Alpha 发布证据体系
│   ├── openai_service.dart        # 底层 transport(已收编)
│   ├── content_analyzer.dart      # 旧 AI 拆题(保留)
│   └── gamification_service.dart  # XP/心/连击/勋章
├── shared/widgets/                # 公共组件
└── [其他...]

test/                              # 86 个测试文件, 307 个测试
├── golden_path_test.dart          # 旧主链路
├── learning_agent_unified_golden_path_test.dart  # Agent 完整路径
├── programming_learning_golden_path_test.dart
├── correctness_golden_path_test.dart  # 正确性基线
├── database_migration_test.dart   # v2→v23 全量迁移
├── fixtures/                      # 评测数据集+fixture
└── support/                       # fake 服务+CLI 测试支撑

docs/                              # 22 份设计文档
├── execution-roadmap-v2.md        # Branch 15→21 完整路线图
├── agent-architecture.md          # Agent 架构设计
├── private-alpha-*.md             # Alpha 发布相关(7个)
└── [correctness, mvp, golden-path...]

tool/                              # 4 个 Dart CLI
└── private_alpha_*.dart           # 发布就绪检查工具

schema/
└── private-alpha-readiness-v2.schema.json
```

## 数据库 Schema(v23)

18 张表,分 6 个体系:

**旧体系(兼容保留)**
- `decks`, `questions`(加溯源字段), `study_records`, `user_stats`

**来源层**
- `sources`(type, trust_level, uri, publisher, revision, license, content_hash)
- `source_chunks`(content, locator, relative_path, start_line, end_line)

**知识层**
- `knowledge_points`(kind: concept/architecture/dataFlow/...)
- `knowledge_point_sources`(多对多关联 + relation 类型)
- `knowledge_point_prerequisites`(先修 DAG)

**会话层**
- `learning_sessions`(mode: quiz/interview/tutor/agent_session/...)
- `interview_turns`, `tutor_turns`(v22 加 grounded_claims_json)

**Agent 运行时**
- `learning_agent_states`(phase, checkpoint_revision, plan_snapshot)
- `learning_agent_trace_events`(13 种事件类型)

**编程练习**
- `programming_exercises`(四维 rubric, verified 标志)
- `programming_exercise_attempts`
- `programming_review_actions`

**遥测**
- `product_events`(schema 版本化, dedupe_key 幂等)

迁移测试覆盖 v2→v23 全部版本升级路径。

## 快速开始

### 环境要求
- Flutter 3.5+
- Dart 3.5+
- Android SDK (API 21+,推荐 API 36)
- JDK 17+

### 安装运行

```bash
# 克隆仓库
git clone https://github.com/xuanli199/duoduo.git
cd duoduo

# 安装依赖
flutter pub get

# 运行测试
flutter test

# 代码分析
flutter analyze

# 运行 debug
flutter run

# 构建 Release APK
flutter build apk --release
```

### 首次启动引导

APP 首次启动会进入 7 步引导:

1. **选择学习目标**:AI 面试准备 / 项目理解 / 编程基础
2. **配置 AI 模型**:填写 API 地址、Key、模型名,通过 5 用例验收
3. **导入项目**:选择本地目录或 ZIP,标记来源类型(source_code/official_doc)
4. **覆盖度审核**:预览提取的知识点,确认引用正确性
5. **首次会话**:体验面试官或导师模式
6. **结果预览**:查看学习成果和薄弱点
7. **完成**:进入主界面

历史用户(已有 decks/questions 数据)直通主界面。

### 配置 AI 接口

支持任意 OpenAI 兼容接口:

| 供应商 | API 地址示例 | 协议 |
|--------|------------|------|
| OpenAI | `https://api.openai.com/v1` | chat_completions |
| DeepSeek | `https://api.deepseek.com` | chat_completions |
| 阿里千问 | `https://dashscope.aliyuncs.com/compatible-mode/v1` | chat_completions |
| Moonshot | `https://api.moonshot.cn/v1` | chat_completions |
| 智谱 | `https://open.bigmodel.cn/api/paas/v4` | chat_completions |
| 自定义 | 你的中转地址 | 按需选择 |

**重要**:首次配置后会运行 5 个验收用例,全部通过才能用于正式学习:
1. 结构化 JSON 输出
2. 中文理解(七言绝句续写)
3. Dart 编程能力
4. 主张级引用绑定
5. 证据不足时拒答

API Key 存储在 flutter_secure_storage,不会明文落盘。

## 工程质量

- **307 个测试**,覆盖数据库迁移、AI 任务、Agent 状态机、检索排序、正确性评测
- **零 analyzer error/warning**
- **固化基线**:黄金路径集成测试 + 正确性指标(Recall@1, MRR, 引用覆盖率, 拒答准确率)
- **文档驱动**:22 份设计文档,execution roadmap 记录到 Branch 21.6a

## 当前状态

项目处于 **Branch 21 Private Alpha** 收尾阶段:

- ✅ 核心功能完整(来源导入、知识库、Agent、面试/导师/练习、复习闭环)
- ✅ 首次启动引导
- ✅ 隐私控制与数据导出
- ✅ 224 个测试通过
- ⏸️ 发布 HOLD:等待至少一个模型 profile 通过 5/5 验收 + Arm64 真机 release 冒烟
- 🚧 十人内测未启动

## 开发路线图

已完成的 Branch(详见 `docs/execution-roadmap-v2.md`):

- ✅ Branch 15:工程验证与黄金路径
- ✅ Branch 16:项目来源导入 v1
- ✅ Branch 17:项目理解与面试循环
- ✅ Branch 18:编程知识学习循环(先修图+导师+练习+四维评分)
- ✅ Branch 19:正确性与评估(引用覆盖率+拒答门槛+模型验收矩阵)
- ✅ Branch 20:统一知识库学习代理
- 🚧 Branch 21:Private Alpha 产品化(Leaf 21.1~21.6a 完成,21.6 实际内测待启动)

明确延迟的特性(等实际需求触发):
- 多端账号与云同步
- 向量数据库(当前 FTS+词法检索够用)
- 自动 GitHub 克隆
- PDF/视频解析
- 多 Agent 编排

## 许可证

MIT

## 致谢

本项目受 Duolingo 的游戏化设计启发,Agent 架构参考了 LangGraph 的状态机模式,证据门禁理念来自 Anthropic 的 Constitutional AI 论文。
