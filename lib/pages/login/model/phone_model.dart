import 'package:json_annotation/json_annotation.dart';

part 'phone_model.g.dart';

@JsonSerializable()
class PhoneModel {
  @JsonKey(defaultValue: '')
  final String mobile;

  PhoneModel({required this.mobile});

  factory PhoneModel.fromJson(Map<String, dynamic> json) =>
      _$PhoneModelFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneModelToJson(this);
}
