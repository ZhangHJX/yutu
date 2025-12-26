import 'dart:math';

import 'package:common/src/entry.dart';
import 'package:flutter/material.dart';

class CExchangeTag extends StatelessWidget {
  const CExchangeTag({super.key, this.duration = const Duration(milliseconds: 2000)});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: .only(top: 6.w),
      child: Image.asset('assets/images/mall/ic_exchange.png', fit: BoxFit.fitHeight, height: 11.w)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: duration, angle: pi / 4, size: .3, curve: Curves.ease),
    );
  }
}
