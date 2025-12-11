import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../../widgets/app_status_bar.dart';
import 'person_info_input.dart';
import 'person_info_avatar.dart';
import 'person_logic.dart';

class PersonInfoPage extends StatelessWidget {
  PersonInfoPage({super.key});

  final logic = Get.put(PersonLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(top: false, child: _buildSaveButton(logic)),
      body: KeyboardDismissOnTap(
        child: KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) {
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
            final buttonBottom = isKeyboardVisible
                ? keyboardInset + 12.w
                : ScreenTools.bottomBarHeight + 12.w;
            final scrollBottomPadding = buttonBottom + 100.w;
            return Stack(
              children: [
                AppStatusBar(),
                Column(
                  children: [
                    CAppBar(
                      title: const Text(
                        '个人资料',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: Colors.transparent,
                    ),

                    SizedBox(height: 12.w),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 13.w,
                          right: 13.w,
                          bottom: scrollBottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// 头像
                            GestureDetector(
                              onTap: () => logic.handlePickAvatar(context),
                              child: PersonInfoAvatar(logic: logic),
                            ),

                            SizedBox(height: 24.w),

                            ProfileInput(
                              label: "昵称",
                              controller: logic.nicknameCtrl,
                              hint: "输入昵称",
                              maxLength: 15,
                            ),

                            SizedBox(height: 16.w),

                            Obx(
                              () => ProfileInput(
                                label: "手机号",
                                controller: logic.phoneCtrl,
                                readOnly: logic.phoneBound.value,
                                hint: logic.phoneBound.value
                                    ? logic.phone.value
                                    : "输入手机号",
                              ),
                            ),

                            SizedBox(height: 16.w),

                            ProfileInput(
                              label: "个性签名",
                              controller: logic.signatureCtrl,
                              maxLines: 5,
                              maxLength: 30,
                              showCounter: true,
                              hint: "输入你的签名吧~",
                            ),
                            SizedBox(height: 33.w),
                            Text(
                              '提示：修改的头像、呢称和个性签名将提交审核，审核\n通过后自动生效。请勿上传违规内容。',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11.w,
                                color: "#9E9E9E".color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Positioned(
                //   left: 13.w,
                //   right: 13.w,
                //   bottom: buttonBottom,
                //   child: _buildSaveButton(logic),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton(PersonLogic logic) {
    return GestureDetector(
      onTap: logic.changeSave,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 29.w),
        height: 48.w,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF766BFE), Color(0xFF29A3FF)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          "保存修改",
          style: TextStyle(color: Colors.white, fontSize: 16.w),
        ),
      ),
    );
  }
}
