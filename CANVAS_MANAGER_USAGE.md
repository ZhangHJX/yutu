# CanvasStatusManager 使用指南

## 概述
`CanvasStatusManager` 处理画布的平移和缩放手势，并提供恢复/重置功能。

## 核心功能

### 1. 手势处理
- **单指拖动**：移动画布
- **双指缩放**：以双指中心为基准进行缩放
- **缩放范围**：0.25x ~ 3.0x

### 2. 恢复方法

#### 重置到初始状态
```dart
// 重置画布到 1.0 倍缩放、无平移的初始状态
_canvasStatusManager.resetMatrix();
```

使用场景：
- 用户点击"重置"或"适应屏幕"按钮
- 初始化画布

#### 恢复到指定状态
```dart
// 保存当前状态
Matrix4 savedState = _canvasStatusManager.getMatrix();

// ... 进行一些操作 ...

// 恢复到保存的状态
_canvasStatusManager.restoreMatrix(savedState);
```

使用场景：
- 撤销/重做操作
- 保存和恢复画布状态
- 版本控制

### 3. 状态查询

#### 获取完整矩阵
```dart
Matrix4 matrix = _canvasStatusManager.getMatrix();
// 用于保存到数据库或历史记录
```

#### 获取缩放比例
```dart
double scale = _canvasStatusManager.getScale();
print('当前缩放：${scale.toStringAsFixed(2)}x');
```

#### 获取偏移量
```dart
Offset offset = _canvasStatusManager.getOffset();
print('X 偏移：${offset.dx}, Y 偏移：${offset.dy}');
```

## 集成示例

### 在编辑页面中集成恢复功能

```dart
class _CanvasEditorPagePageState extends State<CanvasEditorPage> {
  final _canvasStatusManager = CanvasStatusManager();
  
  // 保存画布状态的栈（用于撤销/重做）
  final List<Matrix4> _stateHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _canvasStatusManager.onMatrixChanged = (matrix, scale, offset) {
      if (!mounted) return;
      
      // 保存到撤销栈
      _saveToHistory(matrix);
      
      setState(() {
        _canvalsModel.updateMatrix4(matrix, scale, offset);
      });
    };
  }

  /// 保存状态到历史记录
  void _saveToHistory(Matrix4 matrix) {
    // 移除当前位置之后的历史
    if (_historyIndex < _stateHistory.length - 1) {
      _stateHistory.removeRange(_historyIndex + 1, _stateHistory.length);
    }
    
    // 添加新状态
    _stateHistory.add(matrix.clone());
    _historyIndex = _stateHistory.length - 1;
  }

  /// 撤销
  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _canvasStatusManager.restoreMatrix(_stateHistory[_historyIndex]);
    }
  }

  /// 重做
  void _redo() {
    if (_historyIndex < _stateHistory.length - 1) {
      _historyIndex++;
      _canvasStatusManager.restoreMatrix(_stateHistory[_historyIndex]);
    }
  }

  /// 重置画布
  void _handleReset() {
    _canvasStatusManager.resetMatrix();
    _stateHistory.clear();
    _historyIndex = -1;
  }

  /// 适应屏幕
  void _handleFitScreen() {
    _canvasStatusManager.resetMatrix();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... UI 构建 ...
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _undo,
            tooltip: '撤销',
            child: Icon(Icons.undo),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _redo,
            tooltip: '重做',
            child: Icon(Icons.redo),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _handleReset,
            tooltip: '重置',
            child: Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
```

### 在工具栏中显示缩放比例和偏移

```dart
Widget _buildStatusBar() {
  return Container(
    padding: EdgeInsets.all(8),
    child: Row(
      children: [
        Text(
          'Scale: ${_canvasStatusManager.getScale().toStringAsFixed(2)}x',
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(width: 16),
        Text(
          'Offset: (${_canvasStatusManager.getOffset().dx.toStringAsFixed(0)}, '
          '${_canvasStatusManager.getOffset().dy.toStringAsFixed(0)})',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
```

## API 参考

| 方法 | 说明 | 返回值 |
|------|------|--------|
| `resetMatrix()` | 重置到初始状态 | void |
| `restoreMatrix(Matrix4)` | 恢复到指定状态 | void |
| `getMatrix()` | 获取当前矩阵 | Matrix4 |
| `getScale()` | 获取当前缩放比例 | double |
| `getOffset()` | 获取当前偏移量 | Offset |

## 事件回调

```dart
// 当矩阵变化时触发
_canvasStatusManager.onMatrixChanged = (matrix, scale, offset) {
  print('矩阵已变化：scale=$scale, offset=$offset');
};
```

## 约束条件

- **最小缩放**：0.25x（四分之一尺寸）
- **最大缩放**：3.0x（三倍尺寸）
- **基准点**：双指缩放时以两指中心为基准
- **补偿平移**：缩放后自动调整平移，保持基准点在屏幕上不动

## 常见问题

### Q: 如何持久化保存画布状态？
A: 使用 `getMatrix()` 获取矩阵，然后序列化保存：
```dart
Matrix4 matrix = _canvasStatusManager.getMatrix();
// 将 matrix 的数据序列化保存到文件或数据库
List<double> matrixData = matrix.storage;
```

### Q: 如何实现"适应屏幕"功能？
A: 直接调用 `resetMatrix()` 方法，这会重置到 1.0 倍缩放且无平移。

### Q: 缩放中心总是双指中心吗？
A: 是的，使用双指缩放时，系统自动以两指中心点（在画布坐标系中）作为缩放中心。

