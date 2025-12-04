# 画布元素边缘吸附功能

## 功能概述

在画布编辑器中，当移动元素时，系统会自动检测与其他元素的边缘对齐，并提供吸附效果和视觉参考线。

## 实现细节

### 1. 核心组件

#### ElementSnapHelper (元素吸附辅助类)
位置：`lib/ui/canvas/gesture/element_snap_helper.dart`

主要功能：
- 检测移动元素与其他元素的边缘距离
- 计算吸附位置
- 生成参考线数据

支持的吸附类型：
- **边缘对齐**：左、右、上、下边缘
- **中心对齐**：水平中心、垂直中心（更高优先级）

#### 吸附阈值
- 默认吸附阈值：`5.0` 像素
- 中心点吸附阈值：`7.5` 像素（`5.0 × 1.5`，优先级更高）

当移动元素的边缘与目标元素边缘的距离小于阈值时，会触发吸附。

#### 旋转元素支持 ✨
系统使用 **AABB（轴对齐包围盒）** 来处理旋转后的元素：
- 自动计算旋转元素的外接矩形
- 基于外接矩形进行边缘和中心点吸附
- 性能优化：旋转角度小于0.01时跳过计算
- 中心点对齐优先级更高，更符合设计工具习惯

### 2. 集成方式

#### 在 ElementGestureManager 中集成
位置：`lib/ui/canvas/gesture/element_gesture_manager.dart`

在元素拖动时调用吸附检测：

```dart
case _InteractionMode.drag:
  if (_session.dragStartPointer != null &&
      _session.dragStartElementPosition != null) {
    final delta = event.localPosition - _session.dragStartPointer!;
    final position = _session.dragStartElementPosition! + delta;
    
    // 检测吸附
    final snapResult = ElementSnapHelper.checkSnap(
      targetBox,
      position,
      boxes,
    );
    
    // 更新吸附参考线
    _currentSnapLines = snapResult.snapLines;
    
    // 应用吸附后的位置
    targetBox.x = snapResult.position.dx;
    targetBox.y = snapResult.position.dy;
  }
  break;
```

### 3. 视觉反馈

#### 参考线绘制器
位置：`lib/ui/canvas/widgets/snap_lines_painter.dart`

`SnapLinesPainter` 是一个独立的 CustomPainter 类，负责绘制吸附参考线。

在画布编辑器中使用：

```dart
// 吸附参考线（最上层）
if (_gestureManager.currentSnapLines.isNotEmpty)
  Positioned.fill(
    child: CustomPaint(
      painter: SnapLinesPainter(
        snapLines: _gestureManager.currentSnapLines,
      ),
    ),
  ),
```

参考线样式：
- 颜色：粉红色 (`#FF0080`)
- 宽度：1.0 像素
- 延伸范围：超出元素边界，覆盖整个可见画布区域

### 4. 工作流程

1. **用户开始拖动元素**
   - 记录起始位置
   - 进入拖动模式

2. **移动过程中**
   - 计算元素的目标位置
   - 调用 `ElementSnapHelper.checkSnap()` 检测吸附
   - 如果距离小于阈值，应用吸附位置
   - 更新参考线数据

3. **绘制参考线**
   - 通过 `_SnapLinesPainter` 绘制参考线
   - 参考线延伸到画布边界外

4. **用户释放元素**
   - 清除参考线
   - 重置吸附状态

### 5. 性能优化

- 只在拖动模式下进行吸附检测
- 跳过隐藏和锁定的元素
- 使用最小距离算法，只保留最近的吸附线
- 参考线使用 `shouldRepaint` 优化重绘

### 6. 可配置参数

#### 吸附阈值
可以在 `ElementSnapHelper` 中修改：

```dart
static const double snapThreshold = 5.0; // 修改此值调整吸附灵敏度
```

#### 参考线颜色
可以在 `SnapLinesPainter` 中修改：

```dart
// lib/ui/canvas/widgets/snap_lines_painter.dart
final paint = Paint()
  ..color = const Color(0xFFFF0080) // 修改此值改变参考线颜色
  ..strokeWidth = 1.0
  ..style = PaintingStyle.stroke;
```

## 使用示例

用户在画布上拖动元素时：

1. 当元素的左边缘接近另一个元素的左边缘时，会自动吸附对齐
2. 当元素的右边缘接近另一个元素的右边缘时，会自动吸附对齐
3. 当元素的中心接近另一个元素的中心时，会自动吸附对齐
4. 垂直方向同理（上、下、中心）

