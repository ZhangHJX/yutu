import 'package:flutter/material.dart';

extension ToColor on String {
  Color get color => Color(int.parse(replaceAll('#', '0xFF')));
}

extension ToString on Color {
  /// #RRGGBB（不含透明度）
  String get string {
    final rHex = (r * 255).round().toRadixString(16).padLeft(2, '0');
    final gHex = (g * 255).round().toRadixString(16).padLeft(2, '0');
    final bHex = (b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${rHex.toUpperCase()}${gHex.toUpperCase()}${bHex.toUpperCase()}';
  }
}
