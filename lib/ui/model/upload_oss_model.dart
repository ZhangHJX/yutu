import 'package:json_annotation/json_annotation.dart';

part 'upload_oss_model.g.dart';

@JsonSerializable()
class UploadOssModel {
  @JsonKey(name: 'sign_url', defaultValue: '')
  String signUrl;
  @JsonKey(defaultValue: '')
  String endpoint;
  @JsonKey(defaultValue: '')
  String bucket;
  @JsonKey(defaultValue: '')
  String path;
  @JsonKey(defaultValue: '')
  String file;
  @JsonKey(name: 'resource_id', defaultValue: 0)
  int resourceId;

  UploadOssModel({
    required this.signUrl,
    required this.endpoint,
    required this.bucket,
    required this.path,
    required this.file,
    required this.resourceId,
  });

  factory UploadOssModel.fromJson(Map<String, dynamic> json) =>
      _$UploadOssModelFromJson(json);

  Map<String, dynamic> toJson() => _$UploadOssModelToJson(this);
}
