import 'package:common/common.dart';
import 'package:flutter/material.dart';

final ps = PixelSnap.of(Get.context!);

final hairline = ps(0.5);

/// 边框颜色为 0xFFEAEAEA
final borderSide = BorderSide(color: Color(0xFFEAEAEA), width: hairline);

BorderSide getBorderSide(Color color) => BorderSide(color: color, width: hairline);
