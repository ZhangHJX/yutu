import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../utils/index.dart';

import 'server_page_model.dart';
import '../../zmj/index.dart';

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
    final message = json[messageKey];

    T? data;

    /// 退出登陆处理
    if (code == -1) {
      EventBusManager.share.emit(AppEventType.logout);
    }
    debugPrint("=====$json=====接口返回信息===${HttpStatus.ok}===$message");

    try {
      if (rawData is Map) {
        data = fromJsonT(Map<String, dynamic>.from(rawData));
      } else {
        data = fromJsonT({dstValueKey: rawData});
      }
    } finally {
      if (HttpStatus.ok == 200) {
        if (showErrorToast && message.isNotEmpty) {
          debugPrint("你走的是哪个 toast 提示====下====");
          showToastAfterLoading(message);
        }
      } else {
        showToastAfterLoading(message);
      }
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
