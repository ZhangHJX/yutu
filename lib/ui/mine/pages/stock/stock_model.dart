import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(explicitToJson: true)
class StockModel {
  int id;
  String title;
  final int sizeBytes; // 用于统计占用空间

  StockModel({required this.id, required this.title, required this.sizeBytes});
}
