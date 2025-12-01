import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../../../stores/user_model.dart';
import 'package:voicetemplate/stores/global.dart';

class PersonLogic extends GetxController {
  final global = Get.find<GlobalLogic>();

  final userModel = Get.arguments is UserModel
      ? Get.arguments as UserModel
      : UserModel();

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
    // loading.value = true;
    // final data = await repository.fetchProfile();
    // loading.value = false;

    final profile = userModel;
    avatar.value = profile.avatar.isNotEmpty ? profile.avatar : "";
    nickname.value = profile.nickname.isNotEmpty ? profile.nickname : "zhangmj";
    phone.value = profile.phone.isNotEmpty ? profile.phone : "15669993907";
    signature.value = profile.signature.isNotEmpty
        ? profile.signature
        : "你是世界上最好的人";

    nicknameCtrl.text = nickname.value;
    signatureCtrl.text = signature.value;
    phoneCtrl.text = phone.value;
    phoneBound.value = phone.value.isNotEmpty;
  }

  /// 上传头像
  Future<void> pickAvatar() async {
    // final picker = ImagePicker();
    // final img = await picker.pickImage(source: ImageSource.gallery);
    // if (img != null) {
    //   avatar.value = img.path; // 本地路径
    // }
  }

  /// 保存资料
  @override
  void onClose() {
    nicknameCtrl.dispose();
    signatureCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }

  Future<void> save() async {
    if (nicknameCtrl.text.trim().isEmpty) {
      Get.snackbar("提示", "请输入昵称");
      return;
    }

    final updatedProfile = UserModel(
      avatar: avatar.value,
      nickname: nicknameCtrl.text.trim(),
      phone: phoneCtrl.text.trim().isNotEmpty
          ? phoneCtrl.text.trim()
          : phone.value,
      signature: signatureCtrl.text.trim(),
    );
    global.userInfo.value = updatedProfile;

    // final success = await repository.updateProfile(profile);
    // if (success) {
    //   Get.back();
    //   Get.snackbar("成功", "资料已更新");
    // }
  }
}
