import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CKeepAlive extends HookWidget {
  const CKeepAlive({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    return child;
  }
}
