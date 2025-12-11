import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'person_logic.dart';

class PersonInfoAvatar extends StatelessWidget {
  final PersonLogic logic;
  const PersonInfoAvatar({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: 88.w,
        height: 88.w,
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/mine/mine_info_icon_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CBorderImage(
              size: 76.w,
              imgUrl: logic.avatar.value,
              isCircle: true,
            ),

            Positioned(
              bottom: -6,
              right: -6,
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
    );
  }
}
