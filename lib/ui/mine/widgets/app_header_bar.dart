import 'package:flutter/material.dart';

class AppHeaderBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? right;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;

    return Container(
      height: statusBar + 51,
      padding: EdgeInsets.only(top: statusBar),
      child: Row(
        children: [
          // 返回按钮
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 48),

          // 中间标题
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),

          // 右侧按钮（默认占位）
          right ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}
