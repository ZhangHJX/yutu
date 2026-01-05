import 'package:common/common.dart';
import 'package:flutter/material.dart';

class NavigationWidget extends StatelessWidget {
  const NavigationWidget({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: ScreenTools.statusBarHeight,
          color: Colors.transparent,
        ),

        SizedBox(
          height: 44.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  EventBusManager.share.emit(AppEventType.mineRefresh);
                  Get.back();
                },
                child: SizedBox(
                  width: 50.w,
                  height: 40.w,
                  child: Image.asset(
                    'assets/images/global/ic_black_back.png',
                    width: 26.w,
                    height: 26.w,
                  ),
                ),
              ),

              Text(
                title,
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#232535".color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              Container(color: Colors.transparent, width: 50.w, height: 40.w),
            ],
          ),
        ),
      ],
    );
  }
}
