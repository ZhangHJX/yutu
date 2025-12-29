import 'package:common/common.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import '../../widgets/app_status_bar.dart';
import 'logic.dart';

class PasswordPage extends StatelessWidget {
  final ForgetLogic logic = Get.put(ForgetLogic());

  PasswordPage({super.key});

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordOneController = TextEditingController();
  final TextEditingController _passwordTwoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // AppStatusBar(),
            Column(
              children: [
                CAppBar(
                  title: Text(
                    logic.global.isLogin ? "设置密码" : '忘记密码',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Colors.transparent,
                ),

                SizedBox(height: 24.w),

                _buildPhoneField(),
                SizedBox(height: 16.w),

                _buildYanZhengField(),
                SizedBox(height: 16.w),

                _buildNewPassworldField(),
                SizedBox(height: 16.w),

                _buildAgainPassworldField(),

                Spacer(),

                GestureDetector(
                  onTap: logic.changePassWord,
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
                        image: AssetImage(
                          'assets/images/login/login_btn_bg.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(24.w),
                    ),
                    child: Center(
                      child: Text(
                        '登录',
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
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      height: 48.w,
      margin: EdgeInsets.symmetric(horizontal: 29.w),
      decoration: BoxDecoration(
        color: "#F4F4F4".color,
        borderRadius: BorderRadius.circular(24.w),
      ),
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      alignment: Alignment.center,
      child: Row(
        children: [
          Text(
            '+ 86',
            style: TextStyle(fontSize: 16.w, color: "#797979".color),
          ),
          SizedBox(width: 9.w),
          Container(width: 2.w, height: 16.w, color: "#D8D8D8".color),
          SizedBox(width: 10.w),

          Expanded(
            child: TextField(
              controller: logic.phoneController,
              keyboardType: TextInputType.number,
              enabled: !logic.global.isLogin,
              inputFormatters: [LengthLimitingTextInputFormatter(11)],
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '请输入手机号码',
                hintStyle: TextStyle(
                  fontSize: 14.w,
                  color: "#9E9E9E".color,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onChanged: (value) => logic.phone.value = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYanZhengField() {
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
              controller: _codeController,
              keyboardType: TextInputType.number,
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
              onChanged: (value) => logic.code.value = value,
            ),
          ),

          Obx(
            () => TextButton(
              onPressed: logic.validatePhoneNumber,
              child: Text(
                logic.isCountingDown.value
                    ? '${logic.countDown.value}s'
                    : '获取验证码',
                style: TextStyle(
                  fontSize: 12.w,
                  color: "#3691FF".color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              controller: _passwordOneController,
              obscureText: true,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '请输入密码',
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
              controller: _passwordTwoController,
              obscureText: true,
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
              onChanged: (value) => logic.again.value = value,
            ),
          ),
        ],
      ),
    );
  }
}
