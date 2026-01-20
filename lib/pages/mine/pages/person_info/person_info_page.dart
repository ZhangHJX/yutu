import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'person_info_input.dart';
import 'person_info_avatar.dart';
import 'person_logic.dart';
import '../widgets/top_navigation_widget.dart';
import 'package:voicetemplate/pages/utils/file/index.dart';

class PersonInfoPage extends StatelessWidget {
  PersonInfoPage({super.key});

  final logic = Get.put(PersonLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(top: false, child: _buildSaveButton(logic)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9ADEFD),
              Color(0xFFF7F7F7),
              Color(0xFFF7F7F7),
              Color(0xFFE3EEF7),
            ],
            stops: [0.0, 0.15, 0.15, 1.0],
          ),
        ),
        child: KeyboardDismissOnTap(
          child: KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
              final buttonBottom = isKeyboardVisible
                  ? keyboardInset + 12.w
                  : ScreenTools.bottomBarHeight + 12.w;
              final scrollBottomPadding = buttonBottom + 100.w;
              return Column(
                children: [
                  TopNavigationWidget(
                    title: "个人资料",
                    back: () async {
                      debugPrint("==个人资料===哈哈哈哈哈===");
                      await PickerImageManager.deleteDirectory();
                    },
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

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 10.w),
                                child: Text(
                                  '昵称',
                                  style: TextStyle(
                                    fontSize: 16.w,
                                    color: "#232535".color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              SizedBox(height: 15),

                              Container(
                                padding: EdgeInsets.only(
                                  left: 13.w,
                                  right: 13.w,
                                  top: 1.w,
                                  bottom: 1.w,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: logic.nicknameCtrl,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(15),
                                        ],
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          hintText: '输入昵称',
                                          hintStyle: TextStyle(
                                            color: "#848484".color,
                                            fontSize: 14.w,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: "#848484".color,
                                        ),
                                        onChanged: (value) {
                                          logic.nickname.value = value;
                                        },
                                      ),
                                    ),
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: logic.nicknameCtrl,
                                      builder: (context, value, child) {
                                        final current =
                                            value.text.characters.length;
                                        return Text(
                                          "$current/15",
                                          style: TextStyle(
                                            fontSize: 14.w,
                                            color: "#848484".color,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              changeValue: (value) {
                                logic.phone.value = value;
                              },
                            ),
                          ),

                          SizedBox(height: 16.w),

                          ProfileInput(
                            label: "个性签名",
                            controller: logic.signatureCtrl,
                            maxLines: 5,
                            maxLength: 40,
                            showCounter: true,
                            hint: "输入你的签名吧~",
                            changeValue: (value) {
                              logic.signature.value = value;
                            },
                          ),
                          SizedBox(height: 33.w),
                          Text(
                            '提示：修改的头像、昵称和个性签名将提交审核，审核\n通过后自动生效。请勿上传违规内容。',
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
