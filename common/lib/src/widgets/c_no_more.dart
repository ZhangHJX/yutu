import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CNoMore extends StatelessWidget {
  const CNoMore({super.key, this.gap = 0});

  final double gap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: .only(top: gap),
        child: Row(
          mainAxisAlignment: .center,
          children: [Text('没有更多数据了', style: text989897())],
        ),
      ),
    );
  }
}
