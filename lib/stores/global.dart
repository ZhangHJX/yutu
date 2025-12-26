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

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();

    accessToken.value = box.read(tokenKey) ?? '';
    userInfo.value = UserModel.fromJson(box.read(userInfoKey) ?? {});

    addInterceptor();

    ever(accessToken, (token) {
      box.write(tokenKey, token);
    });

    ever(userInfo, (user) {
      box.write(userInfoKey, user.toJson());
    });

    if (accessToken.value.isNotEmpty) {
      updateUserToken();
    }
  }

  /// 获取用户信息
  void fetchUserInfo({bool isLaunch = false}) async {
    try {
      final result = await http.post<UserModel>(
        '/homePage/user/index',
        converter: UserModel.fromJson,
        withToken: true,
      );
      userInfo.value = result.data ?? UserModel();
      if (result.code == 0 && !isLaunch) {
        Get.back();
      }
    } catch (e) {
      debugPrint('===========  error: $e');
    }
  }

  /// 获取更新Token值
  void updateUserToken() async {
    try {
      final result = await http.post<LoginResponse>(
        '/homePage/user/refreshUserToken',
        converter: LoginResponse.fromJson,
        withToken: true,
      );
      if (result.code == 0) {}
      debugPrint(
        'updateUserToken====${result.code}=======${result.data?.token}',
      );
    } catch (e) {
      debugPrint('updateUserToken===========$e');
    }
  }

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
      removeUserInfo();
    }
  }

  void removeUserInfo() {
    accessToken.value = '';
    userInfo.value = UserModel();
  }

  void addInterceptor() {
    http.addInterceptor(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final token = box.read(tokenKey);
          if (options.extra[withTokenKey] && token != null) {
            options.headers['token'] = token;
          }
          return handler.next(options);
        },
      ),
    );
  }
}
