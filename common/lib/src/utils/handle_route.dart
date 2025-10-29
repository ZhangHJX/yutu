import 'package:flutter/material.dart';

final List<Route> history = [];

bool hasRoute(String name) {
  final has = history.any((element) => element.settings.name == name);
  debugPrint('hasRoute========>>route:$name, has:$has');
  return has;
}
