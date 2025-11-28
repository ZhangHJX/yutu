import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../model/user_model.dart';
import '../../controller/mine_logic.dart';

class PersonLogic extends GetxController {
  final globalLogic = Get.find<MineLogic>();

  // 获取到参数
  final userModel = Get.arguments is UserModel
      ? Get.arguments as UserModel
      : UserModel();

  /// 用户数据
  var avatar = "啊哈哈哈".obs;
  var nickname = "".obs;
  var phone = "".obs;
  var signature = "".obs;

  /// 输入控制器
  final nicknameCtrl = TextEditingController();
  final signatureCtrl = TextEditingController();

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

    avatar.value = "";
    nickname.value = "zhangmj";
    phone.value = "15669993907";
    signature.value = "你是世界上最好的人";

    nicknameCtrl.text = nickname.value;
    signatureCtrl.text = signature.value;
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
  Future<void> save() async {
    if (nicknameCtrl.text.trim().isEmpty) {
      Get.snackbar("提示", "请输入昵称");
      return;
    }

    final userModel = UserModel(
      avatar: avatar.value,
      nickname: nicknameCtrl.text.trim(),
      phone: phone.value,
      signature: signatureCtrl.text.trim(),
    );

    // final success = await repository.updateProfile(profile);
    // if (success) {
    //   Get.back();
    //   Get.snackbar("成功", "资料已更新");
    // }
  }
}
