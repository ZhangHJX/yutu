import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'event_enum.dart';

/// 事件类型
class BusEvent<T> {
  final AppEventType type;
  final T? data;
  BusEvent(this.type, {this.data});
}

/// 事件管理
class EventBusManager {
  EventBusManager._();
  static final EventBusManager share = EventBusManager._();
  final _bus = EventBus();

  void emit<T>(AppEventType type, {T? data}) =>
      _bus.fire(BusEvent<T>(type, data: data));

  StreamSubscription listenAll(void Function(BusEvent e) handler) {
    return _bus.on<BusEvent>().listen(handler);
  }
}
