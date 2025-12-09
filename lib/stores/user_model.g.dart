// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  nickname: json['nickname'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  sign: json['sign'] as String? ?? '',
  workCount: (json['workCount'] as num?)?.toInt() ?? 0,
  phone: json['phone'] as String? ?? '',
  token: json['token'] as String? ?? '',
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'sign': instance.sign,
  'workCount': instance.workCount,
  'phone': instance.phone,
  'token': instance.token,
};
