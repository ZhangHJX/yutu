import 'package:common/common.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        backgroundColor: "#F5F5F5".color,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Image.asset(
                'assets/images/global/mine_top_bg.png',
                fit: BoxFit.cover,
                height: 240.w,
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 51.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            EventBusManager.share.emit(
                              AppEventType.mineRefresh,
                            );
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
                          logic.global.isLogin ? "设置密码" : '忘记密码',
                          style: TextStyle(
                            fontSize: 16.w,
                            color: "#232535".color,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        Container(
                          color: Colors.transparent,
                          width: 50.w,
                          height: 40.w,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.w),

                  _buildPhoneField(),
                  SizedBox(height: 16.w),

                  _buildYanZhengField(),
                  SizedBox(height: 16.w),

                  _buildNewPassworldField(),

                  SizedBox(height: 6.w),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 29.w),
                    child: Text(
                      '请输入6-20位之间，包含字母、数字的密码',
                      style: TextStyle(fontSize: 12.w, color: "#7662FF".color),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(height: 13.w),
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
        color: Colors.white,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextStyle(
                color: '#474747'.color,
                fontSize: 14.w,
                fontWeight: FontWeight.w500,
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
        color: Colors.white,
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
              inputFormatters: [LengthLimitingTextInputFormatter(4)],
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
              style: TextStyle(
                color: '#474747'.color,
                fontSize: 14.w,
                fontWeight: FontWeight.w500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w),
      ),
      padding: EdgeInsets.only(left: 26.w, right: 15.w),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              return TextField(
                controller: _passwordOneController,
                obscureText: !logic.isNewPasswordVisible.value,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '请输入新密码',
                  hintStyle: TextStyle(
                    fontSize: 14.w,
                    color: "#9E9E9E".color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                style: TextStyle(
                  color: '#474747'.color,
                  fontSize: 14.w,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) => logic.password.value = value,
              );
            }),
          ),
          Obx(
            () => GestureDetector(
              onTap: logic.toggleNewPasswordVisibility,
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: Center(
                  child: Image.asset(
                    logic.isNewPasswordVisible.value
                        ? 'assets/images/login/login_visibility.png'
                        : 'assets/images/login/login_no_visibility.png',
                    width: 18.w,
                    height: 14.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w),
      ),
      padding: EdgeInsets.only(left: 26.w, right: 15.w),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              return TextField(
                controller: _passwordTwoController,
                obscureText: !logic.isAgainPasswordVisible.value,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
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
                style: TextStyle(
                  color: '#474747'.color,
                  fontSize: 14.w,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) => logic.again.value = value,
              );
            }),
          ),
          Obx(
            () => GestureDetector(
              onTap: logic.toggleAgainPasswordVisibility,
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: Center(
                  child: Image.asset(
                    logic.isAgainPasswordVisible.value
                        ? 'assets/images/login/login_visibility.png'
                        : 'assets/images/login/login_no_visibility.png',
                    width: 18.w,
                    height: 14.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
