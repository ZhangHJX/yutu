import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  int id;
  String nickname;
  String avatar;
  String sign;
  String mobile;
  int count;

  @JsonKey(name: 'design_file_size_limit')
  final String designFileSizeLimit;

  @JsonKey(name: 'design_file_size')
  final String designFileSize;

  @JsonKey(name: 'design_draft_file_size_limit')
  final String designDraftFileSizeLimit;

  @JsonKey(name: 'design_draft_file_size')
  final String designDraftFileSize;

  UserModel({
    this.id = 0,
    this.nickname = '',
    this.avatar = '',
    this.sign = '',
    this.mobile = '',
    this.count = 0,
    this.designFileSizeLimit = '',
    this.designFileSize = '',
    this.designDraftFileSizeLimit = '',
    this.designDraftFileSize = '',
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

  // --------- getters：KB -> MB（int，向下取整）---------
  int get designSize => _kbStringToMbInt(designFileSize);
  int get designSizeLimit => _kbStringToMbInt(designFileSizeLimit);

  int get draftSize => _kbStringToMbInt(designDraftFileSize);
  int get draftSizeLimit => _kbStringToMbInt(designDraftFileSizeLimit);

  // --------- helpers ---------
  static int _kbStringToMbInt(String kbStr) {
    final kb = _safeParseDouble(kbStr); // 字符串可能是 "1234.56"
    if (kb <= 0) return 0;
    return (kb / 1024).floor(); // KB -> MB，向下取整
  }

  static double _safeParseDouble(String v) {
    final s = v.trim();
    if (s.isEmpty) return 0;
    return double.tryParse(s) ?? 0;
  }
}
