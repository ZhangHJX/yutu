import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef CPaginationBuilder<T> =
    Widget Function(
      BuildContext context,
      CPaginationState<T> state,
      RefreshController refreshController,
    );

typedef FetchFunc<T, R> = R Function(int page, int size);

class CPaginationState<T> {
  const CPaginationState({
    required this.pageNo,
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.isFirstLoading,
  });

  final int pageNo;

  final List<T> items;

  final bool hasMore;

  final bool isLoading;

  final bool isFirstLoading;

  bool get isEmpty => items.isEmpty && !isFirstLoading;

  CPaginationState<T> copyWith({
    int? pageNo,
    List<T>? items,
    bool? hasMore,
    bool? isLoading,
    bool? isFirstLoading,
  }) {
    return CPaginationState<T>(
      pageNo: pageNo ?? this.pageNo,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isFirstLoading: isFirstLoading ?? this.isFirstLoading,
    );
  }
}

class CPaginatedController<T> extends StatefulWidget {
  /// [headerBuilder] 可选，用于构建公共的头部的UI
  const CPaginatedController({
    required this.builder,
    this.fetchData,
    this.fetchListData,
    super.key,
    this.pageSize = 20,
    this.emptyBuilder,
    this.emptyText,
    this.emptyImgPath,
    this.loadingBuilder,
    this.scrollController,
    this.queryParams,
    this.onRefresh,
    this.onLoad,
    this.enablePullUp = true,
    this.enablePullDown = true,
    this.onDataLoaded,
    this.autoRefresh = true,
    this.loadAtFirst = true,
    this.disablePullUpWhenEmpty = false,
    this.isManual = false,
    this.headerBuilder,
    this.onDataLoadedWithPageNo,
  }) : assert(
         fetchData != null || fetchListData != null,
         'fetchData or fetchListData must be provided',
       );

  /// 是否是手动管理数据, 调用者要自己管理数据, 包括刷新和下拉加载更多, 一般是在月份筛选的地方使用
  final bool isManual;

  final bool loadAtFirst;

  final FetchFunc<T, FutureListModel<T>>? fetchData;

  final FetchFunc<T, FuturePureListModel<T>>? fetchListData;

  final CPaginationBuilder<T> builder;

  /// 空视图构建器
  final WidgetBuilder? emptyBuilder;

  /// 空视图文本
  final String? emptyText;

  /// 空视图图片路径
  final String? emptyImgPath;

  /// 加载中视图构建器
  final WidgetBuilder? loadingBuilder;

  /// 公共的header构建器, 当页面列表有数据或没有数据都拥有的部分
  final WidgetBuilder? headerBuilder;

  /// 每页数据大小, 默认为20条
  final int pageSize;

  /// 自定义滚动控制器
  final ScrollController? scrollController;

  /// 查询参数，当参数变化时会触发刷新
  final Map<String, dynamic>? queryParams;

  /// 下拉刷新触发调用
  final VoidCallback? onRefresh;

  /// 加载更多回调
  final VoidCallback? onLoad;

  /// 数据加载完成的回调
  final void Function(List<T> items)? onDataLoaded;
  final void Function(List<T> items, int pageNo)? onDataLoadedWithPageNo;

  /// 是否启用上拉加载更多
  final bool enablePullUp;

  /// 当列表为空时, 是否禁用上拉加载更多
  final bool disablePullUpWhenEmpty;

  /// 是否启用下拉刷新
  final bool enablePullDown;

  /// 当queryParams变化时是否自动刷新数据
  final bool autoRefresh;

  @override
  State<CPaginatedController<T>> createState() => _CPaginatedControllerState<T>();
}

/// 分页控制器状态
class _CPaginatedControllerState<T> extends State<CPaginatedController<T>> {
  int _pageNo = 1;

  List<T> _list = [];

  bool _hasMore = true;

  late RefreshController _refreshController;

  Map<String, dynamic>? _queryParams;

  bool _isLoading = false;

