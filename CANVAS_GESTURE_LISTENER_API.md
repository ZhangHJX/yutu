# 🎯 CanvasGestureListener API 文档

## 概述

`CanvasGestureListener` 是一个自定义 Widget，封装了 `Listener` 和 `GestureDetector` 的功能，提供统一的手势处理接口。

## 🏗️ 架构

```
CanvasGestureListener (封装组件)
    ├─ Listener (低级指针事件)
    │  ├─ onPointerDown
    │  ├─ onPointerMove
    │  ├─ onPointerUp
    │  └─ onPointerCancel
    │
    └─ GestureDetector (高级手势)
       ├─ onTap
       ├─ onLongPress
       └─ onDoubleTap
           └─ child
```

## 📖 API 参考

### 构造函数

```dart
const CanvasGestureListener({
  Key? key,
  VoidCallback? onPointerDown,
  VoidCallback? onPointerMove,
  VoidCallback? onPointerUp,
  VoidCallback? onPointerCancel,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  VoidCallback? onDoubleTap,
  required Widget child,
})
```

### 属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `onPointerDown` | `Function(PointerDownEvent)?` | 指针按下回调 |
| `onPointerMove` | `Function(PointerMoveEvent)?` | 指针移动回调 |
| `onPointerUp` | `Function(PointerUpEvent)?` | 指针抬起回调 |
| `onPointerCancel` | `Function(PointerCancelEvent)?` | 指针取消回调 |
| `onTap` | `VoidCallback?` | 单击回调 |
| `onLongPress` | `VoidCallback?` | 长按回调 |
| `onDoubleTap` | `VoidCallback?` | 双击回调 |
| `child` | `Widget` | 子组件（必需） |

## 💡 使用示例

### 基础使用

```dart
CanvasGestureListener(
  onPointerDown: (event) {
    print('Pointer down at ${event.position}');
  },
  onPointerMove: (event) {
    print('Pointer moving at ${event.position}');
  },
  onPointerUp: (event) {
    print('Pointer up at ${event.position}');
  },
  onTap: () {
    print('Canvas tapped');
  },
  child: Container(
    color: Colors.white,
    child: Text('Touch me!'),
  ),
)
```

### 在 CanvasEditorPage 中的使用

```dart
CanvasGestureListener(
  onPointerDown: (event) {
    _handlePointerEvent(event, (localEvent) {
      final canvasState = _canvasKey.currentState;
      if (canvasState != null) {
        final hitElement = canvasState.detectHitElement(localEvent.position);
        if (hitElement != null) {
          canvasState.handlePointerDown(localEvent);
        } else {
          _canvasStatusManager.handlePointerDown(event);
        }
      }
    });
  },
  onPointerMove: (event) {
    // 处理移动
  },
  onPointerUp: (event) {
    // 处理抬起
  },
  onPointerCancel: (event) {
    // 处理取消
  },
  onTap: () {
    // 处理点击反馈
    print('Canvas tapped');
  },
  onLongPress: () {
    // 处理长按
    _showContextMenu();
  },
  onDoubleTap: () {
    // 处理双击
    _canvasStatusManager.zoomToFit();
  },
  child: Container(
    // 布局内容
  ),
)
```

## 🎯 常见场景

### 1. 添加点击反馈

```dart
CanvasGestureListener(
  onTap: () {
    // 添加声音反馈
    AudioService.playTapSound();
    
    // 添加视觉反馈
    setState(() {
      _showTapAnimation = true;
    });
    
    // 延迟重置
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _showTapAnimation = false;
      });
    });
  },
  child: child,
)
```

### 2. 添加长按菜单

```dart
CanvasGestureListener(
  onLongPress: () {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('选项'),
        children: [
          SimpleDialogOption(
            onPressed: () => _delete(),
            child: Text('删除'),
          ),
          SimpleDialogOption(
            onPressed: () => _duplicate(),
            child: Text('复制'),
          ),
        ],
      ),
    );
  },
  child: child,
)
```

### 3. 添加双击缩放

```dart
CanvasGestureListener(
  onDoubleTap: () {
    // 双击时自动适应屏幕
    _canvasStatusManager.reset();
    
    setState(() {
      _canvasOffset = Offset.zero;
      _canvasScale = 1.0;
    });
  },
  child: child,
)
```

### 4. 禁用特定手势

```dart
CanvasGestureListener(
  onPointerDown: (event) { /* 保留 */ },
  onPointerMove: (event) { /* 保留 */ },
  onPointerUp: (event) { /* 保留 */ },
  // 不设置 onTap - 禁用点击反馈
  // 不设置 onLongPress - 禁用长按
  child: child,
)
```

## 📊 事件流程

### 点击事件流程

```
User Touch
    ↓
Listener.onPointerDown
    ↓
GestureDetector 检测
    ↓
识别为点击（Tap）
    ↓
GestureDetector.onTap
```

### 拖动事件流程

```
User Touch & Move
    ↓
Listener.onPointerDown
    ↓
Listener.onPointerMove (multiple times)
    ↓
Listener.onPointerUp
```

### 长按事件流程

