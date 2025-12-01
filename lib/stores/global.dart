import 'package:common/common.dart';
import 'user_model.dart';

/// 登录方式
enum LoginMode {
  /// 验证码登录
  sms,

  /// 账号密码登录
  password,
}

// import '../app/app_route.dart';
// import '../models/list_item.dart';
// import '../models/user_model.dart';
// import '../utils/apis/address.dart';

class GlobalLogic extends GetxController {
  /// TabBarController 索引
  final tabIndex = 0.obs;

  final accessToken = ''.obs;
  final userInfo = UserModel().obs;

  // /// 用户是否登录
  bool get isLogin => accessToken.value.isNotEmpty;

  /// 客服类型, 2为微信, 其他为应用内客服
  // final serviceType = '2'.obs;

  // /// 是否设置了支付密码
  // bool get isSetPassword => userInfo.value.isSetPassword == 1;

  /// ---------------- 登录相关状态（使用 GetX 全局管理） ----------------

  /// 当前登录方式
  final loginMode = LoginMode.sms.obs;

  /// 是否同意协议
  final agreementChecked = false.obs;

  /// 密码是否可见
  final passwordVisible = false.obs;

  /// 是否为验证码登录
  bool get isSmsLogin => loginMode.value == LoginMode.sms;

  /// 切换登录方式
  void toggleLoginMode() {
    loginMode.value = loginMode.value == LoginMode.sms
        ? LoginMode.password
        : LoginMode.sms;
    // 切换模式时重置密码可见
    passwordVisible.value = false;
  }

  /// 切换协议勾选
  void toggleAgreement() {
    agreementChecked.value = !agreementChecked.value;
  }

  /// 切换密码可见性
  void togglePasswordVisible() {
    passwordVisible.value = !passwordVisible.value;
  }

  /// 校验手机号：简单 11 位数字校验
  bool isPhoneValid(String phone) {
    final text = phone.trim();
    return RegExp(r'^1\\d{10}\$').hasMatch(text);
  }

  /// 校验第二个输入框内容
  bool isSecondValid(String text) {
    final value = text.trim();
    if (isSmsLogin) {
      // 验证码 4-6 位数字
      return RegExp(r'^\\d{4,6}\$').hasMatch(value);
    }
    // 密码 6-20 位
    return value.length >= 6 && value.length <= 20;
  }

  /// 是否可以点击登录按钮
  bool canLogin(String phone, String secondInput) {
    return isPhoneValid(phone) &&
        isSecondValid(secondInput) &&
        agreementChecked.value;
  }

  // /// 用户头像
  // String? get wechatAvatar => userInfo.value.wechatAvatar;

  // /// 会员id
  // String get memberId => userInfo.value.memberId ?? '';

  // /// 会员类型
  // int? get memberType => userInfo.value.memberType;

  // /// 会员昵称
  // String? get nickname => userInfo.value.wechatNickName;

  // /// 手机号
  // String? get phone => userInfo.value.mobile;

  // /// 个性签名
  // String? get signature => userInfo.value.signature;

  // /// 生日
  // String? get birthday => userInfo.value.birthday;

  // /// 代理人id
  // String? get agentId => userInfo.value.agentId;

  // /// 性别, 1为女, 2为男, 3为未知
  // int get gender => userInfo.value.gender;
  // String get genderText => switch (gender) {
  //   1 => '女',
  //   2 => '男',
  //   _ => '',
  // };

  // String? get authId => userInfo.value.authId;

  // /// 会员编号
  // String get memberNo => '${userInfo.value.memberNo}';

  // /// 是否开启了通知
  // bool get isNotify => userInfo.value.notify == 1;

  // /// 是否已认证
  // bool get isVerified => userInfo.value.authStatus == 2;

  // final box = GetStorage();

  // @override
  // void onInit() {
  //   super.onInit();

  //   accessToken.value = box.read(tokenKey) ?? '';
  //   userInfo.value = UserModel.fromJson(box.read(userInfoKey) ?? {});

  //   ever(accessToken, (token) {
  //     box.write(tokenKey, token);
  //   });

  //   ever(userInfo, (user) {
  //     box.write(userInfoKey, user);

  //     getAddressList();
  //   });

  //   Future.delayed(100.ms, getAddressList);
  // }

  // /// 跳转到主页
  // /// [index] 跳转的tab索引
  // void toMain(int index) {
  //   Get.until((route) => Get.currentRoute == AppRoutes.main);
  //   tabIndex.value = index;
  // }

  // /// 更新用户信息
  // /// [notify] 通知状态, 1为开启, 0为关闭
  // /// [authStatus] 认证状态, 1为未认证, 2为已认证
  // void updateUserInfo({
  //   int? notify,
  //   int? authStatus,
  //   int? gender,
  //   String? birthday,
  //   String? signature,
  //   String? wechatNickName,
  //   String? wechatAvatar,
  //   int? isSetPassword,
  // }) {
  //   userInfo.value = userInfo.value.copyWith(
  //     notify: notify,
  //     authStatus: authStatus,
  //     gender: gender,
  //     birthday: birthday,
  //     signature: signature,
  //     wechatNickName: wechatNickName,
  //     wechatAvatar: wechatAvatar,
  //     isSetPassword: isSetPassword,
  //   );
  // }

  // /// 退出登录
  // void logout() {
  //   accessToken.value = '';
  //   userInfo.value = UserModel();
  //   addressList.clear();
  // }

  // /// 获取用户信息
  // void fetchUserInfo() async {
  //   final ui = await http.get(
  //     '/zx-auth/auth/app/login/info',
  //     converter: UserModel.fromJson,
  //   );
  //   if (ui.data != null) {
  //     userInfo.value = ui.data!;
  //   }
  // }

  // /// 获取配置的客服类型
  // /// 客服类型, 2为微信, 其他为应用内客服
  // void fetchServiceType() {
  //   http.get('/ds-applet/message/getCustomerService').then((value) {
  //     serviceType.value = value.data ?? '2';
  //   });
  // }
}
