import 'package:common/src/utils/get_safe_padding.dart';
import 'package:flutter/material.dart';

/// 边框颜色为 0xFFEAEAEA
final borderSide = BorderSide(color: Color(0xFFEAEAEA), width: hairline);

BorderSide getBorderSide(Color color) =>
    BorderSide(color: color, width: hairline);
