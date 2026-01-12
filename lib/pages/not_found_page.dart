import 'package:common/common.dart';
import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  NotFoundPage({super.key});

  final dynamic arguments = Get.arguments;
  final previousRoute = Get.previousRoute;
  final parameters = Get.parameters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('404')),
      body: Center(
        child: DefaultTextStyle(
          style: TextStyle(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('哇呜! 您要找的页面走丢了~'),

              const SizedBox(height: 20),
              Text('previousRoute: $previousRoute'),

              if (arguments != null)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Text('arguments: ${arguments?.toString()}'),
                  ],
                ),

              if (parameters.isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Text('parameters: $parameters'),
                  ],
                ),

              const SizedBox(height: 20),
              CButton(
                text: '返回上一页',
                onPressed: Get.back,
                padding: const EdgeInsets.all(6),
                borderRadius: 4,
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
