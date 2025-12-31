import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../widgets/index.dart';
import '../canvas/draft/index.dart';
import '../../app/routes/index.dart';
import '../canvas/fonts/font_manager.dart';
import 'package:voicetemplate/ui/utils/file/index.dart';
import '../model/index.dart';
//最新的数据
import './model/home_model.dart';

class HomeLogic extends GetxController with GetTickerProviderStateMixin {
  /// 推荐列表（响应式）
  final recommendList = <CommonItemModel>[].obs;

  /// Tag列表（响应式）
  final tagList = <TagModel>[].obs;

  // 每个 tab 的数据状态（使用 tagId 作为 key，0 表示全部）
  final RxMap<int, TabDataState> tabDataMap = <int, TabDataState>{}.obs;

  // Tab 索引
  final selectedTabIndex = 0.obs;

  /// 获取当前 tab 是否还有更多数据
  RxBool get hasMore {
    final tagId = _getCurrentTagId();
    return tabDataMap[tagId]?.hasMore ?? true.obs;
  }

  @override
  void onReady() {
    FontManager.to.initFromDisk();
    PickerImageManager.init();
    super.onReady();
  }

  @override
  void onClose() {
    // 释放所有 tab 的 RefreshController
    for (var tabData in tabDataMap.values) {
      tabData.refreshController.dispose();
    }
    tabDataMap.clear();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    homeRefresh();
    // showDraftDialog();
  }

  /// 加载首页数据
  Future<void> homeRefresh() async {
    await loadHomeData(refresh: true);
  }

  Future<void> loadHomeData({bool refresh = false}) async {
    try {
      final result = await http.get(
        '/homePage/index',
        converter: HomeModel.fromJson,
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        // 释放旧的 RefreshController 后再清除
        for (var tabData in tabDataMap.values) {
          tabData.refreshController.dispose();
        }
        tabDataMap.clear();

        recommendList.value = result.data!.recommendList;
        tagList.value = result.data!.tagList;

        // 初始化每个 tag 的数据到 tabDataMap
        for (var index = 0; index < tagList.length; index++) {
          final tag = tagList[index];
          final tabData = _getOrCreateTabData(tag.id);
          if (tag.list.isNotEmpty) {
            // 如果 tag 的 list 不为空，初始化数据
            selectedTabIndex.value = index;
            tabData.dataList.value = tag.list;
            tabData.isInitialized = true;
            tabData.currentPage = 1;
            tabData.hasMore.value = true;
          }
        }
      }
    } catch (e) {
      debugPrint('获取首页数据失败: $e');
    }
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadSceneList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad({int? tagId}) async {
    await loadSceneList(refresh: false);
  }

  /// 获取当前 tab 的 tagId
  int _getCurrentTagId() {
    if (tagList.isEmpty || selectedTabIndex.value >= tagList.length) {
      return 0;
    }
    return tagList[selectedTabIndex.value].id;
  }

  /// 获取或创建 tab 数据状态
  TabDataState _getOrCreateTabData(int tagId) {
    if (!tabDataMap.containsKey(tagId)) {
      tabDataMap[tagId] = TabDataState();
    }
    return tabDataMap[tagId]!;
  }

  /// 加载图片列表
  Future<void> loadSceneList({bool refresh = false}) async {
    // 确定要加载的 tagId
    final targetTagId = _getCurrentTagId();
    final tabData = _getOrCreateTabData(targetTagId);
    if (tabData.isLoading.value) {
      return;
    }
    if (refresh) {
      tabData.currentPage = 1;
    }
    tabData.isLoading.value = true;
    try {
      final result = await http.get(
        '/homePage/tag-index',
        query: {
          'page': '${tabData.currentPage}',
          'limit': globalPageSize,
          'tag_id': targetTagId,
        },
        showErrorToast: false,
      );
      if (result.code == 0 && result.data != null) {
        final listModel = CommonModel.fromJson(result.data);
        // 更新当前 tag 的数据列表（响应式）
        if (tabData.currentPage == 1) {
          tabData.dataList.clear();
        }

        // 追加到列表数据后面
        if (listModel.items.isNotEmpty) {
          tabData.dataList.addAll(listModel.items);
          tabData.currentPage++;
          tabData.hasMore.value = true;
        } else {
          tabData.hasMore.value = false;
        }
        tabData.isInitialized = true;
      }
      // 更新刷新控制器状态 - 使用当前 tab 的 refreshController
      if (refresh) {
        tabData.refreshController.refreshCompleted();
      } else {
        if (hasMore.value) {
          tabData.refreshController.loadComplete();
        } else {
          tabData.refreshController.loadNoData();
        }
      }
      tabData.isLoading.value = false;
    } catch (e) {
      tabData.isLoading.value = false;
      debugPrint('列表数据请求错误: $e');
      // 处理错误状态 - 使用当前 tab 的 refreshController
      if (refresh) {
        tabData.refreshController.refreshFailed();
      } else {
        tabData.refreshController.loadFailed();
      }
    }
  }

  // 切换 tab
  void switchTab(int index) {
    if (index < 0 || tagList.isEmpty || index >= tagList.length) {
      return;
    }
    if (selectedTabIndex.value == index) return;
    // 更新选中索引
    selectedTabIndex.value = index;

    // 切换 tab 时，如果该 tab 未初始化，则加载数据
    final tagId = _getCurrentTagId();
    final tabData = _getOrCreateTabData(tagId);
    if (!tabData.isInitialized) {
      loadSceneList(refresh: true);
    }
  }

  void showDraftDialog() async {
    final isHave = await DraftManager().hasDraft();
    if (isHave) {
      SmartDialog.show(
        builder: (context) => ConfirmPopWidget(
          title: "继续编辑",
          subTitle: "您上次编辑的草稿未正常保存，是\n否返回编辑器继续编辑？",
          cancelAction: () {
            DraftManager().deleteDraft();
          },
          sureAction: () {
            // 异步加载草稿并跳转到画布页面
            () async {
              final draft = await DraftManager().loadDraft();
              if (draft == null) {
                SmartDialog.dismiss();
                return;
              }

              // 根据当前屏幕重新计算画布矩阵
              draft.getMatrix4();

              SmartDialog.dismiss();
              Get.toNamed(AppRoutes.canvalsPage, arguments: draft);
            }();
          },
        ),
        alignment: Alignment.center,
        animationType: SmartAnimationType.centerFade_otherSlide,
        animationTime: Duration(milliseconds: 250),
        maskColor: "#000000".color.withValues(alpha: 0.5),
        clickMaskDismiss: true,
        useAnimation: true,
        usePenetrate: false,
      );
    }
  }
}
