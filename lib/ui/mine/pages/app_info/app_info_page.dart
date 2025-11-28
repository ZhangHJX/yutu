import 'package:common/common.dart';
import 'package:flutter/material.dart';

import '../widgets/app_status_bar.dart';

import '../../../utils/app_info/app_info_utils.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await AppInfoUtils.getAppVersion();
    setState(() {
      _version = version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      body: Stack(
        children: [
          AppStatusBar(),
          SafeArea(
            child: Column(
              children: [
                CAppBar(
                  title: const Text(
                    '软件信息',
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
                        "v$_version",
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
}
