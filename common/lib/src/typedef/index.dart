import 'package:flutter/material.dart';

typedef AsyncFunc<T> = Future<T> Function();

typedef WidgetCreator = Widget Function();

typedef ParamCallback<T> = void Function(T);

typedef Predicate<T> = bool Function(T value);
