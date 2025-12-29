import 'package:flutter/material.dart';
import 'package:common/common.dart';

class PageEmptyState extends StatelessWidget {
  const PageEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("--中间可滚动列表-----PageEmptyState-----");

    return Container(
      color: '#F5F5F5'.color,
      padding: EdgeInsets.only(top: 89.w),
      width: double.infinity,
      child: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                "assets/images/mine/app_resource_empty.png",
                width: 146.w,
                height: 146.w,
                fit: BoxFit.cover,
              ),

              Positioned(
                top: 130.w,
                child: SizedBox(
                  width: 146.w,
                  child: Center(
                    child: Text(
                      "暂无内容",
                      style: TextStyle(fontSize: 12.w, color: "#9E9E9E".color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
