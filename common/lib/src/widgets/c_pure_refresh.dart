import 'package:common/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class CPureRefresh extends StatefulWidget {
  const CPureRefresh({
    required this.child,
    this.fetchData,
    this.enablePullDown = true,
    this.onRefresh,
    this.id,
    this.scrollController,
    this.pageSize = 20,
    this.fetchListData,
    this.hasMore,
    super.key,
  }) : assert(
         fetchData != null || fetchListData != null,
         'fetchData or fetchListData must be provided',
       ),
       assert(
         fetchListData == null || hasMore != null,
         'hasMore must be provided when fetchListData is provided',
       );

  /// 唯一标识
  final String? id;

  final Widget child;

  /// 是否启用下拉刷新, 默认为true
  final bool enablePullDown;

  /// 是否还有更多
  final bool Function()? hasMore;

  /// 下拉刷新回调
  final VoidCallback? onRefresh;

  /// 加载数据, 非分页数据
  final AsyncFunc<void>? fetchData;

  /// 分页数据, 主要是处理data不是数组,并且也不是标准分页数据的情况
  ///
  /// 如: 分页的数据是在data.records里
  ///
  /// 对于标准分页数据, 要使用 [CPaginatedController]
  final Function(int page, int size)? fetchListData;

  /// 每页数据大小, 默认为20条
  final int pageSize;

  final ScrollController? scrollController;

  @override
  State<CPureRefresh> createState() => _CPureRefreshState();
}

class _CPureRefreshState extends State<CPureRefresh> {
  /// 当前页码
  int _pageNo = 1;

  /// 刷新控制器
  late RefreshController _refreshController;

  /// 是否正在加载
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRefresh();

      if (widget.id != null) {
        CGlobalPaginatedRefresher.register(widget.id!, _onRefresh);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      scrollController: widget.scrollController,
      controller: _refreshController,
      enablePullDown: widget.enablePullDown,
      enablePullUp: widget.fetchListData != null,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: widget.child,
    );
  }

  void _onLoading() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    if (widget.hasMore?.call() ?? false) {
      try {
        await widget.fetchListData?.call(_pageNo, widget.pageSize);
        _pageNo += 1;

        if (widget.hasMore?.call() == false) {
          _refreshController.loadNoData();
        } else {
          _refreshController.loadComplete();
        }
      } catch (e) {
        _refreshController.loadFailed();
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRefresh() async {
    if (_isLoading) {
      return;
    }

    widget.onRefresh?.call();

    setState(() => _isLoading = true);

    try {
      if (widget.fetchData != null) {
        await widget.fetchData!();
      } else {
        _pageNo = 1;
        await widget.fetchListData!(_pageNo, widget.pageSize);
        _pageNo += 1;

        if (widget.hasMore?.call() == false) {
          _refreshController.loadNoData();
        }
      }
      _refreshController.refreshCompleted();
      setState(() => _isLoading = false);
    } catch (error) {
      if (kDebugMode) {
        showToast(error.toString());
      }
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();

    if (widget.id != null) {
      CGlobalPaginatedRefresher.unregister(widget.id!);
    }

    debugPrint('CPureRefresh dispose ✌️✌️✌️');

    super.dispose();
  }
}
