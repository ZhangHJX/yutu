import 'dart:math';

import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 在 loading 关闭后显示 toast
/// 用于确保 loading 消失后再显示错误提示
Future<void> showToastAfterLoading(
  String msg, {
  Alignment? alignment = Alignment.center,
  SmartToastType? type = SmartToastType.onlyRefresh,
  Duration delay = const Duration(milliseconds: 300),
}) async {
  // 先关闭可能正在显示的 loading
  SmartDialog.dismiss(status: SmartStatus.loading);
  // 延迟一小段时间，确保 loading 关闭动画完成后再显示 toast
  await Future.delayed(delay);
  return showToast(msg, alignment: alignment, type: type);
}

Future<void> showToast(
  String msg, {
  Alignment? alignment = .center,
  SmartToastType? type = .onlyRefresh,
}) {
  return SmartDialog.showToast(
    msg,
    displayType: type,
    alignment: alignment,
    builder: (context) => Container(
      padding: .symmetric(horizontal: 16.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: .circular(8.w),
      ),
      child: Text(
        msg,
        style: .new(color: Colors.white, fontSize: 14.w, fontWeight: .w500),
      ),
    ),
  );
}

Future<void> showLoading(String msg, {bool showMask = true}) {
  return SmartDialog.showLoading(
    msg: msg,
    maskColor: showMask ? null : Colors.transparent,
    builder: (context) => Center(
      child: Container(
        padding: .all(20.w),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: .circular(8.w),
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            SizedBox(
              width: 30.w,
              height: 30.w,
              child: CircularProgressIndicator(color: Colors.white),
            ),
            SizedBox(height: 12.w),
            Text(
              msg,
              style: .new(
                color: Colors.white,
                fontSize: 14.w,
                fontWeight: .w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 通用对话框
///
/// [isConfirmRight] 确定按钮是否在右边
///
/// [isConfirmOnly] 是否只有确定按钮
///
/// [autoHandle] 是否自动关闭对话框. 如果只是单纯地使用bool返回值, 则可以将该属性设为true
///
/// [tag] 对话框的tag
Future<bool> showMyDialog(
  String msg, {
  String? tag,
  String? confirmText,
  String? cancelText,
  Widget? confirmWidget,
  Widget? cancelWidget,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  bool isConfirmRight = true,
  bool isConfirmOnly = false,
  bool autoHandle = false,
}) async {
  bool isConfirm = false;

  void confirmTap() {
    isConfirm = true;
    onConfirm?.call();

    if (autoHandle) {
      SmartDialog.dismiss(tag: tag);
    }
  }

  void cancelTap() {
    isConfirm = false;
    onCancel?.call();

    if (autoHandle) {
      SmartDialog.dismiss(tag: tag);
    }
  }

  if (autoHandle) {
    tag ??= 'feedback_dialog_${Random().nextInt(1000000)}';
  }

  await SmartDialog.show(
    tag: tag,
    maskColor: Colors.black.withValues(alpha: 0.4),
    alignment: .center,
    builder: (context) => Container(
      margin: .symmetric(horizontal: 26.w),
      padding: .only(left: 12.w, right: 12.w, top: 22.w, bottom: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(14.w),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          Text(
            msg,
            style: text54545D(fontSize: 16.w, height: 24 / 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.w),
          DefaultTextStyle(
            style: .new(
              fontSize: 16.w,
              height: 1,
              color: Colors.white,
              fontWeight: .w500,
            ),
            child: Row(
              textDirection: isConfirmRight
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              spacing: 15.w,
              children: [
                if (!isConfirmOnly)
                  _buildCancelWidget(cancelTap, cancelWidget, cancelText),
                _buildConfirmWidget(confirmTap, confirmWidget, confirmText),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return isConfirm;
}

Widget _buildConfirmWidget(
  VoidCallback confirmTap,
  Widget? confirmWidget,
  String? confirmText,
) {
  return Expanded(
    child: GestureDetector(
      onTap: confirmTap,
      child:
          confirmWidget ??
          CButton(
            height: 44.w,
            textColor: Colors.white,
            text: Text(
              confirmText ?? '确定',
              style: .new(fontSize: 16.w, height: 24 / 16),
            ),
            gradient: defaultGradient,
            borderRadius: 44.w,
            onPressed: confirmTap,
          ),
    ),
  );
}

Widget _buildCancelWidget(
  VoidCallback cancelTap,
  Widget? cancelWidget,
  String? cancelText,
) {
  return Expanded(
    child: GestureDetector(
      onTap: cancelTap,
      child:
          cancelWidget ??
          CButton(
            height: 44.w,
            text: Text(
              cancelText ?? '取消',
              style: text333333(fontSize: 16.w, height: 24 / 16),
            ),
            border: Border.all(color: '#FFD1D1D1'.color),
            borderRadius: 44.w,
            onPressed: cancelTap,
          ),
    ),
  );
}

class BottomSheetItem {
  BottomSheetItem({required this.title, required this.onPressed});
  final String title;
  final VoidCallback onPressed;
}

Future<void> showMyBottomSheet(
  List<BottomSheetItem> items, {
  Widget? title,
  VoidCallback? onCancel,
}) {
  const tag = 'feedback_bottom_sheet';
  return SmartDialog.show(
    tag: tag,
    maskColor: Colors.black.withValues(alpha: 0.4),
    alignment: .bottomCenter,
    builder: (context) => Container(
      constraints: BoxConstraints(maxHeight: 300.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .vertical(top: Radius.circular(12.w)),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          if (title != null) title,
          Flexible(
            child: ListView.separated(
              padding: .zero,
              shrinkWrap: true,
              itemBuilder: (context, index) => CButton(
                text: Text(items[index].title),
                height: 50.w,
                onPressed: () {
                  items[index].onPressed();
                  SmartDialog.dismiss(tag: tag);
                },
              ),
              separatorBuilder: (context, index) =>
                  Container(height: hairline, color: '#FFEAEAEA'.color),
              itemCount: items.length,
            ),
          ),
          Container(color: '#FFF7F9FE'.color, height: 8.w),
          CSafeBottom(
            minBottom: 14.w,
            child: CButton(
              height: 44.w,
              text: Text('取消'),
              width: .infinity,
              onPressed: () {
                onCancel?.call();
                SmartDialog.dismiss(tag: tag);
              },
            ),
          ),
        ],
      ),
    ),
  );
}
