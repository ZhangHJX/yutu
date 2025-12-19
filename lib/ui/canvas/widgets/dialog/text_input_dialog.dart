import 'package:common/common.dart';
import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final Function(String)? onConfirm;
  final String? initialText; // 初始文本
  const TextInputDialog({super.key, this.onConfirm, this.initialText});
  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false; // 是否全屏展开
  bool _keyboardVisible = false; // 键盘是否可见

  // ⭐ 关键：创建一个全局 key 来保持 TextField 的状态
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // ⭐ 设置初始文本
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      // 将光标移动到文本末尾
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    // ⭐ 优化1：添加观察者监听键盘状态
    WidgetsBinding.instance.addObserver(this);

    // ⭐ 优化2：立即请求焦点，不使用延迟
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // ⭐ 优化3：监听键盘状态变化
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    final bottomInset = view?.viewInsets.bottom ?? 0.0;

    final newKeyboardVisible = bottomInset > 0;

    if (_keyboardVisible != newKeyboardVisible) {
      setState(() {
        _keyboardVisible = newKeyboardVisible;
      });
    }
  }

  // 切换展开/折叠状态
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // ⭐ 提取为独立方法，使用同一个 key，添加重绘边界
  Widget _buildTextField() {
    return RepaintBoundary(
      child: TextField(
        key: _textFieldKey, // ← 使用全局 key 保持状态
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        expands: _isExpanded,
        textAlignVertical: _isExpanded
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: "请输入",
          hintStyle: TextStyle(
            fontSize: 14.w,
            color: "#9E9E9E".color,
            fontWeight: defaultConfigFontWeight,
            fontFamily: defaultConfigFamliy,
          ),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(fontSize: 14.w, color: '#292929'.color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _isExpanded
          ? _buildExpandedView(context)
          : _buildCollapsedView(context),
    );
  }

  // 折叠状态的视图
  Widget _buildCollapsedView(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      key: ValueKey('collapsed'),
      margin: EdgeInsets.only(bottom: keyboardHeight),
      height: 77.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.w),
          topRight: Radius.circular(18.w),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 13.w),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 输入框区域
                Expanded(
                  child: Container(
                    height: 44.w,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: "#EBEBEB".color,
                      borderRadius: BorderRadius.circular(22.w),
                    ),
                    alignment: Alignment.centerLeft,
                    // ⭐ 使用共享的 TextField
                    child: _buildTextField(),
                  ),
                ),

                SizedBox(width: 5.w),

                // 放大按钮
                GestureDetector(
                  onTap: _toggleExpand,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    color: Colors.white,
                    child: Center(
                      child: Image.asset(
                        'assets/images/canvals/canvals_expand_input.png',
                        width: 12.w,
                        height: 12.w,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 5.w),

                // 确定按钮
                GestureDetector(
                  onTap: () {
                    widget.onConfirm?.call(_textController.text);
                  },
                  child: Container(
                    height: 25.w,
                    alignment: Alignment.center,
                    child: Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 16.w,
                        color: "#766BFF".color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 展开状态的视图（全屏）
  Widget _buildExpandedView(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      key: ValueKey('expanded'),
      margin: EdgeInsets.only(bottom: keyboardHeight),
      height: ScreenTools.screenHeight - keyboardHeight,
      color: "#EAEAEA".color,
      child: Column(
        children: [
          // 顶部状态栏占位
          Container(
            height: ScreenTools.statusBarHeight,
            color: "#EAEAEA".color,
          ),

          // 顶部工具栏
          Container(
            height: 56.w,
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 确定按钮
                GestureDetector(
                  onTap: () {
                    widget.onConfirm?.call(_textController.text);
                  },
                  child: Text(
                    '确定',
                    style: TextStyle(
                      fontSize: 14.w,
                      color: "#766BFF".color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(width: 15.w),

                // 收起按钮
                GestureDetector(
                  onTap: _toggleExpand,
                  child: Image.asset(
                    'assets/images/canvals/canvals_text_down.png',
                    width: 26.w,
                    height: 26.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          // 文本输入区域
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              // ⭐ 使用共享的 TextField
              child: _buildTextField(),
            ),
          ),
        ],
      ),
    );
  }
}
