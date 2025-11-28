import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../widgets/app_status_bar.dart';
import 'person_info_input.dart';
import 'person_info_avatar.dart';
import 'person_logic.dart';

class PersonInfoPage extends StatelessWidget {
  PersonInfoPage({super.key});

  final logic = Get.put(PersonLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      resizeToAvoidBottomInset: true,
      body: Obx(() {
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

                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 13.w,
                    right: 13.w,
                    bottom: ScreenTools.bottomBarHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// 头像
                      PersonInfoAvatar(logic: logic),

                      SizedBox(height: 30.w),

                      ProfileInput(
                        label: "昵称",
                        controller: logic.nicknameCtrl,
                        hint: "输入昵称",
                        maxLength: 15,
                      ),

                      const SizedBox(height: 20),

                      ProfileInput(
                        label: "手机号",
                        readonly: true,
                        hint: logic.phone.value,
                        suffix: const Text(
                          "(已绑定)",
                          style: TextStyle(color: Color(0xFF4A8DFF)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ProfileInput(
                        label: "个性签名",
                        controller: logic.signatureCtrl,
                        maxLines: 5,
                        maxLength: 30,
                        hint: "输入你的签名吧~",
                      ),

                      const SizedBox(height: 30),

                      /// 保存按钮
                      GestureDetector(
                        onTap: logic.save,
                        child: Container(
                          height: 48,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF766BFE), Color(0xFF29A3FF)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "保存修改",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
