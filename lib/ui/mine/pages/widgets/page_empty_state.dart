import 'package:flutter/material.dart';
import 'package:common/common.dart';

class PageEmptyState extends StatelessWidget {
  const PageEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(top: 89.w + 44.w),
      child: Stack(
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
    );
  }
}
