import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../controllers/create_design_model.dart';

typedef MultiCallback = void Function(bool resizing, bool rotating);

class EditContentBox extends StatefulWidget {
  final EditBoxData data;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final MultiCallback changeValue;

  const EditContentBox({
    super.key,
    required this.data,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.changeValue,
  });

  @override
  State<EditContentBox> createState() => _EditContentBoxState();
}

class _EditContentBoxState extends State<EditContentBox>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  double _rotation = 0.0;
  bool _isRotating = false;
  bool _isResizing = false;
  Offset _lastPanPosition = Offset.zero;

  final GlobalKey _containerKey = GlobalKey();

  // 用于调整大小时的初始值
  double _startWidth = 300;
  double _startHeight = 200;

  // 最大尺寸限制（可以设置为非常大的值）
  static const double _maxSize = 1000000.0;
  Offset _resizeStartPosition = Offset.zero;

  // 记录对角点的全局位置（用于固定对角点）
  Offset _anchorPointGlobal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.data.position.dx,
      top: widget.data.position.dy,
      child: Transform.rotate(
        angle: _rotation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文本框带旋转
            Container(
              key: _containerKey,
              width: widget.data.width,
              height: widget.data.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: widget.isActive
                    ? Border.all(color: "#ff147EFF".color, width: 3)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 内容
                  GestureDetector(
                    onTap: () {
                      debugPrint('点击元素: ${widget.data.id} ${widget.data.text}');
                      widget.onTap();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: _buildContent(),
                  ),

                  // 调整大小的控制点
                  if (widget.isActive) ..._getControlPoint(context),
                ],
              ),
            ),

            // 旋转按钮（与文本框底部保持距离，不参与旋转）
            if (widget.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: GestureDetector(
                  onPanStart: (details) {
                    _handleRotationStart(details);
                  },
                  onPanUpdate: (details) {
                    _handleRotationUpdate(details);
                  },
                  onPanEnd: (details) {
                    _handleRotationEnd(details);
                  },
                  child: Image.asset(
                    'assets/images/canvals/edit_rotation_icon.png',
                    width: 26.w,
                    height: 26.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleRotationStart(DragStartDetails details) {
    widget.changeValue(false, true);
    setState(() {
      _isRotating = true;
      _lastPanPosition = details.globalPosition;
    });
  }

  void _handleRotationUpdate(DragUpdateDetails details) {
    if (_isRotating) {
      // 计算旋转角度
      Offset currentPosition = details.globalPosition;

      // 获取屏幕尺寸
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        // 计算文本框的中心点（全局坐标）
        // Transform.rotate 围绕文本框的中心点旋转
        Offset globalContainerCenter = Offset(
          widget.data.position.dx + widget.data.width / 2,
          widget.data.position.dy + widget.data.height / 2,
        );

        // 计算从Container中心到触摸点的角度
        double currentAngle = math.atan2(
          currentPosition.dy - globalContainerCenter.dy,
          currentPosition.dx - globalContainerCenter.dx,
        );
        double lastAngle = math.atan2(
          _lastPanPosition.dy - globalContainerCenter.dy,
          _lastPanPosition.dx - globalContainerCenter.dx,
        );

        // 计算角度差
        double angleDelta = currentAngle - lastAngle;

        // 处理角度跨越问题（-π到π的边界）
        if (angleDelta > math.pi) {
          angleDelta -= 2 * math.pi;
        } else if (angleDelta < -math.pi) {
          angleDelta += 2 * math.pi;
        }

        setState(() {
          // 修复旋转方向：加上角度差，确保与手指方向一致
          _rotation += angleDelta;
          _lastPanPosition = currentPosition;
        });
      }
    }
  }

  void _handleRotationEnd(DragEndDetails details) {
    widget.changeValue(false, false);
    setState(() {
      _isRotating = false;
    });
  }

  // 处理调整大小的手势
  void _handleResizeStart(DragStartDetails details, String position) {
    widget.changeValue(true, false);
    setState(() {
      _isResizing = true;
      _startWidth = widget.data.width;
      _startHeight = widget.data.width;
      _resizeStartPosition = details.globalPosition;

      // 计算锚点在局部坐标系中的位置（未旋转、未缩放）
      // 角点：锚点是对角点
      // 边中点：锚点是对面边的中点
      Offset anchorPointLocal = Offset.zero;
      switch (position) {
        case 'top-left':
          anchorPointLocal = Offset(
            widget.data.width,
            widget.data.height,
          ); // 对角点是右下角
          break;
        case 'top':
          anchorPointLocal = Offset(
            widget.data.width / 2,
            widget.data.height,
          ); // 对面是下边中点
          break;
        case 'top-right':
          anchorPointLocal = Offset(0, widget.data.height); // 对角点是左下角
          break;
        case 'right':
          anchorPointLocal = Offset(0, widget.data.height / 2); // 对面是左边中点
          break;
        case 'bottom-right':
          anchorPointLocal = Offset(0, 0); // 对角点是左上角
          break;
        case 'bottom':
          anchorPointLocal = Offset(widget.data.width / 2, 0); // 对面是上边中点
          break;
        case 'bottom-left':
          anchorPointLocal = Offset(widget.data.width, 0); // 对角点是右上角
          break;
        case 'left':
          anchorPointLocal = Offset(
            widget.data.width,
            widget.data.height / 2,
          ); // 对面是右边中点
          break;
      }

      // 将锚点转换为全局坐标
      // 先应用旋转
      double cos = math.cos(_rotation);
      double sin = math.sin(_rotation);
      Offset rotatedPoint = Offset(
        anchorPointLocal.dx * cos - anchorPointLocal.dy * sin,
        anchorPointLocal.dx * sin + anchorPointLocal.dy * cos,
      );

      // 再应用缩放
      Offset scaledPoint = rotatedPoint;

      // 最后加上容器位置
      _anchorPointGlobal = widget.data.position + scaledPoint;
    });
  }

  void _handleResizeUpdate(DragUpdateDetails details, String position) {
    if (!_isResizing) return;
    setState(() {
      Offset delta = details.globalPosition - _resizeStartPosition;

      // 根据当前缩放和旋转，调整delta
      // 因为有旋转，需要反向旋转delta来得到正确的调整方向
      double cos = math.cos(-_rotation);
      double sin = math.sin(-_rotation);
      double adjustedDx = delta.dx * cos - delta.dy * sin;
      double adjustedDy = delta.dx * sin + delta.dy * cos;

      // 不再需要除以缩放比例，因为现在直接操作基础尺寸

      // 计算新的尺寸
      double newWidth = _startWidth;
      double newHeight = _startHeight;

      switch (position) {
        case 'top-left':
          newWidth = (_startWidth - adjustedDx).clamp(50.0, _maxSize);
          newHeight = (_startHeight - adjustedDy).clamp(50.0, _maxSize);
          break;
        case 'top':
          newHeight = (_startHeight - adjustedDy).clamp(50.0, _maxSize);
          break;
        case 'top-right':
          newWidth = (_startWidth + adjustedDx).clamp(50.0, _maxSize);
          newHeight = (_startHeight - adjustedDy).clamp(50.0, _maxSize);
          break;
        case 'right':
          newWidth = (_startWidth + adjustedDx).clamp(50.0, _maxSize);
          break;
        case 'bottom-right':
          newWidth = (_startWidth + adjustedDx).clamp(50.0, _maxSize);
          newHeight = (_startHeight + adjustedDy).clamp(50.0, _maxSize);
          break;
        case 'bottom':
          newHeight = (_startHeight + adjustedDy).clamp(50.0, _maxSize);
          break;
        case 'bottom-left':
          newWidth = (_startWidth - adjustedDx).clamp(50.0, _maxSize);
          newHeight = (_startHeight + adjustedDy).clamp(50.0, _maxSize);
          break;
        case 'left':
          newWidth = (_startWidth - adjustedDx).clamp(50.0, _maxSize);
          break;
      }

      // 更新尺寸到data中
      widget.data.width = newWidth;
      widget.data.height = newHeight;

      // 计算新的锚点在局部坐标系中的位置
      Offset newAnchorPointLocal = Offset.zero;
      switch (position) {
        case 'top-left':
          newAnchorPointLocal = Offset(
            widget.data.width - 1.5,
            widget.data.height - 1.5,
          ); // 右下角
          break;
        case 'top':
          newAnchorPointLocal = Offset(
            widget.data.width / 2,
            widget.data.height - 1.5,
          ); // 下边中点
          break;
        case 'top-right':
          newAnchorPointLocal = Offset(1.5, widget.data.height - 1.5); // 左下角
          break;
        case 'right':
          newAnchorPointLocal = Offset(1.5, widget.data.height / 2); // 左边中点
          break;
        case 'bottom-right':
          newAnchorPointLocal = Offset(1.5, 1.5); // 左上角
          break;
        case 'bottom':
          newAnchorPointLocal = Offset(widget.data.width / 2, 1.5); // 上边中点
          break;
        case 'bottom-left':
          newAnchorPointLocal = Offset(widget.data.width - 1.5, 1.5); // 右上角
          break;
        case 'left':
          newAnchorPointLocal = Offset(
            widget.data.width - 1.5,
            widget.data.height / 2,
          ); // 右边中点
          break;
      }

      // 将新的锚点转换为全局坐标
      // 先应用旋转
      double cosRot = math.cos(_rotation);
      double sinRot = math.sin(_rotation);
      Offset rotatedNewPoint = Offset(
        newAnchorPointLocal.dx * cosRot - newAnchorPointLocal.dy * sinRot,
        newAnchorPointLocal.dx * sinRot + newAnchorPointLocal.dy * cosRot,
      );

      // 不再需要应用缩放，因为现在直接操作基础尺寸
      Offset scaledNewPoint = rotatedNewPoint;

      debugPrint(
        "-------$_anchorPointGlobal.dx, -----$_anchorPointGlobal.dy----$scaledNewPoint.dx, -------------$scaledNewPoint.dy",
      );

      // 计算新的位置，使得锚点保持在原来的全局位置
      widget.data.position = _anchorPointGlobal - scaledNewPoint;
    });
  }

  void _handleResizeEnd(DragEndDetails details) {
    widget.changeValue(false, false);
    setState(() {
      _isResizing = false;
      // 保存当前尺寸作为下次调整的起始值
      _startWidth = widget.data.width;
      _startHeight = widget.data.height;
    });
  }

  // 构建调整大小的圆点
  Widget _buildResizeHandle(String position, BuildContext context) {
    // 直接使用组件的宽度和高度，避免获取实际渲染尺寸的问题
    const double hitTestSize = 20.0;
    Offset postionOffset =
        _calculateResizeHandlePositions(
          widget.data.width,
          widget.data.height,
        )[position] ??
        Offset.zero;

    // 控制点位置使用相对定位（相对于 Stack）
    final adjustedPosition = Offset(
      postionOffset.dx - hitTestSize / 2,
      postionOffset.dy - hitTestSize / 2,
    );

    return Positioned(
      left: adjustedPosition.dx,
      top: adjustedPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          // 阻止事件冒泡到父级拖动
          _handleResizeStart(details, position);
        },
        onPanUpdate: (details) {
          _handleResizeUpdate(details, position);
        },
        onPanEnd: (details) {
          _handleResizeEnd(details);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: hitTestSize,
          height: hitTestSize,
          alignment: Alignment.center,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  // 计算调整大小控制点位置的函数
  Map<String, Offset> _calculateResizeHandlePositions(
    double width,
    double height,
  ) {
    return {
      // 四个角点
      'top-left': Offset(0, 0), // 左上角
      'top-right': Offset(width - 4.5, 0), // 右上角
      'bottom-left': Offset(0, height - 4.5), // 左下角
      'bottom-right': Offset(width - 4.5, height - 4.5), // 右下角
      // 四个边中点
      'left': Offset(-1.5, height / 2), // 左边中点
      'right': Offset(width - 4.5, height / 2), // 右边中点
      'top': Offset(width / 2, -1.5), // 上边中点
      'bottom': Offset(width / 2, height - 4.5), // 下边中点
    };
  }

  // 构建内容
  Widget _buildContent() {
    switch (widget.data.type) {
      case ElementType.image:
        if (widget.data.imagePath.isNotEmpty) {
          return ClipRect(
            child: Image.asset(
              widget.data.imagePath,
              width: widget.data.width,
              height: widget.data.height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(Icons.image, color: Colors.grey, size: 48),
            ),
          );
        }
      case ElementType.rectangle:
        return Container(
          width: widget.data.width,
          height: widget.data.height,
          decoration: BoxDecoration(
            color: widget.data.fillColor.color,
            border: Border.all(
              color: widget.data.borderColor.color,
              width: widget.data.borderWidth,
            ),
            // 只有启用阴影时才添加 boxShadow
            boxShadow: widget.data.isShawOpen
                ? [
                    BoxShadow(
                      color: widget.data.shawColor.color,
                      offset: Offset(widget.data.shawX, widget.data.shawY),
                      blurRadius: widget.data.blurValue,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        );
      case ElementType.ellipse:
        return Container(
          width: widget.data.width,
          height: widget.data.height,
          decoration: BoxDecoration(
            color: widget.data.fillColor.color,
            border: Border.all(
              color: widget.data.borderColor.color,
              width: widget.data.borderWidth,
            ),
            // 只有启用阴影时才添加 boxShadow
            boxShadow: widget.data.isShawOpen
                ? [
                    BoxShadow(
                      color: widget.data.shawColor.color,
                      offset: Offset(widget.data.shawX, widget.data.shawY),
                      blurRadius: widget.data.blurValue,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
            borderRadius: BorderRadius.all(
              Radius.elliptical(widget.data.width / 2, widget.data.height / 2),
            ),
          ),
        );

      case ElementType.line:
        return Container(
          decoration: BoxDecoration(
            color: widget.data.fillColor.color,
            border: Border.all(
              color: widget.data.borderColor.color,
              width: widget.data.borderWidth,
            ),
            // 只有启用阴影时才添加 boxShadow
            boxShadow: widget.data.isShawOpen
                ? [
                    BoxShadow(
                      color: widget.data.shawColor.color,
                      offset: Offset(widget.data.shawX, widget.data.shawY),
                      blurRadius: widget.data.blurValue,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: widget.data.width * 0.8,
              height: 4,
              decoration: BoxDecoration(
                color: widget.data.borderColor.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );

      case ElementType.text:
        return Container(
          width: widget.data.width,
          height: widget.data.height,
          color: Colors.transparent,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              widget.data.text,
              style: TextStyle(
                fontFamily: widget.data.fontFamily,
                fontSize: widget.data.fontSize,
                fontWeight: widget.data.fontWeight,
                color: widget.data.textColor.color,
                height: widget.data.lineHeight,
                letterSpacing: widget.data.fontSpace,
                shadows: widget.data.isShawOpen
                    ? [
                        Shadow(
                          color: widget.data.shawColor.color,
                          offset: Offset(widget.data.shawX, widget.data.shawY),
                          blurRadius: widget.data.blurValue,
                        ),
                      ]
                    : [],

                // foreground: Paint()
                //   ..style = PaintingStyle
                //       .stroke // 描边模式
                //   ..strokeWidth = widget
                //       .data
                //       .borderWidth // 边框宽度
                //   ..color = widget.data.borderColor.color, // 边框颜色
              ),
              textAlign: widget.data.align,
            ),
          ),
        );
    }
  }

  List<Widget> _getControlPoint(BuildContext context) {
    switch (widget.data.type) {
      case ElementType.image:
      case ElementType.rectangle:
      case ElementType.ellipse:
      case ElementType.text:
        return [
          _buildResizeHandle('top-left', context),
          _buildResizeHandle('top', context),
          _buildResizeHandle('top-right', context),
          _buildResizeHandle('right', context),
          _buildResizeHandle('bottom-right', context),
          _buildResizeHandle('bottom', context),
          _buildResizeHandle('bottom-left', context),
          _buildResizeHandle('left', context),
        ];
      case ElementType.line:
        return [];
    }
  }
}
