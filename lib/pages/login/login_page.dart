import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:voicetemplate/core/index.dart';
import 'logic.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginLogic logic = Get.put(LoginLogic());

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _onLogin() {
    logic.handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 背景图片
            Image.asset(
              'assets/images/login/app_login_bg.png',
              fit: BoxFit.cover,
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, top: 12.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque, // 或 opaque
                        onTap: () => Get.back(),
                        child: SizedBox(
                          width: 40.w,
                          height: 40.w,
                          child: Center(
                            child: Image.asset(
                              'assets/images/login/login_back_icon.png',
                              width: 8.w,
                              height: 16.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 250.w),
                  // 2. 输入区域
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 29.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPhoneField(),
                        SizedBox(height: 14.w),
                        _buildSecondField(),
                        SizedBox(height: 10.w),

                        Padding(
                          padding: EdgeInsets.only(right: 20.w),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Obx(
                              () => GestureDetector(
                                onTap: () => logic.onTogglePasswordLogin(
                                  _codeController,
                                  _passwordController,
                                ),
                                child: Text(
                                  logic.isPasswordLogin.value
                                      ? '验证码登录'
                                      : '密码登录',
                                  style: TextStyle(
                                    fontSize: 12.w,
                                    color: "#A7A7A7".color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 15.w),

                        Obx(
                          () => GestureDetector(
                            onTap: logic.canLogin.value ? _onLogin : null,
                            child: Container(
                              height: 48.w,
                              padding: EdgeInsets.symmetric(horizontal: 29.w),
                              decoration: BoxDecoration(
                                color: logic.canLogin.value
                                    ? Colors.transparent
                                    : "#64A2FF".color,
                                image: logic.canLogin.value
                                    ? const DecorationImage(
                                        image: AssetImage(
                                          'assets/images/login/login_btn_bg.png',
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(24.w),
                              ),
                              child: Center(
                                child: Text(
                                  '登录',
                                  style: TextStyle(
                                    fontSize: 16.w,
                                    fontWeight: FontWeight.w500,
                                    color: logic.canLogin.value
                                        ? "#FFFFFF".color
                                        : "#1C004C".color.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 8. 忘记密码（仅密码登录时）
                        Obx(
                          () => logic.isPasswordLogin.value
                              ? Column(
                                  children: [
                                    SizedBox(height: 12.w),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () => Get.toNamed(
                                          AppRoutes.password,
                                          arguments: true,
                                        ),
                                        child: Text(
                                          '忘记密码？',
                                          style: TextStyle(
                                            fontSize: 12.w,
                                            color: "#64A2FF".color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),
                  //  协议勾选区域
                  _buildAgreementArea(),
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
          Container(width: 2, height: 16.w, color: "#D8D8D8".color),
          SizedBox(width: 10.w),

          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
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

  Widget _buildSecondField() {
    return Obx(() {
      if (!logic.isPasswordLogin.value) {
        return Container(
          height: 48.w,
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
                  autofillHints: const [AutofillHints.oneTimeCode],
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

      // 密码登录：输入密码 + 密码可见性切换
      return Container(
        height: 48.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.w),
        ),
        padding: EdgeInsets.only(left: 26.w, right: 20.w),
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => TextField(
                  controller: _passwordController,
                  obscureText: !logic.isPasswordVisible.value,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '请输入6-20位密码',
                    hintStyle: TextStyle(
                      fontSize: 14.w,
                      color: "#9E9E9E".color,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onChanged: (value) => logic.password.value = value,
                ),
              ),
            ),

            Obx(
              () => GestureDetector(
                onTap: logic.togglePasswordVisibility,
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: Center(
                    child: Image.asset(
                      logic.isPasswordVisible.value
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
    });
  }

  Widget _buildAgreementArea() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(width: 60.w),
              Image.asset(
                'assets/images/login/login_agree_tips.png',
                width: 107.w,
                height: 29.6.w,
                fit: BoxFit.cover,
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: logic.onToggleAgreement,
                child: Container(
                  color: Colors.transparent,
                  width: 20.w,
                  height: 20.w,
                  child: Center(
                    child: Image.asset(
                      logic.isAgreement.value
                          ? 'assets/images/login/login_agree.png'
                          : 'assets/images/login/login_agree_no.png',
                      width: 12.w,
                      height: 12.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 2.w),

              Text(
                '我已阅读并同意 ',
                style: TextStyle(
                  fontSize: 11.w,
                  color: "#000000".color.withValues(alpha: 0.5),
                ),
              ),
              GestureDetector(
                onTap: logic.onPrivacyPolicyTap,
                child: Text(
                  '《隐私协议》',
                  style: TextStyle(fontSize: 11.w, color: "#6F62FF".color),
                ),
              ),
              Text(
                ' 和 ',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: "#000000".color.withValues(alpha: 0.5),
                ),
              ),
              GestureDetector(
                onTap: logic.onUserAgreementTap,
                child: Text(
                  '《用户协议》',
                  style: TextStyle(fontSize: 11.w, color: "#6F62FF".color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