  bool _isFirstLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _queryParams = widget.queryParams;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.loadAtFirst) {
        refreshData();
      }
    });
  }

  @override
  void didUpdateWidget(CPaginatedController<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 基于内容的比较是否相等，且只有在autoRefresh为true时才刷新
    if (widget.autoRefresh && !mapEquals(widget.queryParams, _queryParams)) {
      _queryParams = widget.queryParams;
      refreshData();
    } else if (!mapEquals(widget.queryParams, _queryParams)) {
      // 如果autoRefresh为false，仍然更新_queryParams但不刷新
      _queryParams = widget.queryParams;
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 刷新数据（重置到第一页）
  ///
  /// 可以从外部通过GlobalKey调用此方法手动刷新
  Future<void> refreshData() async {
    _refreshController.resetNoData();
    widget.onRefresh?.call();
    await _fetchData(isRefresh: true);
  }

  /// 加载更多数据
  Future<void> loadMoreData() async {
    if (_hasMore && !_isLoading) {
      await _fetchData(specificPage: _pageNo + 1);
      widget.onLoad?.call();
    } else if (!_hasMore) {
      _refreshController.loadNoData();
    }
  }

  /// 内部加载数据方法
  Future<void> _fetchData({bool isRefresh = false, int? specificPage}) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final targetPage = specificPage ?? (isRefresh ? 1 : _pageNo);

      if (isRefresh) {
        _pageNo = 1;
      }

      if (widget.fetchData != null) {
        final result = await widget.fetchData!.call(targetPage, widget.pageSize);
        // final result = await performWithLoading(
        //   '',
        //   () => widget.fetchData!.call(targetPage, widget.pageSize),
        // );

        if (result.data != null) {
          final serverPageModel = result.data!;
          final newItems = serverPageModel.list;

          setState(() {
            if (isRefresh) {
              _list = newItems ?? [];
            } else {
              _list = [..._list, ...(newItems ?? [])];
              // 请求成功后才更新页码
              if (specificPage != null && specificPage > _pageNo) {
                _pageNo = specificPage;
              } else if (!isRefresh) {
                // 常规加载更多
                _pageNo += 1;
              }
            }

            _hasMore = !serverPageModel.isLastPage;
            _isFirstLoading = false;
          });

          // 调用数据加载完成回调
          widget.onDataLoaded?.call(_list);
          widget.onDataLoadedWithPageNo?.call(_list, _pageNo);
        }
      } else {
        final result = await widget.fetchListData!.call(targetPage, widget.pageSize);
        // final result = await performWithLoading(
        //   '',
        //   () => widget.fetchListData!.call(targetPage, widget.pageSize),
        // );

        if (result.data != null) {
          final newItems = result.data!;

          setState(() {
            if (isRefresh) {
              _list = newItems;
            } else {
              _list = [..._list, ...newItems];
              // 请求成功后才更新页码
              if (specificPage != null && specificPage > _pageNo) {
                _pageNo = specificPage;
              } else if (!isRefresh) {
                // 常规加载更多
                _pageNo += 1;
              }
            }

            if (!widget.isManual) {
              _hasMore = newItems.length >= widget.pageSize;
            }
            _isFirstLoading = false;
          });

          // 调用数据加载完成回调
          if (widget.isManual) {
            // 回调当次的数据
            widget.onDataLoaded?.call(newItems);
            widget.onDataLoadedWithPageNo?.call(newItems, _pageNo);
          } else {
            // 回调所有数据
            widget.onDataLoaded?.call(_list);
            widget.onDataLoadedWithPageNo?.call(_list, _pageNo);
          }
        }
      }

      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }

      if (isRefresh) {
        _refreshController.refreshCompleted();
        if (!_hasMore) {
          _refreshController.loadNoData();
        }
      } else {
        if (!widget.isManual) {
          if (_hasMore) {
            _refreshController.loadComplete();
          } else {
            _refreshController.loadNoData();
          }
        }
      }
    } catch (error) {
      debugPrint('😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡糟糕, CPaginatedController出错了: $error');
      if (kDebugMode) {
        showToast(error.toString());
      }
      if (isRefresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 下拉刷新处理
  void _onRefresh() {
    // _isFirstLoading = true;
    refreshData();
  }

  /// 上拉加载更多处理
  void _onLoading() {
    loadMoreData();
  }

  @override
  Widget build(BuildContext context) {
    // 构建当前分页状态
    final state = CPaginationState<T>(
      pageNo: _pageNo,
      items: _list,
      hasMore: _hasMore,
      isLoading: _isLoading,
      isFirstLoading: _isFirstLoading && _isLoading,
    );

    if (state.isFirstLoading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    Widget child;

    if (state.isEmpty) {
      final emptyWidget =
          widget.emptyBuilder?.call(context) ??
          CEmpty(text: widget.emptyText, imgPath: widget.emptyImgPath);
      child = _buildWithHeader(context, emptyWidget, isEmptyState: true);
    } else {
      final contentWidget = widget.builder(context, state, _refreshController);
      child = _buildWithHeader(context, contentWidget, isEmptyState: false);
    }

    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: widget.enablePullUp && !(widget.disablePullUpWhenEmpty && state.isEmpty),
      enablePullDown: widget.enablePullDown,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      child: child,
    );
  }

  /// 构建带header的布局
  Widget _buildWithHeader(
    BuildContext context,
    Widget contentWidget, {
    required bool isEmptyState,
  }) {
    if (widget.headerBuilder == null) {
      return contentWidget;
    }

    final header = widget.headerBuilder!.call(context);
    final isHeaderSliver = _isSliver(header);
    final isContentCustomScrollView = contentWidget is CustomScrollView;

    // 空状态处理
    if (isEmptyState) {
      if (isHeaderSliver) {
        return CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            header,
            SliverFillRemaining(hasScrollBody: false, child: contentWidget),
          ],
        );
      } else {
        return Column(
          children: [
            header,
            Expanded(child: contentWidget),
          ],
        );
      }
    }

    // 有数据状态处理
    if (isContentCustomScrollView) {
      final headerSliver = isHeaderSliver ? header : SliverToBoxAdapter(child: header);
      return CustomScrollView(
        controller: widget.scrollController,
        slivers: [headerSliver, ...contentWidget.slivers],
      );
    } else if (_isSliver(contentWidget)) {
      final headerSliver = isHeaderSliver ? header : SliverToBoxAdapter(child: header);
      return CustomScrollView(
        controller: widget.scrollController,
        slivers: [headerSliver, contentWidget],
      );
    } else {
      return Column(
        children: [
          header,
          Expanded(child: contentWidget),
        ],
      );
    }
  }

  /// 安全地检测widget是否为Sliver类型
  bool _isSliver(Widget widget) {
    return widget is SliverList ||
        widget is SliverGrid ||
        widget is SliverFixedExtentList ||
        widget is SliverPrototypeExtentList ||
        widget is SliverFillViewport ||
        widget is SliverAnimatedList ||
        widget is SliverAnimatedGrid ||
        widget is SliverFillRemaining ||
        widget is SliverPersistentHeader ||
        widget is SliverAppBar ||
        widget is SliverPadding ||
        widget is SliverToBoxAdapter ||
        widget is SliverIgnorePointer ||
        widget is SliverOffstage ||
        widget is SliverOpacity ||
        widget is SliverLayoutBuilder ||
        widget is SliverSafeArea ||
        widget is SliverVisibility;
  }
}

