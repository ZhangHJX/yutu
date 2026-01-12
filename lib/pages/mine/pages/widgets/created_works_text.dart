import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CreatedWorksText extends StatelessWidget {
  const CreatedWorksText({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = TextStyle(
      fontSize: 13.w,
      color: const Color(0xFF848484),
      fontWeight: FontWeight.w500,
    );

    final TextStyle numberStyle = baseStyle.copyWith(
      color: const Color(0xFF6594FF),
      fontWeight: FontWeight.w400,
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '已创建 '),
          TextSpan(text: '$count', style: numberStyle),
          const TextSpan(text: '个作品'),
        ],
      ),
    );
  }
}
