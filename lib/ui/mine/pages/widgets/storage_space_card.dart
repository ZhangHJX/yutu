import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../resource/resource_logic.dart';
import 'gradient_progress_bar.dart';

class StorageSpaceCard extends StatelessWidget {
  final AppResourceLogic controller;

  const StorageSpaceCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final used = controller.usedSpaceBytes.value;
      final total = controller.totalSpaceBytes;
      final usedMB = controller.formatMB(used);
      final totalMB = controller.formatMB(total);

      return Container(
        padding: EdgeInsets.only(top: 8.w, bottom: 10.w),
        margin: EdgeInsets.symmetric(horizontal: 13.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 18.w, right: 16.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 32.w,
                    height: 32.w,
                    child: Image.asset(
                      "assets/images/mine/app_resource_yunpan.png",
                      width: 18.w,
                      height: 18.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 7.w),

                  Text(
                    '存储空间',
                    style: TextStyle(
                      fontSize: 16.w,
                      fontWeight: FontWeight.w600,
                      color: "#232535".color,
                    ),
                  ),
                  const Spacer(),

                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.only(
                      top: controller.usedRatio >= 1 ? 10.w : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${usedMB}MB/${totalMB}MB',
                          style: TextStyle(
                            fontSize: 13.w,
                            color: "#9E9E9E".color,
                          ),
                        ),

                        if (controller.usedRatio >= 1)
                          Text(
                            "存储空间已满",
                            style: TextStyle(
                              color: "#FF3838".color,
                              fontSize: 10.w,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.end,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 6.w),
            Padding(
              padding: EdgeInsets.only(left: 24.w, right: 16.w),
              child: GradientProgressBar(
                value: controller.usedRatio.clamp(0, 1),
                height: 8.w,
                backgroundColor: "#D8D8D8".color,
              ),
            ),

            SizedBox(height: 15.w),

            Obx(() {
              final usedRatio = controller.usedRatio;
              return usedRatio > 0.9
                  ? Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: Text(
                        "素材总容量限制为${totalMB}MB，超出后需要删除旧素材才能上传新素材",
                        style: TextStyle(
                          color: "#FF3A3A".color,
                          fontSize: 11.w,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : SizedBox.shrink();
            }),
          ],
        ),
      );
    });
  }
}
