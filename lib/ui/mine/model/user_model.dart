import 'package:common/common.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  /// 是否已登录
  bool isLogin;
  String avatar;
  String nickname;
  int workCount;
  String phone;
  String signature;
  List<String> designImages;

  UserModel({
    this.isLogin = false,
    this.avatar = '',
    this.nickname = '',
    this.workCount = 0,
    this.phone = '',
    this.signature = '',
    this.designImages = const [],
  });
}
