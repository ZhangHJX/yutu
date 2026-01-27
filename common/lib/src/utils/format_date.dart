import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 格式化日期, 支持时间戳 和 字符串
///
/// [ymd] 是否返回完整日期
///
/// [showTime] 是否显示时间
///
/// [semantic] 是否返回语义化日期: 刚刚/几分钟前/几小时前/昨天/前天/MM-DD/YYYY-MM-DD
///
/// [isIM] 是否是IM日期: 今天/昨天/MM-DD/YYYY-MM-DD
///
/// 比较当前日期与目标日期date是不是在同一年
/// 如果在同一年,则只输入出年月如:02-21
/// 如果不再同一年,则输出年月日,如2024-02-21
String formatDate(
  dynamic date, {
  bool showTime = false,
  bool ymd = false,
  bool semantic = false,
  bool isIM = false,
}) {
  try {
    DateTime dateTime;
    if (date == null) {
      return '';
    }

    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is int) {
      if (date.toString().length == 10) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date * 1000);
      } else if (date.toString().length == 13) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return _handleError(() => FormatException('无效的时间戳格式'));
      }
    } else {
      return _handleError(() => ArgumentError('date参数必须是字符串或时间戳'));
    }

    if (ymd) {
      return '${_padLeft(dateTime.year)}-${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}${showTime ? ' ${_padLeft(dateTime.hour)}:${_padLeft(dateTime.minute)}' : ''}';
    }

    final DateTime now = DateTime.now();

    if (isIM) {
      // 今天
      if (DateUtils.isSameDay(now, dateTime)) {
        return _formatHm(dateTime);
      }

      // 昨天
      if (DateUtils.isSameDay(
        dateTime,
        now.subtract(const Duration(days: 1)),
      )) {
        return '昨天 ${_formatHm(dateTime)}';
      }

      // 同年内格式：MM-DD
      if (dateTime.year == now.year) {
        return '${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}';
      }

      // 跨年格式：YYYY-MM-DD
      return '${dateTime.year}-${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}';
    }

    if (semantic) {
      final diff = now.difference(dateTime);

      // 今天
      if (DateUtils.isSameDay(now, dateTime)) {
        if (diff.inHours >= 1) {
          return '${diff.inHours}小时前';
        }
        if (diff.inMinutes >= 1) {
          return '${diff.inMinutes}分钟前';
        }
        return '刚刚';
      }

      // 昨天
      if (DateUtils.isSameDay(
        dateTime,
        now.subtract(const Duration(days: 1)),
      )) {
        return '昨天 ${_formatHm(dateTime)}';
      }

      // 前天
      if (DateUtils.isSameDay(
        dateTime,
        now.subtract(const Duration(days: 2)),
      )) {
        return '前天 ${_formatHm(dateTime)}';
      }

      // 同年内格式：MM-DD
      if (dateTime.year == now.year) {
        return '${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}';
      }

      // 跨年格式：YYYY-MM-DD
      return '${dateTime.year}-${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}';
    }

    // 比较年份
    if (dateTime.year == now.year) {
      // 同一年，只返回月-日
      return '${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}${showTime ? ' ${_padLeft(dateTime.hour)}:${_padLeft(dateTime.minute)}' : ''}';
    }
    // 不同年，返回年-月-日
    return '${_padLeft(dateTime.year)}-${_padLeft(dateTime.month)}-${_padLeft(dateTime.day)}${showTime ? ' ${_padLeft(dateTime.hour)}:${_padLeft(dateTime.minute)}' : ''}';
  } catch (e) {
    if (kReleaseMode) {
      return '';
    } else {
      rethrow;
    }
  }
}

String _formatHm(DateTime dt) => '${_padLeft(dt.hour)}:${_padLeft(dt.minute)}';

String _padLeft(int value) {
  return value.toString().padLeft(2, '0');
}

/// 处理错误的私有方法
String _handleError(Function() errorFactory) {
  if (kReleaseMode) {
    return '';
  } else {
    throw errorFactory();
  }
}
