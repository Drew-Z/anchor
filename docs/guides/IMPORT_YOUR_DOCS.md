# 导入自己的学习资料

本指南帮助你将个人文档、代码项目、笔记转化为个性化学习内容。

---

## 支持的文件格式

### ✅ 当前支持

| 格式 | 说明 | 切分策略 |
|------|------|----------|
| **Markdown** (`.md`, `.markdown`) | 个人笔记、技术博客 | 按标题层级语义切分 |
| **代码文件** | Dart, JS, Python, Java 等 | 按固定行数切分,保留行号 |
| **纯文本** (`.txt`) | 纯文本笔记 | 按固定行数切分 |

### 🚧 计划支持

- PDF 文档
- Notion 导出的 HTML
- Obsidian Vault
- Jupyter Notebook (`.ipynb`)

---

## Markdown 文档最佳实践

### ✅ 推荐的文档结构

```markdown
# 主题标题

简短介绍...

## 核心概念 1

详细解释...

### 示例

```代码示例```

### 注意事项

常见陷阱...

## 核心概念 2

...
```

**为什么这样好?**
- 清晰的标题层级 → 语义切分更准确
- 每个二级标题是独立知识点 → 便于提取
- 代码块和列表完整 → 不会被切断

### ❌ 避免的情况

```markdown
这是一大段文字没有任何标题结构blablabla持续很多行...
```

**问题**: 无法识别语义边界,只能按行数硬切分。

### 优化建议

1. **添加标题**: 至少使用 `##` 二级标题分隔主要概念
2. **控制长度**: 每个小节 100-300 行为宜
3. **保留代码块**: 使用 ` ``` ` 包裹代码,避免被误切
4. **关键信息加粗**: 帮助 AI 识别重点

---

## 导入代码项目

### 适合导入的项目

- ✅ 你正在学习的开源项目
- ✅ 公司项目的公开文档部分
- ✅ 自己的练手项目,想复习架构

### 不适合的场景

- ❌ 超大项目(10000+ 文件) → 建议只导入核心模块
- ❌ 自动生成的代码(如 `build/`, `node_modules/`)
- ❌ 没有注释的遗留代码 → AI 难以理解

### 导入流程

1. **选择项目目录**
   ```
   点击 "导入项目" → 选择项目根目录
   ```

2. **文件筛选**
   - 系统自动排除:
     - `.git/`, `node_modules/`, `build/`, `.dart_tool/`
     - 二进制文件(图片、视频)
     - 超大文件(>1MB)
   
   - 手动选择:
     - 勾选核心代码目录(如 `lib/`, `src/`)
     - 包含关键文档(`README.md`, `ARCHITECTURE.md`)

3. **预览统计**
   ```
   已选择: 45 个文件
   总大小: 320 KB
   预计生成: 15 个知识点, 30 道题目
   预计费用: $0.10
   ```

4. **开始分析**
   - 第一步: 语义切分(10 秒)
   - 第二步: 理解项目架构(30 秒)
   - 第三步: 提取知识点(40 秒)
   - 第四步: 生成题目(60 秒)
   - 第五步: 验证引用(20 秒)

### 生成的内容

#### A. 项目理解大纲

```
1. 项目架构
   - MVVM 模式
   - Riverpod 状态管理
   - Repository 数据层

2. 核心模块
   - 导入服务: 文档解析和切分
   - AI 管道: 知识提取和题目生成
   - 复习调度: 间隔重复算法

3. 数据流
   [流程图]

4. 关键实现
   - 语义切分算法
   - Citation 验证机制
```

#### B. 代码理解题

```
题目: 以下关于 SemanticChunker 的说法,正确的是?

A. 固定每 100 行切一块
B. 根据 Markdown 标题层级切分
C. 随机切分
D. 不切分,整个文件是一块

答案: B
解析: 根据 lib/services/ingestion/semantic_chunker.dart:45-67,
      chunkMarkdown 方法按 ## 标题识别语义边界。

来源: lib/services/ingestion/semantic_chunker.dart:45-67
```

---

## 导入技巧

### 技巧 1: 分模块导入

**场景**: 项目太大,一次导入超时

**解决方案**: 分批导入不同模块

```
第一批: lib/data/ (数据层)
第二批: lib/services/ (业务逻辑)
第三批: lib/features/ (UI 层)
```

每批会生成独立的 Deck,可以分别学习。

### 技巧 2: 增量更新

**场景**: 文档更新了,不想重新导入全部

**当前方案**(手动):
1. 删除旧的 Source
2. 重新导入更新后的文档

**未来计划**: 自动检测文档变化(基于 `contentHash`)

### 技巧 3: 合并多个来源

**场景**: 一个主题的笔记分散在多个文件

**方案 A**: 手动合并为一个 Markdown
```bash
cat part1.md part2.md part3.md > complete.md
```

**方案 B**: 分别导入,后期在同一个 Deck 中学习

### 技巧 4: 提高题目质量

**在导入前优化文档**:

1. **添加示例**
   ```markdown
   ## StatefulWidget 生命周期
   
   描述...
   
   ### 示例代码
   ```dart
   class MyWidget extends StatefulWidget {
     @override
     State<MyWidget> createState() => _MyWidgetState();
   }
   
   class _MyWidgetState extends State<MyWidget> {
     @override
     void initState() {
       super.initState();
       // 初始化代码
     }
   }
   ```
   ```
   
   → AI 会生成"以下代码执行顺序"类的实践题

2. **标注重点**
   ```markdown
   **核心要点**: initState 只调用一次
   ⚠️ **常见错误**: 在 dispose 后调用 setState
   ```
   
   → AI 会生成针对这些点的题目

3. **包含对比**
   ```markdown
   ## StatelessWidget vs StatefulWidget
   
   | 特性 | StatelessWidget | StatefulWidget |
   |------|----------------|---------------|
   | 状态 | 不可变 | 可变 |
   | 性能 | 更快 | 略慢 |
   ```
   
   → AI 会生成对比类选择题

---

## 文件组织建议

### 推荐的目录结构

```
我的学习资料/
├── Programming/
│   ├── Flutter/
│   │   ├── basics.md
│   │   ├── state-management.md
│   │   └── projects/
│   │       └── my-app/
│   ├── Python/
│   │   └── async-io.md
│   └── ...
├── Frameworks/
│   └── React/
│       └── hooks.md
└── Tools/
    └── Git/
        └── commands.md