```
User Hold
    ↓
Listener.onPointerDown
    ↓
等待 ~500ms (GestureDetector 内置)
    ↓
GestureDetector.onLongPress
    ↓
Listener.onPointerUp (当用户释放)
```

## 🔄 与原生 Listener/GestureDetector 的比较

### 原生方式

```dart
Listener(
  onPointerDown: (event) { /* ... */ },
  onPointerMove: (event) { /* ... */ },
  onPointerUp: (event) { /* ... */ },
  onPointerCancel: (event) { /* ... */ },
  child: GestureDetector(
    onTap: () { /* ... */ },
    onLongPress: () { /* ... */ },
    onDoubleTap: () { /* ... */ },
    child: Container(...),
  ),
)
```

### 使用 CanvasGestureListener

```dart
CanvasGestureListener(
  onPointerDown: (event) { /* ... */ },
  onPointerMove: (event) { /* ... */ },
  onPointerUp: (event) { /* ... */ },
  onPointerCancel: (event) { /* ... */ },
  onTap: () { /* ... */ },
  onLongPress: () { /* ... */ },
  onDoubleTap: () { /* ... */ },
  child: Container(...),
)
```

**优势**:
- ✅ 更简洁清晰
- ✅ 减少嵌套层数
- ✅ API 统一
- ✅ 易于维护

## 🚀 扩展功能

### 添加新的手势类型

要添加新的手势类型，只需修改 `CanvasGestureListener`：

```dart
/// 滑动回调
final void Function(DragStartDetails)? onHorizontalDragStart;

@override
Widget build(BuildContext context) {
  return Listener(
    // ...
    child: GestureDetector(
      onHorizontalDragStart: onHorizontalDragStart,
      // ...
      child: child,
    ),
  );
}
```

### 添加自定义手势识别

```dart
class CustomCanvasGestureListener extends CanvasGestureListener {
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const CustomCanvasGestureListener({
    // ... 其他参数
    this.onSwipeLeft,
    this.onSwipeRight,
    required Widget child,
  }) : super(child: child);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          onSwipeLeft?.call();
        } else {
          onSwipeRight?.call();
        }
      },
      child: super.build(context),
    );
  }
}
```

## ✅ 检查清单

### 使用前

- [ ] 已导入 `CanvasGestureListener`
- [ ] 子组件已准备好
- [ ] 回调函数已定义

### 使用时

- [ ] 正确设置需要的回调
- [ ] 不需要的回调设为 `null`（可选）
- [ ] 确保 `child` 不为空

### 使用后

- [ ] 测试所有启用的手势
- [ ] 验证事件优先级
- [ ] 性能测试（如需要）

## 📈 性能考虑

### 优化建议

1. **只启用需要的手势**
   ```dart
   // ✅ 好：只启用需要的回调
   CanvasGestureListener(
     onPointerDown: (event) { /* ... */ },
     onPointerMove: (event) { /* ... */ },
     // 不设置 onTap 如果不需要
     child: child,
   )
   ```

2. **避免在回调中进行重操作**
   ```dart
   // ❌ 不好：在回调中进行复杂计算
   onPointerMove: (event) {
     final result = expensiveCalculation(event.position);
     updateUI(result);
   }

   // ✅ 好：使用防抖或节流
   onPointerMove: (event) {
     _debounce(() {
       final result = expensiveCalculation(event.position);
       updateUI(result);
     });
   }
   ```

3. **合理使用 setState**
   ```dart
   // ❌ 不好：每次移动都调用 setState
   onPointerMove: (event) {
     setState(() {
       _position = event.position;
     });
   }

   // ✅ 好：批量更新或使用其他状态管理
   onPointerMove: (event) {
     _position = event.position;
     // 需要时才调用 setState
   }
   ```

## 🔧 故障排除

### 手势不响应

**可能原因**:
1. 回调为 `null`
2. `behavior` 设置不对
3. 子组件拦截了事件

**解决方案**:
```dart
// 检查 behavior
CanvasGestureListener(
  // ...
  child: Container(
    // 确保 Container 有适当的大小
    width: double.infinity,
    height: double.infinity,
  ),
)
```

### 多个手势冲突

**可能原因**:
1. 点击被识别为长按
2. 拖动被识别为点击

**解决方案**:
```dart
// 使用 GestureDetector 的参数控制
// 在 CanvasGestureListener 中添加配置
```

## 📚 相关文档

- [Flutter Listener 文档](https://api.flutter.dev/flutter/widgets/Listener-class.html)
- [Flutter GestureDetector 文档](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [手势库](https://api.flutter.dev/flutter/gestures/gestures-library.html)

## 🎉 总结

`CanvasGestureListener` 提供了：

1. **简化的 API** - 统一的手势处理接口
2. **灵活的配置** - 支持多种手势类型
3. **清晰的代码** - 减少嵌套，易于理解
4. **易于扩展** - 支持添加新的手势类型

**使用建议**:
- ✅ 用于需要处理多种手势的场景
- ✅ 用于需要统一手势处理接口的组件
- ✅ 用于降低代码复杂度的项目

---

**版本**: 1.0
**状态**: ✅ 生产就绪
**最后更新**: 当前

