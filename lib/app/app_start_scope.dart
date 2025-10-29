import 'package:common/common.dart';
import 'package:flutter/material.dart';

import 'app_config_init.dart';
import 'routes/index.dart';

class AppStartScope extends HookWidget {
  const AppStartScope({super.key, this.minStartDurationMs = 600});

  final int minStartDurationMs;

  @override
  Widget build(BuildContext context) {
    final timeRecord = useState(DateTime.now().millisecondsSinceEpoch);

    final initialize = useMemoized(() {
      const envFileName = String.fromEnvironment(
        'ENV_FILE',
        defaultValue: '.env.prod',
      );
      return () async {
        await GetStorage.init();

        await dotenv.load(fileName: 'env/$envFileName');

        debugPrint('App启动环境:$envFileName');

        final dstMap = Map.fromEntries(dotenv.env.entries);
        await dotenv.load(fileName: 'env/.env', mergeWith: dstMap);

        final cost = DateTime.now().millisecondsSinceEpoch - timeRecord.value;
        debugPrint('App启动耗时:$cost ms');
        final waitTime = minStartDurationMs - cost;

        if (waitTime > 0) {
          await Future.delayed(Duration(milliseconds: waitTime));
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await Get.offNamed(AppRoutes.main);
      };
    }, []);

    useEffect(() {
      initialize();

      return null;
    }, [initialize]);

    return const AppConfigInit();
  }
}
