import 'package:common/common.dart';
import 'package:flutter/widgets.dart';
import 'login_response.dart';
import 'user_model.dart';

/// 登录方式
enum LoginMode {
  sms, // 验证码登录
  /// 账号密码登录
  password, //
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

  /// 用户是否登录
  bool get isLogin => accessToken.value.isNotEmpty;

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

  /// 用户头像
  String? get avatar => userInfo.value.avatar;

  /// 昵称
  String? get nickname => userInfo.value.nickname;

  /// 手机号
  String? get phone => userInfo.value.mobile;

  // /// 个性签名
  String? get sign => userInfo.value.sign;

  // /// 生日
  // String? get birthday => userInfo.value.birthday;

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

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();

    accessToken.value = box.read(tokenKey) ?? '';
    userInfo.value = UserModel.fromJson(box.read(userInfoKey) ?? {});

    ever(accessToken, (token) {
      box.write(tokenKey, token);
    });

    ever(userInfo, (user) {
      box.write(userInfoKey, user.toJson());
    });

    // if (accessToken.value.isNotEmpty) {
    //   updateUserToken();
    // }
  }

  /// 获取用户信息
  void fetchUserInfo() async {
    try {
      final result = await http.post<UserModel>(
        '/homePage/user/index',
        converter: UserModel.fromJson,
        withToken: true,
      );
      userInfo.value = result.data ?? UserModel();
      if (result.code == 0) {
        Get.back();
      }
    } catch (e) {
      debugPrint('===========  error: $e');
    }
  }

  /// 获取更新Token值
  void updateUserToken() async {
    try {
      final result = await http.post(
        '/homePage/user/refreshUserToken',
        // converter: UserModel.fromJson,
        withToken: true,
      );
      debugPrint('updateUserToken====$result=======${result.data}');
    } catch (e) {
      debugPrint('updateUserToken===========$e');
    }
  }

  // /// 跳转到主页
  // /// [index] 跳转的tab索引
  // void toMain(int index) {
  //   Get.until((route) => Get.currentRoute == AppRoutes.main);
  //   tabIndex.value = index;
  // }

  /// 更新用户信息
  void updateUserInfo({String? nickname, String? avatar, String? sign}) {
    userInfo.value = userInfo.value.copyWith(
      nickname: nickname,
      avatar: avatar,
      sign: sign,
    );
  }

  /// 退出登录
  void logout() async {
    final result = await http.post(
      '/homePage/user/logout',
      withToken: true,
      showErrorToast: true,
    );
    if (result.code == 0) {
      accessToken.value = '';
      userInfo.value = UserModel();
    }
  }

  // /// 获取配置的客服类型
  // /// 客服类型, 2为微信, 其他为应用内客服
  // void fetchServiceType() {
  //   http.get('/ds-applet/message/getCustomerService').then((value) {
  //     serviceType.value = value.data ?? '2';
  //   });
  // }
}

/// 获取验证码
// Future<String> getVerifyCode() async {
//   final globalLogic = Get.find<GlobalLogic>();
//   showLoading('获取验证码中...');
//   final completer = Completer<String>();
//   try {
//     final codeId =
//         (await http.get(
//           '/ds-applet/member/sendSetPassCode',
//           query: {'phone': globalLogic.phone},
//           converter: primitiveConverter<String>(),
//         )).data ??
//         '';
//     showToast('验证码已发送');
//     completer.complete(codeId);
//   } catch (e) {
//     completer.completeError(e);
//   } finally {
//     SmartDialog.dismiss(status: SmartStatus.loading);
//   }
//   return completer.future;
// }


/*
final data = await http.post(
      '/ds-app/appletDynamic/discoveryList/${globalLogic.memberId}',
      data: {'labelList': [], 'discoveryBoardDTOList': discoveryBoardDTOList},
     converter: listConverter(DiscoveryModel.fromJson),
);
*/ 

