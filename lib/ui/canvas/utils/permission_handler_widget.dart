import 'package:common/common.dart';
import 'package:flutter/material.dart';

class PermissionHandlerWidget extends StatefulWidget {
  const PermissionHandlerWidget({super.key});

  @override
  State<PermissionHandlerWidget> createState() =>
      _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  @override
  void initState() {
    super.initState();
  }

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
              '提示',
              style: TextStyle(
                fontSize: 18.w,
                color: "#232535".color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 46.w),
            child: Text(
              '打开相册以上传图片到编辑器\n中进行进一步编辑',
              style: TextStyle(
                fontSize: 16.w,
                color: "#434343".color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Spacer(),

          // 标题栏
          Row(
            children: [
              SizedBox(width: 20.w),
              GestureDetector(
                onTap: () => SmartDialog.dismiss(),
                child: Container(
                  width: 114.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: "#E8E8E8".color,
                    borderRadius: BorderRadius.circular(20.w),
                  ),
                  child: Center(
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16.w,
                        color: "#222325".color.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              GestureDetector(
                onTap: () {
                  SmartDialog.dismiss();
                  AppSettings.openAppSettings(type: AppSettingsType.settings);
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
                      '同意',
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

          SizedBox(height: 26.w),
        ],
      ),
    );
  }
}