/// 全局分页刷新器
///
/// 提供了一种通过ID刷新任何位置的分页列表的方法
class CGlobalPaginatedRefresher {
  static final Map<String, VoidCallback> _refreshCallbacks = {};

  /// 刷新所有列表
  static void refreshAll() {
    _refreshCallbacks.forEach((key, value) {
      value();
    });
  }

  /// 注册刷新回调
  static void register(String id, VoidCallback callback) {
    _refreshCallbacks[id] = callback;
  }

  /// 注销刷新回调
  static void unregister(String id) {
    _refreshCallbacks.remove(id);
  }

  /// 刷新指定ID的列表
  static void refresh(String id) {
    final callback = _refreshCallbacks[id];
    if (callback != null) {
      callback();
    } else {
      debugPrint('🥵 未找到ID为"$id"的分页列表，请确认ID是否正确');
    }
  }
}

class CIdentifiablePaginatedController<T> extends StatefulWidget {
  const CIdentifiablePaginatedController({
    required this.id,
    required this.builder,
    this.fetchData,
    this.fetchListData,
    super.key,
    this.emptyBuilder,
    this.emptyText,
    this.emptyImgPath,
    this.loadingBuilder,
    this.pageSize = 20,
    this.scrollController,
    this.queryParams,
    this.onRefresh,
    this.onLoad,
    this.enablePullUp = true,
    this.enablePullDown = true,
    this.onDataLoaded,
    this.autoRefresh = true,
    this.loadAtFirst = true,
    this.disablePullUpWhenEmpty = false,
    this.isManual = false,
    this.headerBuilder,
    this.onDataLoadedWithPageNo,
  });

