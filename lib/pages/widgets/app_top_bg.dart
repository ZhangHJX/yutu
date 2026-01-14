import 'package:common/common.dart';
import 'package:flutter/material.dart';

class AppTopBg extends StatelessWidget {
  const AppTopBg({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240.w,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/global/top_navigation_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
