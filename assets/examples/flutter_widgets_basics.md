# Flutter Widget 基础示例

> 适合 Flutter 初学者的知识点集合

## Widget 基础

### StatelessWidget

StatelessWidget 是不可变的 Widget。一旦创建,其属性就不能改变。适合用于展示静态内容。

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello World');
  }
}
```

### StatefulWidget

StatefulWidget 是可变的 Widget。通过关联的 State 对象管理状态,可以响应用户交互。

关键方法:
- `initState()`: 初始化,只调用一次
- `build()`: 构建 UI,可能多次调用
- `dispose()`: 清理资源,Widget 销毁时调用

```dart
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // 初始化逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_counter');
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}
```

## 布局 Widget

### Container

Container 是最常用的布局 Widget,可以设置:
- 宽高 (width, height)
- 内边距 (padding)
- 外边距 (margin)
- 背景色 (color)
- 边框 (decoration)

```dart
Container(
  width: 100,
  height: 100,
  padding: EdgeInsets.all(8),
  margin: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text('Container'),
)
```

### Row 和 Column

- Row: 水平排列子 Widget
- Column: 垂直排列子 Widget

主轴对齐 (mainAxisAlignment):
- start: 起始位置
- center: 居中
- end: 结束位置
- spaceBetween: 两端对齐,中间均分
- spaceAround: 每个元素两侧间距相等
- spaceEvenly: 所有间距相等

交叉轴对齐 (crossAxisAlignment):
- start: 起始位置
- center: 居中
- end: 结束位置
- stretch: 拉伸填充

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('A'),
    Text('B'),
    Text('C'),
  ],
)
```

### Expanded 和 Flexible

Expanded 让子 Widget 占据剩余空间:

```dart
Row(
  children: [
    Text('Fixed'),
    Expanded(
      child: Text('Takes remaining space'),
    ),
  ],
)
```

## 生命周期

### StatefulWidget 生命周期

1. **createState()**: 创建 State 对象
2. **initState()**: State 初始化,只调用一次
3. **didChangeDependencies()**: 依赖变化时调用
4. **build()**: 构建 UI,可能多次调用
5. **didUpdateWidget()**: Widget 配置变化时调用
6. **setState()**: 触发重建
7. **deactivate()**: Widget 从树中移除时调用
8. **dispose()**: State 对象永久移除时调用

### 何时使用 setState

当需要更新 UI 时调用 setState:

```dart
void _incrementCounter() {
  setState(() {
    _counter++;  // 修改状态
  });
}
```

注意:
- setState 内只放状态修改代码
- 不要在 dispose 后调用 setState
- setState 是同步的,但 UI 更新是异步的

## BuildContext

BuildContext 代表 Widget 在树中的位置,用于:
- 查找祖先 Widget
- 访问 Theme 和 MediaQuery
- 导航

```dart
// 获取主题
final theme = Theme.of(context);

// 获取屏幕尺寸
final size = MediaQuery.of(context).size;

// 导航
Navigator.of(context).push(...);
```

注意: BuildContext 不能在 dispose 后使用。

## 常见错误

### 1. 在 initState 中使用 BuildContext

错误:
```dart
@override
void initState() {
  super.initState();
  final theme = Theme.of(context);  // 可能报错
}
```

正确:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final theme = Theme.of(context);  // 安全
}
```

### 2. 忘记调用 super

错误:
```dart
@override
void initState() {
  // 忘记调用 super.initState()
  _loadData();
}
```

正确:
```dart
@override
void initState() {
  super.initState();  // 必须先调用
  _loadData();
}
```

### 3. dispose 后调用 setState

错误:
```dart
Future<void> _loadData() async {
  final data = await fetchData();
  setState(() {  // 如果 Widget 已销毁会报错
    _data = data;
  });
}
```

正确:
```dart
Future<void> _loadData() async {
  final data = await fetchData();
  if (mounted) {  // 检查是否还在树中
    setState(() {
      _data = data;
    });
  }
}
```

---

**知识点数量**: 约 12 个  
**难度**: 初级  
**适合**: Flutter 入门学习者
