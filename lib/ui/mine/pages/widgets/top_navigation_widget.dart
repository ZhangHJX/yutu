import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'page_navigation_bar.dart';

class TopNavigationWidget extends StatelessWidget {
  const TopNavigationWidget({
    super.key,
    required this.title,
    required this.rightTitle,
    required this.onTap,
  });

  final String title;
  final String rightTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PageNavigationBar(
      child: Column(
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
                IconButton(
                  padding: EdgeInsets.only(right: 5.w),
                  icon: Image.asset(
                    'assets/images/global/ic_black_back.png',
                    width: 26.w,
                    height: 26.w,
                  ),
                  onPressed: () {
                    EventBusManager.share.emit(AppEventType.mineRefresh);
                    Get.back();
                  },
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.w,
                    color: "#232535".color,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                GestureDetector(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20.w),
                    child: Text(
                      rightTitle,
                      style: TextStyle(
                        fontSize: 13.w,
                        color: "#6C64FF".color,
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
}
