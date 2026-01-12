import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'common_model.dart';

class TabDataState {
  /// 图片列表
  RxList<CommonItemModel> dataList = <CommonItemModel>[].obs;

  /// 当前页码
  int currentPage = 1;

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 是否还有更多数据
  final RxBool hasMore = true.obs;

  final GlobalKey refresherKey = GlobalKey();

  /// 刷新控制器（每个 tab 独立管理）
  final RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

  /// 是否已初始化（用于懒加载）
  bool isInitialized = false;

  /// 释放资源
  void dispose() {
    refreshController.dispose();
  }
}
