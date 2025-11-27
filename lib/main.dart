import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app_start_scope.dart';

void main() async {
  Intl.defaultLocale = 'zh_CN';
  await initializeDateFormatting('zh_CN');

  runApp(const AppStartScope());
}
// 多语言适配  https://blog.csdn.net/zz00008888/article/details/145241603