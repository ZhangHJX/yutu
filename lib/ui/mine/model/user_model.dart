import 'package:common/common.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  /// 是否已登录
  bool isLogin;
  String avatar;
  String nickname;
  int workCount;
  List<String> designImages;

  UserModel({
    this.avatar = '',
    this.nickname = '',
    this.isLogin = false,
    this.workCount = 0,
    this.designImages = const [],
  });
}
