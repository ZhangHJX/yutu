import 'package:common/common.dart';

@JsonSerializable(explicitToJson: true)
class DesiginModel {
  int id;
  String title;
  int likeCount;

  DesiginModel({
    required this.id,
    required this.title,
    required this.likeCount,
  });
}
