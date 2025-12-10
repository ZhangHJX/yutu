import 'package:common/common.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  int id;
  String nickname;
  String avatar;
  String sign;
  String mobile;
  int count;

  UserModel({
    this.id = 0,
    this.nickname = '',
    this.avatar = '',
    this.sign = '',
    this.mobile = '',
    this.count = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// 推荐加一个 copyWith，方便更新部分字段
  UserModel copyWith({
    int? id,
    String? nickname,
    String? avatar,
    String? sign,
    String? mobile,
    int? count,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      sign: sign ?? this.sign,
      mobile: mobile ?? this.mobile,
      count: count ?? this.count,
    );
  }
}
