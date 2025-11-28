import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'person_logic.dart';

class PersonInfoAvatar extends StatelessWidget {
  final PersonLogic logic;
  const PersonInfoAvatar({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: logic.pickAvatar,
      child: Obx(
        () => Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/mine/mine_info_icon_bg.png",
                  ), // 或 NetworkImage(...)
                  fit: BoxFit.cover, // 拉伸方式：cover / contain 等
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: ClipOval(
                        child: logic.avatar.isEmpty
                            ? Container(
                                width: 76.w,
                                height: 76.w,
                                color: Color(0xFFF2F3F7),
                                child: Icon(Icons.person_outline, size: 32.w),
                              )
                            :
                              // : Image.network(
                              //     user.avatar,
                              //     width: 56,
                              //     height: 56,
                              //     fit: BoxFit.cover,
                              //   ),
                              Image.asset(
                                "assets/images/mine/mine_info_editor.png",
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Image.asset(
                      "assets/images/mine/person_info_camera.png",
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.cover,
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
}
