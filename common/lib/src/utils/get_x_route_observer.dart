import 'package:common/common.dart';
import 'package:flutter/material.dart';

class GetXRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    RouterReportManager.reportCurrentRoute(route);
    debugPrint('didPush: ${route.settings.name}');
    history.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    RouterReportManager.reportRouteDispose(route);
    history.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    history.remove(oldRoute);
    if (newRoute != null) {
      history.add(newRoute);
    }
  }
}
