# 旋转元素吸附功能实现指南

## 概述

已成功实现**方案2：中心为主的旋转元素吸附**，使用AABB（轴对齐包围盒）算法来处理旋转后元素的边缘吸附。

## 核心改进

### 1. 新增 AABB 计算方法

在 `ElementSnapHelper` 中添加了 `_getRotatedAABB()` 方法：

```dart
/// 计算元素旋转后的AABB（轴对齐包围盒）
static Rect _getRotatedAABB(CanvasElement element, Offset position) {
  // 性能优化：旋转角度很小时跳过计算
  if (element.rotation.abs() < 0.01) {
    return Rect.fromLTWH(position.dx, position.dy, 
                         element.width, element.height);
  }
  
  // 计算旋转后四个角点的世界坐标
  // 返回最小包围矩形
  ...
}
```

**特点：**
- 🚀 性能优化：未旋转元素直接返回原始矩形
- 📐 精确计算：考虑旋转角度的完整三角函数变换
- 💡 简洁高效：O(1) 复杂度

### 2. 修改吸附检测逻辑

原有逻辑：
```dart
// ❌ 旧代码：只使用原始位置和尺寸
final movingLeft = targetPosition.dx;
final movingRight = targetPosition.dx + movingElement.width;
```

新逻辑：
```dart
// ✅ 新代码：使用 AABB 计算旋转后的边界
final movingBounds = _getRotatedAABB(movingElement, targetPosition);
final movingLeft = movingBounds.left;
final movingRight = movingBounds.right;
```

**改进点：**
- 移动元素使用 AABB
- 目标元素使用 AABB
- 画布边界计算使用 AABB

### 3. 增强中心点吸附优先级

```dart
/// 中心点吸附的额外优先级
static const double centerSnapBonus = 1.5;

// 中心对齐使用更大的阈值（优先级更高）
if (centerToCenterXDistance < snapThreshold * centerSnapBonus &&
    centerToCenterXDistance < minDistance) {
  onSnap(
    targetCenterX - (movingCenterX - movingLeft),
    centerToCenterXDistance * 0.8, // 降低距离值，提高优先级
    ...
  );
}
```

**效果：**
- 中心对齐阈值：7.5像素（5.0 × 1.5）
- 边缘对齐阈值：5.0像素
- 优先级权重：中心对齐 × 0.8

## 工作原理

### AABB 算法详解

```
原始矩形 (100×50):      旋转45度后:           AABB包围盒:
┌──────────┐               ╱╲               ┌────────┐
│          │              ╱  ╲              │  ╱╲    │
│          │    旋转45°  ╱    ╲    AABB→   │ ╱  ╲   │
│          │    ────→   ╲    ╱    计算→   │╱    ╲  │
└──────────┘             ╲  ╱              │╲    ╱  │
                          ╲╱               │ ╲  ╱   │
                                          │  ╲╱    │
                                          └────────┘
```

### 计算步骤

1. **计算中心点** `(cx, cy)`
2. **获取四个角点**相对中心的偏移
3. **应用旋转矩阵**：
   ```
   x' = x·cos(θ) - y·sin(θ)
   y' = x·sin(θ) + y·cos(θ)
   ```
4. **找出边界**：`min/max(x')`, `min/max(y')`
5. **返回矩形**：`Rect.fromLTRB(minX, minY, maxX, maxY)`

## 使用示例

### 场景1：旋转矩形吸附未旋转矩形

```dart
// 元素 A（未旋转）
CanvasElement elementA = CanvasElement(
  x: 100, y: 100,
  width: 100, height: 50,
  rotation: 0,
);

// 元素 B（旋转45度）
CanvasElement elementB = CanvasElement(
  x: 200, y: 150,
  width: 80, height: 80,
  rotation: math.pi / 4, // 45度
);

// 拖动元素 B 时的吸附检测
final snapResult = ElementSnapHelper.checkSnap(
  elementB,
  Offset(195, 125), // 目标位置（接近元素A）
  [elementA, elementB],
);

// 结果：
// - snapResult.hasSnap = true
// - snapResult.position = 调整后的位置（中心对齐）
// - snapResult.snapLines = [垂直参考线]
```

### 场景2：两个旋转元素互相吸附

```dart
// 元素 A（旋转30度）
CanvasElement elementA = CanvasElement(
  x: 100, y: 100,
  width: 100, height: 50,
  rotation: math.pi / 6, // 30度
);

// 元素 B（旋转60度）
CanvasElement elementB = CanvasElement(
  x: 250, y: 150,
  width: 80, height: 80,
  rotation: math.pi / 3, // 60度
);

// 两者都使用 AABB 进行吸附检测
// 吸附基于外接矩形的边缘和中心点
```

## 技术优势

### 1. 性能优化

