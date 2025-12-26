import 'package:flutter/material.dart';

extension ToColor on String {
  Color get color => Color(int.parse(replaceAll('#', '0xFF')));
}
