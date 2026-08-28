import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/source.dart';
import '../models/source_chunk.dart';
import '../models/knowledge_point.dart';
import '../models/knowledge_point_prerequisite.dart';
import '../models/knowledge_point_source.dart';

/// Demo 数据播种器 - 用于新用户首次启动时自动导入示例内容
class DemoDataSeeder {
  final DatabaseHelper _db;

  DemoDataSeeder(this._db);

  /// 导入 Vue.js 核心响应式系统 Demo
  Future<void> seedVueCoreDemo() async {
    final sourceId =
        'demo_vue_reactivity_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // 1. 创建 Source
    final source = Source(
      id: sourceId,
      title: 'Vue.js 响应式系统原理',
      type: SourceType.markdown,
      createdAt: now,
      updatedAt: now,
      contentHash: 'demo_vue_reactivity_v1',
      trustLevel: SourceTrustLevel.officialDoc,
      publisher: 'Vue.js Official',
    );

    await _db.database.then((db) => db.insert('sources', source.toMap()));

    // 2. 创建 Source Chunks (核心概念文档片段)
    final chunks = [
      SourceChunk(
        id: '${sourceId}_chunk_1',
        sourceId: sourceId,
        chunkIndex: 0,
        content: '''# Vue.js 响应式系统核心原理

Vue.js 的响应式系统是其核心特性之一,它使得数据变化能够自动反映到视图上。

## 核心概念

1. **数据劫持(Data Hijacking)**: 通过 Object.defineProperty() 或 Proxy 拦截对象属性的读写操作
2. **依赖收集(Dependency Collection)**: 在数据被读取时,记录哪些组件依赖这个数据
3. **派发更新(Notify Update)**: 数据变化时,通知所有依赖该数据的组件重新渲染''',
        startLine: null,
        endLine: null,
        createdAt: now,
      ),
      SourceChunk(
        id: '${sourceId}_chunk_2',
        sourceId: sourceId,
        chunkIndex: 1,
        content: '''## 响应式原理 (Vue 2.x)

```javascript
function defineReactive(obj, key, val) {
  const dep = new Dep(); // 依赖收集器

  Object.defineProperty(obj, key, {
    get() {
      if (Dep.target) {
        dep.depend(); // 收集依赖
      }
      return val;
    },
    set(newVal) {
      if (newVal === val) return;
      val = newVal;
      dep.notify(); // 通知更新
    }
  });
}
```

**关键点**:
- 每个响应式属性都有一个 Dep 实例
- get 触发时收集依赖(Watcher)
- set 触发时通知所有 Watcher 更新''',
        startLine: null,
        endLine: null,
        createdAt: now,
      ),
      SourceChunk(
        id: '${sourceId}_chunk_3',
        sourceId: sourceId,
        chunkIndex: 2,
        content: '''## Dep 类 - 依赖管理器

```javascript
class Dep {
  constructor() {
    this.subs = []; // 存储所有订阅者(Watcher)
  }

  depend() {
    if (Dep.target) {
      this.subs.push(Dep.target);
    }
  }

  notify() {
    this.subs.forEach(sub => sub.update());
  }
}

Dep.target = null; // 全局唯一的 Watcher
```''',
        startLine: null,
        endLine: null,
        createdAt: now,
      ),
      SourceChunk(
        id: '${sourceId}_chunk_4',
        sourceId: sourceId,
        chunkIndex: 3,
        content: '''## Watcher 类 - 观察者

```javascript
class Watcher {
  constructor(vm, expOrFn, cb) {
    this.vm = vm;
    this.getter = expOrFn;
    this.cb = cb;
    this.value = this.get();
  }

  get() {
    Dep.target = this; // 设置当前 Watcher
    const value = this.getter.call(this.vm);
    Dep.target = null; // 清空
    return value;
  }

  update() {
    const newValue = this.get();
    if (newValue !== this.value) {
      this.cb.call(this.vm, newValue, this.value);
      this.value = newValue;
    }
  }
}
```

**执行流程**:
1. 创建 Watcher 时,调用 get() 方法
2. get() 中设置 Dep.target = this
3. 执行 getter 函数,触发数据的 get 拦截器
4. get 拦截器中调用 dep.depend(),收集当前 Watcher
5. 数据变化时,dep.notify() 通知所有 Watcher 更新''',
        startLine: null,
        endLine: null,
        createdAt: now,
      ),
      SourceChunk(
        id: '${sourceId}_chunk_5',
        sourceId: sourceId,
        chunkIndex: 4,
        content: '''## Vue 3 响应式系统 (Proxy)

Vue 3 使用 Proxy 替代 Object.defineProperty,解决了以下问题:
- 无法检测对象属性的添加和删除
- 无法监听数组下标和 length 的变化

```javascript
function reactive(target) {
  return new Proxy(target, {
    get(target, key, receiver) {
      const result = Reflect.get(target, key, receiver);
      track(target, key); // 依赖收集
      return result;
    },
    set(target, key, value, receiver) {
      const result = Reflect.set(target, key, value, receiver);
      trigger(target, key); // 触发更新
      return result;
    }
  });
}
```

**优势**:
- 可以拦截更多操作(in、delete、has 等)
- 支持数组和 Map/Set 等集合类型
- 性能更好(无需递归遍历所有属性)''',
        startLine: null,
        endLine: null,
        createdAt: now,
      ),
    ];

    for (final chunk in chunks) {
      await _db.database
          .then((db) => db.insert('source_chunks', chunk.toMap()));
    }

    // 3. 创建 Knowledge Points (从内容中提取的知识点)
    final knowledgePoints = [
      KnowledgePoint(
        id: '${sourceId}_kp_1',
        title: 'Object.defineProperty 数据劫持',
        summary:
            '通过 Object.defineProperty 拦截对象属性的 get/set 操作,在 get 时收集依赖,在 set 时触发更新',
        kind: KnowledgePointKind.concept,
        tags: ['vue', 'reactive', 'javascript'],
        difficulty: 2,
        interviewRelevance: 8,
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgePoint(
        id: '${sourceId}_kp_2',
        title: 'Dep 依赖收集器',
        summary: '每个响应式属性对应一个 Dep 实例,负责收集依赖该属性的所有 Watcher,并在属性变化时通知它们更新',
        kind: KnowledgePointKind.dataFlow,
        tags: ['vue', 'dep', 'observer'],
        difficulty: 2,
        interviewRelevance: 7,
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgePoint(
        id: '${sourceId}_kp_3',
        title: 'Watcher 观察者模式',
        summary: 'Watcher 是连接数据和视图的桥梁,在创建时收集依赖,在数据变化时执行回调更新视图',
        kind: KnowledgePointKind.architecture,
        tags: ['vue', 'watcher', 'design-pattern'],
        difficulty: 3,
        interviewRelevance: 9,
        createdAt: now,
        updatedAt: now,
      ),
      KnowledgePoint(
        id: '${sourceId}_kp_4',
        title: 'Proxy 响应式代理',
        summary:
            'Vue 3 使用 Proxy 替代 Object.defineProperty,可以拦截更多操作,支持数组和集合类型,性能更优',
        kind: KnowledgePointKind.implementation,
        tags: ['vue3', 'proxy', 'reactive'],
        difficulty: 2,
        interviewRelevance: 8,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final kp in knowledgePoints) {
      await _db.database
          .then((db) => db.insert('knowledge_points', kp.toMap()));
    }

    // 4. 创建知识点依赖关系，使用当前 schema 的稳定模型字段。
    final prerequisiteRelations = [
      KnowledgePointPrerequisite(
        knowledgePointId: '${sourceId}_kp_3',
        prerequisiteKnowledgePointId: '${sourceId}_kp_2',
        rationale: 'Watcher 依赖 Dep 完成依赖收集。',
        createdAt: now,
      ),
      KnowledgePointPrerequisite(
        knowledgePointId: '${sourceId}_kp_2',
        prerequisiteKnowledgePointId: '${sourceId}_kp_1',
        rationale: 'Dep 依赖 defineReactive 提供属性拦截。',
        createdAt: now,
      ),
    ];
    final db = await _db.database;
    for (final relation in prerequisiteRelations) {
      await db.insert(
        'knowledge_point_prerequisites',
        relation.toMap(),
      );
    }

    // 5. 将知识点关联到实际 source chunks，而不是已废弃的 source_id 字段。
    for (var index = 0; index < knowledgePoints.length; index++) {
      final kp = knowledgePoints[index];
      final chunk = chunks[index + 1];
      await db.insert(
        'knowledge_point_sources',
        KnowledgePointSource(
          knowledgePointId: kp.id,
          sourceChunkId: chunk.id,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
