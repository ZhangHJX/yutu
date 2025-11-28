import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'resource_logic.dart';
import 'package:voicetemplate/ui/widgets/confirm_pop_widget.dart';

class ResourceBottomBar extends StatelessWidget {
  final AppResourceLogic controller;
  const ResourceBottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: controller.clearSelection,
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
                  title: "温馨提示",
                  subTitle:
                      '确定要删除选中的${controller.type == "draft" ? "草稿" : "素材"}吗？',
                  sureAction: controller.deleteSelected,
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
