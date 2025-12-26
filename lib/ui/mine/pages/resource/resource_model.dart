import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(explicitToJson: true)
class ResourceModel {
  int id;
  String title;
  final int sizeBytes; // 用于统计占用空间

  ResourceModel({
    required this.id,
    required this.title,
    required this.sizeBytes,
  });
}