```dart
// 快速路径：未旋转元素
if (element.rotation.abs() < 0.01) {
  return Rect.fromLTWH(...); // O(1)
}

// 正常路径：旋转元素
// 只需计算4个角点 O(1)
```

### 2. 视觉准确性

- ✅ 对齐可见的外接边界
- ✅ 中心点始终精确
- ✅ 符合用户视觉预期

### 3. 兼容性

- ✅ 向后兼容（未旋转元素行为不变）
- ✅ 混合场景支持（旋转+未旋转）
- ✅ 所有元素类型适用

## 与其他方案对比

| 特性 | 方案2 (AABB) | 方案3 (OBB精确) |
|-----|-------------|----------------|
| 实现难度 | ⭐ 简单 | ⭐⭐⭐⭐ 复杂 |
| 计算性能 | ⭐⭐⭐⭐⭐ 极快 | ⭐⭐ 较慢 |
| 对齐精度 | ⭐⭐⭐ 良好 | ⭐⭐⭐⭐⭐ 完美 |
| 用户体验 | ⭐⭐⭐⭐⭐ 直观 | ⭐⭐ 可能过于复杂 |
| 代码维护性 | ⭐⭐⭐⭐⭐ 易维护 | ⭐⭐ 复杂 |

## 测试建议

### 单元测试场景

```dart
void testRotatedElementSnap() {
  // 1. 测试未旋转元素（确保向后兼容）
  final rect1 = CanvasElement(
    x: 0, y: 0, width: 100, height: 100, rotation: 0
  );
  final bounds1 = ElementSnapHelper._getRotatedAABB(rect1, rect1.position);
  assert(bounds1 == Rect.fromLTWH(0, 0, 100, 100));
  
  // 2. 测试90度旋转（对称性）
  final rect2 = CanvasElement(
    x: 0, y: 0, width: 100, height: 50, rotation: math.pi / 2
  );
  final bounds2 = ElementSnapHelper._getRotatedAABB(rect2, rect2.position);
  // 预期：宽高互换的AABB
  
  // 3. 测试45度旋转（对角线最大）
  final rect3 = CanvasElement(
    x: 0, y: 0, width: 100, height: 100, rotation: math.pi / 4
  );
  final bounds3 = ElementSnapHelper._getRotatedAABB(rect3, rect3.position);
  // 预期：AABB 约为 141×141 (100√2)
}
```

### 手动测试步骤

1. **基础旋转测试**
   - 创建一个矩形
   - 旋转45度
   - 拖动靠近另一个未旋转的矩形
   - 验证：吸附到中心或边缘时显示参考线

2. **多角度测试**
   - 测试0°, 30°, 45°, 60°, 90°
   - 验证所有角度都能正常吸附

3. **性能测试**
   - 画布上放置20+个元素
   - 部分旋转不同角度
   - 拖动元素，观察是否流畅
   - 验证：无明显卡顿

4. **边界情况测试**
   - 极小旋转角度（0.001°）
   - 大旋转角度（>360°）
   - 负角度旋转
   - 验证：都能正确处理

## 性能分析

### 时间复杂度

- AABB 计算：O(1) - 固定4个角点
- 吸附检测：O(n) - n为元素数量
- 总体：O(n) - 线性复杂度

### 空间复杂度

- 临时变量：O(1)
- 参考线列表：O(1) - 最多2条线

### 优化措施

1. **快速路径**：未旋转元素跳过三角函数计算
2. **惰性计算**：只在需要时计算AABB
3. **提前退出**：找到吸附点后立即返回

## 常见问题

### Q1: 为什么不用精确的旋转边缘？
**A:** AABB方案更简单、更快，且符合大多数设计工具的习惯（Figma、Sketch都使用AABB）。

### Q2: 旋转角度很大时，AABB会很大怎么办？
**A:** 这是正常的。中心点对齐优先级更高，用户通常会依赖中心对齐。

### Q3: 能否支持精确的边对边吸附？
**A:** 可以作为未来改进（OBB方案），但会增加复杂度，需要评估用户需求。

### Q4: 性能会受影响吗？
**A:** 几乎没有影响。三角函数计算很快，且有优化（小角度跳过）。

### Q5: 如何调整吸附灵敏度？
**A:** 修改常量：
```dart
static const double snapThreshold = 5.0; // 边缘吸附
static const double centerSnapBonus = 1.5; // 中心吸附倍数
```

## 总结

✅ **已完成：**
- AABB 计算方法
- 吸附逻辑更新（使用AABB）
- 中心点优先级提升
- 文档和测试指南

🚀 **优势：**
- 简单高效
- 性能优秀
- 用户体验好
- 易于维护

📝 **后续优化方向：**
- 添加单元测试
- 性能监控
- 用户反馈收集
- 考虑 OBB 精确模式（可选）

