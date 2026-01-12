import 'package:json_annotation/json_annotation.dart';
part 'stock_model.g.dart';

@JsonSerializable(explicitToJson: true)
class StockModel {
  @JsonKey(name: 'list', defaultValue: [])
  final List<StockItemModel> items;

  StockModel({required this.items});

  factory StockModel.fromJson(Map<String, dynamic> json) =>
      _$StockModelFromJson(json);

  Map<String, dynamic> toJson() => _$StockModelToJson(this);
}

@JsonSerializable()
class StockItemModel {
  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(defaultValue: '')
  final String image;

  @JsonKey(name: 'file_size', defaultValue: '')
  final String fileSize;
  @JsonKey(name: 'canvas_size', defaultValue: '')
  final String canvasSize;

  StockItemModel({
    required this.id,
    required this.image,
    required this.fileSize,
    required this.canvasSize,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) =>
      _$StockItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$StockItemModelToJson(this);
}
