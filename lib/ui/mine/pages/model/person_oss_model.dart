import 'package:common/common.dart';

part 'person_oss_model.g.dart';

@JsonSerializable()
class PersonOssModel {
  @JsonKey(name: 'sign_url')
  String signUrl;
  String endpoint;
  String bucket;
  String path;
  String file;
  @JsonKey(name: 'resource_id')
  int resourceId;

  PersonOssModel({
    this.signUrl = '',
    this.endpoint = '',
    this.bucket = '',
    this.path = '',
    this.file = '',
    this.resourceId = 0,
  });

  factory PersonOssModel.fromJson(Map<String, dynamic> json) =>
      _$PersonOssModelFromJson(json);

  Map<String, dynamic> toJson() => _$PersonOssModelToJson(this);
}
