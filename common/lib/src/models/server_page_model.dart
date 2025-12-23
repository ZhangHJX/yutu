


class ServerPageModel<T> {
  ServerPageModel({
    /// 数据列表
    required this.list,
    required this.page,
    required this.pageSize,
  });

  factory ServerPageModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ServerPageModel<T>(
      list: (json['list'] as List<dynamic>).map(fromJsonT).toList(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
    );
  }

  final List<T> list;
  final int page;
  final int pageSize;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return <String, dynamic>{
      'list': list.map(toJsonT).toList(),
      'page': page,
      'pageSize': pageSize,
    };
  }
}
