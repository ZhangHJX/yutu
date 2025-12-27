import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/ui/widgets/confirm_pop_widget.dart';

class OperationBottomBar extends StatelessWidget {
  final VoidCallback deleteEvent;
  final VoidCallback cancelEvent;
  final String typeName;

  const OperationBottomBar({
    super.key,
    required this.cancelEvent,
    required this.deleteEvent,
    required this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: cancelEvent,
            child: Image.asset(
              "assets/images/mine/app_resource_cancel.png",
              width: 153.w,
              height: 40.w,
              fit: BoxFit.cover,
            ),
          ),

          GestureDetector(
            onTap: () {
              SmartDialog.show(
                builder: (context) => ConfirmPopWidget(
                  title: '温馨提示',
                  subTitle: '确定要删除选中的$typeName吗？',
                  sureAction: deleteEvent,
                ),
                alignment: Alignment.center,
                animationType: SmartAnimationType.centerFade_otherSlide,
                animationTime: Duration(milliseconds: 250),
                maskColor: "#000000".color.withValues(alpha: 0.5),
                clickMaskDismiss: false,
                useAnimation: true,
                usePenetrate: false,
              );
            },
            child: Image.asset(
              "assets/images/mine/app_resource_delete.png",
              width: 153.w,
              height: 40.w,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class WarningPopWidget {}
