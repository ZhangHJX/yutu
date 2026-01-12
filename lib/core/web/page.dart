import 'package:common/common.dart';
import 'package:flutter/material.dart';

class WebPage extends HookWidget {
  WebPage({super.key});

  final String url = Get.arguments is String
      ? Get.arguments
      : Get.arguments['url'] is String
      ? Get.arguments['url']
      : '';

  @override
  Widget build(BuildContext context) {
    final title = useState('');
    final progress = useState(0);

    final controller = useMemoized(() {
      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progressValue) {
            progress.value = progressValue;
          },
          onPageFinished: (String url) async {
            final pageTitle = await controller.runJavaScriptReturningResult(
              'document.title',
            );
            String cleanTitle = pageTitle.toString();
            if (cleanTitle.startsWith('"') && cleanTitle.endsWith('"')) {
              cleanTitle = cleanTitle.substring(1, cleanTitle.length - 1);
            }
            title.value = cleanTitle;
          },
        ),
      );

      controller.loadRequest(Uri.parse(url));

      return controller;
    }, []);

    return Scaffold(
      appBar: CAppBar(title: Text(title.value)),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (progress.value < 100)
            Positioned.fill(
              bottom: null,
              child: LinearProgressIndicator(
                value: progress.value / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}
