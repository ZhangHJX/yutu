import 'package:common/common.dart';

part 'upload_oss_model.g.dart';

@JsonSerializable()
class UploadOssModel {
  @JsonKey(name: 'sign_url')
  String signUrl;
  String endpoint;
  String bucket;
  String path;
  String file;
  @JsonKey(name: 'resource_id')
  int resourceId;

  UploadOssModel({
    this.signUrl = '',
    this.endpoint = '',
    this.bucket = '',
    this.path = '',
    this.file = '',
    this.resourceId = 0,
  });

  factory UploadOssModel.fromJson(Map<String, dynamic> json) =>
      _$UploadOssModelFromJson(json);

  Map<String, dynamic> toJson() => _$UploadOssModelToJson(this);
}
