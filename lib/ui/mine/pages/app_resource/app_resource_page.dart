import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'app_resource_logic.dart';

class AppResourcePage extends StatelessWidget {
  AppResourcePage({super.key});

  final logic = Get.put(AppResourceLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: Column(
              children: [
                CAppBar(
                  title: Text(
                    logic.type == "draft" ? "我的草稿" : "我的素材",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                SizedBox(height: 33.w),

                /// 图标
                Image.asset(
                  "assets/images/global/app_info_logo.png",
                  width: 80.w,
                  height: 80.81.w,
                ),

                SizedBox(height: 25.w),

                /// 名称
                Text(
                  "语音厅设计助手",
                  style: TextStyle(
                    fontSize: 20.w,
                    color: "#232535".color,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 9.w),

                Text(
                  "让设计更简单",
                  style: TextStyle(fontSize: 16.w, color: "#848484 ".color),
                ),

                SizedBox(height: 14.w),

                /// 版本块
                Container(
                  height: 44.w,
                  margin: EdgeInsets.symmetric(horizontal: 13.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 13.w),
                      Text(
                        "当前版本",
                        style: TextStyle(
                          fontSize: 14.w,
                          color: "#121F33".color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "v",
                        style: TextStyle(
                          fontSize: 14.w,
                          color: "#1677FF".color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3.w),

                      Image.asset(
                        "assets/images/mine/app_info_check.png",
                        width: 16.w,
                        height: 16.w,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Text(
                        "© 2024 语音厅设计助手",
                        style: TextStyle(
                          color: "#9E9E9E".color,
                          fontSize: 11.w,
                        ),
                      ),
                      Text(
                        "All rights reserved",
                        style: TextStyle(
                          color: "#9E9E9E".color,
                          fontSize: 11.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部渐变背景
  Widget _buildHeaderBackground() {
    return Container(
      height: 146.w,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB1D5FF), Color(0xFFF5F6FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
