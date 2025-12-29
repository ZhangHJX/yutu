import 'package:json_annotation/json_annotation.dart';
part 'stock_model.g.dart';

@JsonSerializable(explicitToJson: true)
class StockModel {
  @JsonKey(name: 'list')
  final List<StockItemModel> items;

  StockModel({required this.items});

  factory StockModel.fromJson(Map<String, dynamic> json) =>
      _$StockModelFromJson(json);

  Map<String, dynamic> toJson() => _$StockModelToJson(this);
}

@JsonSerializable()
class StockItemModel {
  final int? id;
  final String? image;
  @JsonKey(name: 'file_size')
  final String? fileSize;
  @JsonKey(name: 'canvas_size')
  final String? canvasSize;

  StockItemModel({this.id, this.image, this.fileSize, this.canvasSize});

  factory StockItemModel.fromJson(Map<String, dynamic> json) =>
      _$StockItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$StockItemModelToJson(this);
}
