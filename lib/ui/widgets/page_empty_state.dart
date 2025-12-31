import 'package:flutter/material.dart';
import 'package:common/common.dart';

class PageEmptyState extends StatelessWidget {
  const PageEmptyState({super.key, this.title = "暂无内容"});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
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
                      title,
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