  /// 是否是手动管理数据, 调用者要自己管理数据, 包括刷新和下拉加载更多, 一般是在月份筛选的地方使用
  final bool isManual;

  final bool loadAtFirst;

  /// 空视图文本
  final String? emptyText;

  /// 空视图图片路径
  final String? emptyImgPath;

  /// 唯一标识符，用于全局刷新
  final String id;

  /// 加载数据的函数
  final FetchFunc<T, FutureListModel<T>>? fetchData;

  final FetchFunc<T, FuturePureListModel<T>>? fetchListData;

  /// 内容构建器
  final CPaginationBuilder<T> builder;

  /// 空视图构建器
  final WidgetBuilder? emptyBuilder;

  /// 加载中视图构建器
  final WidgetBuilder? loadingBuilder;

  /// 公共的header构建器, 当页面列表有数据或没有数据都拥有的部分
  final WidgetBuilder? headerBuilder;

  /// 每页数据大小, 默认为20条
  final int pageSize;

  /// 自定义滚动控制器
  final ScrollController? scrollController;

  /// 查询参数
  final Map<String, dynamic>? queryParams;

  /// 刷新回调
  final VoidCallback? onRefresh;

  /// 加载更多回调
  final VoidCallback? onLoad;

  /// 数据加载完成的回调
  final void Function(List<T> items)? onDataLoaded;
  final void Function(List<T> items, int pageNo)? onDataLoadedWithPageNo;

  /// 当列表为空时, 是否禁用上拉加载更多
  final bool disablePullUpWhenEmpty;

  /// 是否启用上拉加载更多
  final bool enablePullUp;

  /// 是否启用下拉刷新
  final bool enablePullDown;

  /// 当queryParams变化时是否自动刷新数据
  final bool autoRefresh;

  @override
  State<CIdentifiablePaginatedController<T>> createState() =>
      _CIdentifiablePaginatedControllerState<T>();
}

class _CIdentifiablePaginatedControllerState<T> extends State<CIdentifiablePaginatedController<T>> {
  final GlobalKey<_CPaginatedControllerState<T>> _key = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CGlobalPaginatedRefresher.register(widget.id, _refresh);
    });
  }

  @override
  void dispose() {
    CGlobalPaginatedRefresher.unregister(widget.id);
    super.dispose();
  }

  void _refresh() {
    _key.currentState?.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return CPaginatedController<T>(
      key: _key,
      isManual: widget.isManual,
      fetchData: widget.fetchData,
      fetchListData: widget.fetchListData,
      builder: widget.builder,
      emptyBuilder: widget.emptyBuilder,
      emptyText: widget.emptyText,
      emptyImgPath: widget.emptyImgPath,
      loadingBuilder: widget.loadingBuilder,
      headerBuilder: widget.headerBuilder,
      pageSize: widget.pageSize,
      scrollController: widget.scrollController,
      queryParams: widget.queryParams,
      onRefresh: widget.onRefresh,
      onLoad: widget.onLoad,
      enablePullUp: widget.enablePullUp,
      enablePullDown: widget.enablePullDown,
      onDataLoaded: widget.onDataLoaded,
      autoRefresh: widget.autoRefresh,
      loadAtFirst: widget.loadAtFirst,
      disablePullUpWhenEmpty: widget.disablePullUpWhenEmpty,
      onDataLoadedWithPageNo: widget.onDataLoadedWithPageNo,
    );
  }
}
