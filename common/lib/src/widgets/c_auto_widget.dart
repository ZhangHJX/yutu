import 'package:common/common.dart';
import 'package:flutter/material.dart';

abstract class AutoGetView<T extends GetxController> extends StatelessWidget {
  const AutoGetView({super.key});

  String? get tag => null;

  T get logic => Get.find<T>(tag: tag);

  @override
  Widget build(BuildContext context);
}
