import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/stores/global.dart';
import '../model/person_oss_model.dart';

class PersonLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  /// 用户数据
  var avatar = "啊哈哈哈".obs;
  var nickname = "".obs;
  var phone = "".obs;
  var signature = "".obs;
  final phoneBound = false.obs;

  /// 输入控制器
  final nicknameCtrl = TextEditingController();
  final signatureCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  /// 加载用户资料
  Future<void> loadProfile() async {
    avatar.value = global.avatar ?? "";
    nickname.value = global.nickname ?? "";
    phone.value = global.phone ?? "";
    signature.value = global.sign ?? "";

    nicknameCtrl.text = nickname.value;
    signatureCtrl.text = signature.value;
    phoneCtrl.text = phone.value;
    phoneBound.value = phone.value.isNotEmpty;
  }

  /// 上传头像
  Future<void> pickAvatar() async {
    // try {
    //   final result = await http.post<PersonOssModel>(
    //     '/upload/generateUploadUrl',
    //     data: {"type": "avatar", "file_type": "png"},
    //     converter: PersonOssModel.fromJson,
    //     showErrorToast: false,
    //     withToken: true,
    //   );
    //   debugPrint('===========  result: ${result.data?.signUrl}');
    // } catch (e) {
    //   debugPrint('===========  error: $e');
    // }
  }

  // {sign_url: http://yutu-1363209587.cos.ap-nanjing.myqcloud.com/image/avatar/avatar601471f1b97b218a4cbf7477d2bcb6e6.png?sign=q-sign-algorithm%3Dsha1%26q-ak%3DAKIDsmU1LUQ9fz63pOkspY6ScaKq8E6nJemg%26q-sign-time%3D1765335985%3B1765444045%26q-key-time%3D1765335985%3B1765444045%26q-header-list%3Dhost%26q-url-param-list%3D%26q-signature%3D72d5adb8b6aa5369aaeb48f33c75462dd0794bc9&,
  //  endpoint: ,
  //  bucket: yutu-1363209587,
  //  path: /image/avatar/avatar601471f1b97b218a4cbf7477d2bcb6e6.png,
  //  file: http://yutu-1363209587.cos.ap-nanjing.myqcloud.com/image/avatar/avatar601471f1b97b218a4cbf7477d2bcb6e6.png,
  //  resource_id: 3}

  Future<void> changeSave() async {
    if (nickname.value.trim().isEmpty) {
      showToast("请输入昵称");
      return;
    }

    // final updatedProfile = UserModel(
    //   avatar: avatar.value,
    //   nickname: nicknameCtrl.text.trim(),
    //   mobile: phoneCtrl.text.trim().isNotEmpty
    //       ? phoneCtrl.text.trim()
    //       : phone.value,
    //   // signature: signatureCtrl.text.trim(),
    // );

    try {
      final result = await http.post(
        '/user/edit',
        data: {
          "nickname": nickname.value,
          "avatar": avatar.value,
          "sign": signature.value,
        },
        withToken: true,
        showErrorToast: true,
      );
      debugPrint('===========  result: $result');
      if (result.code == 0) {
        Get.back();
      }
    } catch (e) {
      debugPrint('===========  error: $e');
    }
  }
}
