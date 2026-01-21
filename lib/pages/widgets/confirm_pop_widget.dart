import 'package:common/common.dart';
import 'package:flutter/material.dart';

class ConfirmPopWidget extends StatelessWidget {
  final String title;
  final String subTitle;
  final String sureTitle;
  final Widget? subTitleWidget;
  final String cancelTitle;
  final VoidCallback? sureAction;
  final VoidCallback? cancelAction;

  final int marginTop;

  const ConfirmPopWidget({
    super.key,
    required this.title,
    this.subTitle = '',
    this.subTitleWidget,
    required this.sureAction,
    this.cancelAction,
    this.sureTitle = "确定",
    this.cancelTitle = "取消",
    this.marginTop = 29,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277.w,
      height: 251.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.w),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 24.w),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18.w,
                color: "#232535".color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: marginTop.w),
            child: _buildSubTitle(),
          ),

          Spacer(),

          // 按钮
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    cancelAction?.call();
                    SmartDialog.dismiss();
                  },
                  child: Container(
                    width: 114.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: "#E8E8E8".color,
                      borderRadius: BorderRadius.circular(20.w),
                    ),
                    child: Center(
                      child: Text(
                        cancelTitle,
                        style: TextStyle(
                          fontSize: 16.w,
                          color: "#222325".color.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    sureAction?.call();
                    SmartDialog.dismiss();
                  },
                  child: Container(
                    width: 114.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.w),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3691FF), Color(0xFF8556FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        sureTitle,
                        style: TextStyle(
                          fontSize: 16.w,
                          color: "#FFFFFF".color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 26.w),
        ],
      ),
    );
  }

  /// 根据传入类型构建副标题
  Widget _buildSubTitle() {
    if (subTitleWidget != null) {
      return subTitleWidget!;
    }
    return Text(
      subTitle,
      style: TextStyle(
        fontSize: 16.w,
        color: "#434343".color,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }
}
