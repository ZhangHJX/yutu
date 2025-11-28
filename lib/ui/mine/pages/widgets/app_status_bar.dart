import 'package:common/common.dart';
import 'package:flutter/material.dart';

class AppStatusBar extends StatelessWidget {
  const AppStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 146.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ["#9ADEFD".color, "#FFFFFF".color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
