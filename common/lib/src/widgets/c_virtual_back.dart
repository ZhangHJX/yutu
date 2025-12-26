import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CVirtualBack extends StatelessWidget {
  const CVirtualBack({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        await _HandleVirtualBack.back();
      },
      child: child,
    );
  }
}

class _HandleVirtualBack {
  static const MethodChannel channel = MethodChannel('com.beefighting.mall/toBackground');

  static Future<bool> back() async {
    try {
      await channel.invokeMethod('toBackground');
    } catch (e) {
      debugPrint(e.toString());
    }
    return Future.value(false);
  }
}
