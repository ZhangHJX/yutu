import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mine_main_page.dart';

class MinePage extends HookWidget {
  const MinePage({super.key});

  final name = "";

  // final logic = Get.put(ProfileLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: MineMainPage(),
      ),
    );
  }
}
