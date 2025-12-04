import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_status_bar.dart';
import 'logic.dart';

class SetPage extends StatelessWidget {
  SetPage({super.key});

  final SetLogic logic = Get.put(SetLogic());

  final TextEditingController _oneController = TextEditingController();
  final TextEditingController _twoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AppStatusBar(),
          Column(
            children: [
              CAppBar(
                title: const Text(
                  '设置密码',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.transparent,
              ),

              SizedBox(height: 24.w),

              _buildNewPassworldField(),
              SizedBox(height: 14.w),

              _buildAgainPassworldField(),

              SizedBox(height: 50.w),

              GestureDetector(
                onTap: saveSetPassword,
                child: Container(
                  height: 48.w,
                  margin: EdgeInsets.only(
                    left: 29.w,
                    right: 29.w,
                    bottom: 51.w,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 29.w),
                  decoration: BoxDecoration(
                    color: "#64A2FF".color,
                    image: DecorationImage(
                      image: AssetImage('assets/images/login/login_btn_bg.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(24.w),
                  ),
                  child: Center(
                    child: Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 16.w,
                        fontWeight: FontWeight.w500,
                        color: "#FFFFFF".color,
                      ),
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

  void saveSetPassword() {}

  Widget _buildNewPassworldField() {
    return Container(
      height: 48.w,
      margin: EdgeInsets.symmetric(horizontal: 29.w),
      decoration: BoxDecoration(
        color: "#F4F4F4".color,
        borderRadius: BorderRadius.circular(24.w),
      ),
      padding: EdgeInsets.only(left: 26.w, right: 15.w),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _oneController,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '请输入验证码',
                hintStyle: TextStyle(
                  fontSize: 14.w,
                  color: "#9E9E9E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onChanged: (value) => logic.password.value = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgainPassworldField() {
    // 密码登录：输入密码 + 密码可见性切换
    return Container(
      height: 48.w,
      margin: EdgeInsets.symmetric(horizontal: 29.w),
      decoration: BoxDecoration(
        color: "#F4F4F4".color,
        borderRadius: BorderRadius.circular(24.w),
      ),
      padding: EdgeInsets.only(left: 26.w, right: 15.w),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _twoController,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '再次输入密码',
                hintStyle: TextStyle(
                  fontSize: 14.w,
                  color: "#9E9E9E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onChanged: (value) => logic.password.value = value,
            ),
          ),
        ],
      ),
    );
  }
}