同时会显示粉红色的参考线，指示当前的对齐位置。

## 旋转元素适配技术细节

### AABB（轴对齐包围盒）算法

当元素旋转后，使用AABB算法计算其最小外接矩形：

```dart
/// 计算元素旋转后的AABB
static Rect _getRotatedAABB(CanvasElement element, Offset position) {
  // 1. 性能优化：旋转角度很小时直接返回原始矩形
  if (element.rotation.abs() < 0.01) {
    return Rect.fromLTWH(position.dx, position.dy, 
                         element.width, element.height);
  }
  
  // 2. 计算元素中心点
  final cx = position.dx + element.width / 2;
  final cy = position.dy + element.height / 2;
  
  // 3. 计算旋转后的四个角点
  final cos = math.cos(element.rotation);
  final sin = math.sin(element.rotation);
  
  // 4. 找出最小和最大边界
  // 遍历四个角点，找出 minX, maxX, minY, maxY
  
  // 5. 返回包围盒
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
```

### 吸附流程（支持旋转）

1. **计算移动元素的AABB**
   ```dart
   final movingBounds = _getRotatedAABB(movingElement, targetPosition);
   ```

2. **遍历目标元素，计算每个的AABB**
   ```dart
   final targetBounds = _getRotatedAABB(element, element.position);
   ```

3. **基于AABB进行边缘和中心点检测**
   - 使用AABB的边界进行吸附判断
   - 中心点对齐使用更宽松的阈值（1.5倍）

4. **应用吸附位置**
   - 返回吸附后的坐标
   - 生成参考线数据用于UI显示

### 优势

- ✅ **简单高效**：O(n) 复杂度，n为元素数量
- ✅ **符合直觉**：对齐可见边界，而非原始矩形
- ✅ **性能优化**：小角度旋转跳过计算
- ✅ **中心优先**：中心对齐更容易触发，符合设计习惯

## 注意事项

1. 吸附功能只在拖动模式下生效
2. 锁定和隐藏的元素不参与吸附检测
3. 参考线会自动在拖动结束后清除
4. 支持同时在水平和垂直方向吸附
5. ✨ **旋转元素使用AABB进行吸附，确保视觉对齐准确**
6. 中心点对齐优先级高于边缘对齐

## 测试旋转元素吸附

### 测试步骤

1. **创建测试元素**
   - 在画布上添加2-3个矩形或图片元素
   
2. **旋转元素**
   - 选中一个元素，使用旋转控制点旋转45度
   
3. **测试中心对齐**
   - 拖动旋转的元素靠近另一个元素
   - 观察：当两个元素中心对齐时，应出现粉红色参考线
   - 验证：元素会自动吸附到中心位置
   
4. **测试边缘对齐**
   - 拖动旋转的元素，使其AABB边缘靠近另一个元素
   - 观察：当外接矩形边缘对齐时，应出现参考线
   - 验证：元素会自动吸附到边缘位置

5. **测试多元素场景**
   - 同时有多个旋转和未旋转的元素
   - 验证：吸附始终选择距离最近的对齐点

### 预期效果示意

```
未旋转元素 A:  ┌──────┐
               │      │
               └──────┘

旋转45度元素 B:    ╱╲
                  ╱  ╲
                 ╱    ╲
                ╲    ╱
                 ╲  ╱
                  ╲╱

AABB包围盒:    ┌────┐  ← 用于吸附检测
               │ ╱╲ │
               │╱  ╲│
               │    │
               │╲  ╱│
               │ ╲╱ │
               └────┘

对齐场景 1 (中心对齐):
┌──────┐     ┌────┐
│      │  ·  │ ╱╲ │  ← 粉红色垂直参考线穿过两个中心
└──────┘     │╲  ╱│
             └────┘

对齐场景 2 (边缘对齐):
┌──────┐┌────┐
│      ││ ╱╲ │  ← 左边缘对齐右边缘
└──────┘│╲  ╱│
        └────┘
```

## 未来改进方向

1. 支持画布边界吸附
2. 支持等距分布吸附
3. 添加吸附音效反馈
4. 支持自定义吸附规则
5. 添加吸附开关设置
6. 考虑实现OBB（定向包围盒）精确吸附（高级模式）