```

**优势**:
- 按主题分类 → 容易找到要导入的内容
- 一个主题一个 Deck → 学习路径清晰

---

## Troubleshooting

### 问题 1: 导入后没有生成题目

**可能原因**:
- 文档太短(<100 行) → AI 认为没有足够内容
- 文档是代码为主,注释很少 → AI 难以理解

**解决方案**:
1. 添加文档注释说明代码逻辑
2. 或手动创建题目

### 问题 2: 生成的题目质量不高

**可能原因**:
- 文档描述模糊
- 缺少具体示例

**解决方案**:
1. 查看生成的题目
2. 在审核界面删除低质量题目
3. 优化文档后重新导入

### 问题 3: 引用验证失败

**现象**: 题目标记为 "pending"(待核验)

**原因**: AI 引用了不存在的 chunk,或引用不支持答案

**解决方案**:
1. 在审核界面点击 "查看来源"
2. 检查引用是否合理
3. 可以手动修改题目,或删除

### 问题 4: 代码文件切分不合理

**现象**: 一个函数被切成两块

**原因**: 函数太长,超过了默认的 160 行切分阈值

**解决方案**:
1. 调整切分参数(见[自定义配置](#自定义切分参数))
2. 或重构代码,函数保持简短

---

## 自定义切分参数

编辑 `lib/services/ingestion/project_source_import_service.dart`:

```dart
List<SourceChunk> buildSourceChunks({
  required ProjectSourceSnapshot snapshot,
  required Set<String> selectedPaths,
  required String sourceId,
  required DateTime createdAt,
  int maxLinesPerChunk = 160, // 改为 200 或更大
}) {
  // ...
}
```

**推荐值**:
- Markdown: 不需要调整(自动按标题切分)
- 代码文件: 
  - 简短函数为主: 100 行
  - 包含长类定义: 200 行
  - 大型遗留代码: 300 行

---

## 高级用法: 批量导入

**场景**: 有 100 个 Markdown 笔记要导入

**脚本示例**(未来功能):

```bash
# 遍历目录,批量导入
for file in notes/*.md; do
  flutter run --dart-define=IMPORT_FILE="$file"
done
```

**当前替代方案**:
1. 合并为一个大 Markdown
2. 或手动逐个导入(推荐每次 5-10 个文件)

---

## 隐私提醒

### 敏感信息检查

导入前请确认文档中没有:
- ❌ API Keys / Tokens
- ❌ 密码 / 私钥
- ❌ 个人身份信息
- ❌ 公司机密代码

**数据去向**:
1. 本地存储: SQLite 数据库(不上传)
2. OpenAI API: 仅发送文档内容用于生成题目
3. 可选云同步: 未来功能,用户自主选择

### 删除导入的内容

```
设置 → 知识库管理 → 选择 Source → 删除
```

删除后:
- 关联的知识点被删除
- 生成的题目被删除
- 学习记录保留(用于统计)

---

## 示例文档模板

### 模板 1: 技术笔记

```markdown
# React Hooks 学习笔记

> 学习时间: 2024-01-15
> 参考资料: React 官方文档

## useState

### 基本用法

`useState` 是最常用的 Hook...

```jsx
const [count, setCount] = useState(0);
```

### 注意事项

⚠️ **不要在循环/条件中使用 Hooks**

原因: ...

## useEffect

...
```

### 模板 2: 代码项目说明

```markdown
# 项目名称

## 架构设计

本项目采用 Clean Architecture...

### 目录结构

```
lib/
├── data/       # 数据层
├── domain/     # 业务逻辑
└── presentation/ # UI 层
```

## 核心模块

### 用户认证模块

位置: `lib/features/auth/`

流程:
1. 用户输入
2. 验证
3. Token 存储

关键代码: `auth_service.dart:45-67`

...
```

---

## 下一步

- [自定义 AI Prompt](./CUSTOMIZE_PROMPTS.md) - 调整生成策略
- [系统架构](../architecture/SYSTEM_OVERVIEW.md) - 理解切分原理
- [贡献指南](../../CONTRIBUTING.md) - 帮助改进导入功能

---

**导入遇到问题?** [提交 Issue](https://github.com/你的用户名/duoduo/issues) 或加入 [Discord](https://discord.gg/你的邀请)
