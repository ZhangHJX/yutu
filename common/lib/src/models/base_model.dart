import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/index.dart';

import 'server_page_model.dart';

typedef FutureListModel<T> = Future<BaseModel<ServerPageModel<T>>>;

typedef FuturePureListModel<T> = Future<BaseModel<List<T>>>;

const dstValueKey = 'value';
const codeKey = 'code';
const dataKey = 'data';
const messageKey = 'message';

class BaseModel<T> {
  BaseModel({required this.code, required this.message, this.data});

  factory BaseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
    bool showErrorToast,
  ) {
    final rawData = json[dataKey];
    final code = json[codeKey];
    final String message = json[messageKey] as String? ?? '';

    T? data;

    debugPrint('BaseModel===$rawData');

    if (showErrorToast && message.isNotEmpty) {
      showToast(message);
    }

    if (rawData is Map) {
      data = fromJsonT(rawData as Map<String, dynamic>);
    } else {
      data = fromJsonT({dstValueKey: rawData});
    }

    return BaseModel(code: code, message: message, data: data);
  }

  Map<String, dynamic> toJson() {
    return {codeKey: code, messageKey: message, dataKey: data};
  }

  bool get isSuccess => code == HttpStatus.ok;

  final int code;
  final String message;
  final T? data;
}

T Function(Map<String, dynamic>) primitiveConverter<T>() =>
    (json) => json[dstValueKey];

ServerPageModel<T> Function(Map<String, dynamic>) pageConverter<T>(
  T Function(Map<String, dynamic>) fromJsonT,
) {
  return (json) => ServerPageModel<T>.fromJson(
    json,
    (item) => fromJsonT(item as Map<String, dynamic>),
  );
}

List<T> Function(Map<String, dynamic>) listConverter<T>(
  T Function(Map<String, dynamic>) fromJsonT, [
  String? field,
]) {
  return (json) => JsonHelper.fromMapList(
    field == null ? json[dstValueKey] : json[field],
    fromJsonT,
  );
}
