import 'package:common/common.dart';
import 'package:flutter/material.dart';

class AppResourceLogic extends GetxController {
  // 获取到参数
  String type = Get.arguments is String ? Get.arguments : null;
}
