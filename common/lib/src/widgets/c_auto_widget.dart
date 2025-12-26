import 'package:common/common.dart';
import 'package:flutter/material.dart';

abstract class AutoGetView<T extends GetxController> extends GetView<T> {
  const AutoGetView({super.key});

  T get logic => controller;

  @override
  Widget build(BuildContext context);
}
