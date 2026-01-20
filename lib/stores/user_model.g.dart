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
  mobile: json['mobile'] as String? ?? '',
  designCount: (json['design_count'] as num?)?.toInt() ?? 0,
  designFileSizeLimit: json['design_file_size_limit'] as String? ?? '',
  designFileSize: json['design_file_size'] as String? ?? '',
  designDraftFileSizeLimit:
      json['design_draft_file_size_limit'] as String? ?? '',
  designDraftFileSize: json['design_draft_file_size'] as String? ?? '',
  userMmaterialFileSizeLimit:
      json['user_material_file_size_limit'] as String? ?? '',
  userMaterialFileSize: json['user_material_file_size'] as String? ?? '',
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'sign': instance.sign,
  'mobile': instance.mobile,
  'design_file_size_limit': instance.designFileSizeLimit,
  'design_file_size': instance.designFileSize,
  'design_draft_file_size_limit': instance.designDraftFileSizeLimit,
  'design_draft_file_size': instance.designDraftFileSize,
  'user_material_file_size_limit': instance.userMmaterialFileSizeLimit,
  'user_material_file_size': instance.userMaterialFileSize,
  'design_count': instance.designCount,
};
