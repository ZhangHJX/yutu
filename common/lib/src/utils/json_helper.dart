import 'dart:convert';

/// JSON辅助工具类，提供通用的JSON操作方法
class JsonHelper {
  /// 将JSON字符串解析为Map
  static Map<String, dynamic> parseJson(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// 将JSON字符串解析为List
  static List<dynamic> parseJsonList(String jsonString) {
    return json.decode(jsonString) as List<dynamic>;
  }

  /// 将对象转换为JSON字符串
  static String toJsonString(dynamic object) {
    return json.encode(object);
  }

  /// 将Map类型转换为指定模型类型
  static T fromMap<T>(Map<String, dynamic> map, T Function(Map<String, dynamic>) fromJson) {
    return fromJson(map);
  }

  /// 将List类型转换为指定模型类型的List
  static List<T> fromMapList<T>(List<dynamic>? list, T Function(Map<String, dynamic>) fromJson) {
    if (list == null) {
      return [];
    }
    return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  /// 将JSON字符串转换为指定模型类型
  static T fromJsonString<T>(String jsonString, T Function(Map<String, dynamic>) fromJson) {
    final Map<String, dynamic> map = parseJson(jsonString);
    return fromJson(map);
  }

  /// 将JSON字符串转换为指定模型类型的List
  static List<T> fromJsonStringList<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = parseJsonList(jsonString);
    return fromMapList(list, fromJson);
  }
}
