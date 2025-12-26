/// 分页数据模型
class ServerPageModel<T> {
  ServerPageModel({
    /// 数据总数
    required this.total,

    /// 数据列表
    required this.list,
    required this.pageNum,
    required this.pageSize,
    required this.isFirstPage,

    /// 是否最后一页
    required this.isLastPage,
  });

  factory ServerPageModel.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    return ServerPageModel<T>(
      total: (json['total'] as num).toInt(),
      list: (json['list'] as List<dynamic>?)?.map(fromJsonT).toList(),
      pageNum: (json['pageNum'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      isFirstPage: json['isFirstPage'] as bool,
      isLastPage: json['isLastPage'] as bool,
    );
  }

  final int total;
  final List<T>? list;
  final int pageNum;
  final int pageSize;
  final bool isFirstPage;
  final bool isLastPage;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return <String, dynamic>{
      'total': total,
      'list': list?.map(toJsonT).toList(),
      'pageNum': pageNum,
      'pageSize': pageSize,
      'isFirstPage': isFirstPage,
      'isLastPage': isLastPage,
    };
  }
}
