import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../stores/global.dart';
import '../canvas/draft/index.dart';
import '../canvas/fonts/font_manager.dart';
import '../canvas/model/index.dart';
import 'package:voicetemplate/pages/utils/file/index.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import '../model/index.dart';

import 'package:voicetemplate/core/index.dart';

//最新的数据
import 'model/home_model.dart';
import 'draft/draft_edit_model.dart';
import 'draft/draft_continue_edit_widget.dart';
import 'draft/draft_download_service.dart';

class HomeLogic extends GetxController with GetTickerProviderStateMixin {
  final global = Get.find<GlobalLogic>();

  /// 推荐列表（响应式）
  final recommendList = <CommonItemModel>[].obs;

  /// Tag列表（响应式）
  final tagList = <TagModel>[].obs;

  /// 是否显示顶部导航中的 Tab（用于与中间 Tab 联动）
  final RxBool showTopTab = false.obs;

  final tabList = <CommonItemModel>[].obs;

  // Tab 索引
  final selectedTabIndex = 0.obs;

  /// TabController
  final Rxn<TabController> tabController = Rxn<TabController>();

  /// 草稿选择
  final isLocal = true.obs;

  GlobalKey refresherKey = GlobalKey();
  RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

  /// 滚动控制器，用于监听滚动位置
  final ScrollController scrollController = ScrollController();

  /// 获取当前 tab 的 tagId
  int _getCurrentTagId() {
    if (tagList.isEmpty || selectedTabIndex.value >= tagList.length) {
      return 0;
    }
    return tagList[selectedTabIndex.value].id;
  }

  Worker? _countWorker;

  /// 当前页码
  int currentPage = 1;

  /// 是否正在加载/更多数据
  bool isLoading = false;
  bool hasMore = true;

  @override
  void onReady() {
    FontManager.to.initFromDisk();
    PickerImageManager.init();
    super.onReady();
  }

  @override
  void onClose() {
    // HomeTabDataState 没有 refreshController，不需要释放
    // tabDataMap.clear();
    // 释放 TabController
    tabController.value?.dispose();
    tabController.value = null;
    // 释放 ScrollController
    scrollController.dispose();
    _countWorker?.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    homeRefresh();

    /// 登录事件监听
    _countWorker = ever(global.accessToken, (token) {
      homeRefresh();
      showDraftDialog();
    });
    // 监听网络状态变化
    global.connectStatus.onStatusChanged.listen((status) {
      if (status != NetworkStatus.none) {
        homeRefresh();
        showDraftDialog();
      }
    });

    // 监听滚动位置，用于控制顶部 Tab 的显示
    scrollController.addListener(_onScroll);
  }

  /// 滚动监听回调
  void _onScroll() {
    // 计算推荐区域的大概高度：推荐标题高度42.w + 列表高度(201.w)
    final recommendationHeight = 42.w + 201.w;
    // 当滚动偏移超过推荐区域高度时，说明中间 Tab 已经滑到搜索框边缘
    final shouldShowTopTab = scrollController.offset >= recommendationHeight;
    if (showTopTab.value != shouldShowTopTab) {
      showTopTab.value = shouldShowTopTab;
    }
  }

  /// 加载首页数据
  Future<void> homeRefresh() async {
    await loadHomeData(refresh: true);
  }

  Future<void> loadHomeData({bool refresh = false}) async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    try {
      final result = await http.get(
        '/homePage/index',
        converter: HomeModel.fromJson,
      );
      if (result.code == 0 && result.data != null) {
        // HomeTabDataState 没有 refreshController，直接清除
        tabList.clear();

        currentPage = 1;

        recommendList.value = result.data!.recommendList;
        tagList.value = result.data!.tagList;

        // 初始化每个 tag 的数据到 tabDataMap
        final index = tagList.indexWhere((e) => e.isSelect == 1);
        final tabData = index == -1 ? null : tagList[index];
        if (tabData != null && tabData.list.isNotEmpty) {
          selectedTabIndex.value = index;
          tabList.value = tabData.list;
          hasMore = true;
        } else {
          hasMore = false;
        }
        // 创建或更新 TabController
        _createOrUpdateTabController();
      }
      isLoading = false;
      if (refresh) {
        refreshController.resetNoData();
        refreshController.refreshCompleted();
      } else {
        if (hasMore) {
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }
    } catch (e) {
      isLoading = false;
      if (refresh) {
        refreshController.refreshCompleted();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  /// 创建或更新 TabController
  void _createOrUpdateTabController() {
    if (tagList.isEmpty) {
      tabController.value?.dispose();
      tabController.value = null;
      return;
    }

    final newLength = tagList.length;

    // 如果 TabController 已存在且长度相同，只需要同步索引
    if (tabController.value != null &&
        tabController.value!.length == newLength) {
      if (tabController.value!.index != selectedTabIndex.value) {
        tabController.value!.index = selectedTabIndex.value;
      }
      return;
    }

    // 释放旧的 TabController
    tabController.value?.dispose();

    // 创建新的 TabController
    final newController = TabController(
      length: newLength,
      vsync: this,
      initialIndex: selectedTabIndex.value.clamp(0, newLength - 1),
    );

    tabController.value = newController;
  }

  // 切换 tab
  void switchTab(int index) {
    if (index < 0 || tagList.isEmpty || index >= tagList.length) {
      return;
    }
    if (selectedTabIndex.value == index) return;

    // 先调用 animateTo 来滚动和动画
    if (tabController.value != null) {
      tabController.value!.animateTo(index);
    }
    // 更新选中索引
    selectedTabIndex.value = index;
    loadSceneList(refresh: true);
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    await loadSceneList(refresh: true);
  }

  /// 上拉加载更多
  Future<void> onLoad({int? tagId}) async {
    await loadSceneList(refresh: false);
  }

  /// 加载图片列表
  Future<void> loadSceneList({bool refresh = false}) async {
    // 确定要加载的 tagId
    final targetTagId = _getCurrentTagId();
    if (refresh) {
      currentPage = 1;
    }
    if (isLoading) {
      return;
    }
    isLoading = true;
    try {
      final result = await http.get(
        '/homePage/tag-index',
        query: {
          'page': '$currentPage',
          'limit': globalPageSize,
          'tag_id': targetTagId,
        },
      );
      if (result.code == 0 && result.data != null) {
        final listModel = CommonModel.fromJson(result.data);
        if (currentPage == 1) {
          tabList.clear();
        }
        // 追加到列表数据后面
        if (listModel.items.isNotEmpty) {
          tabList.addAll(listModel.items);
          currentPage++;
          hasMore = true;
        } else {
          hasMore = false;
        }
      }
      isLoading = false;
      // 更新刷新控制器状态 - 使用全局的 refreshController
      if (refresh) {
        refreshController.resetNoData();
        refreshController.refreshCompleted();
      } else {
        if (hasMore) {
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }
      isLoading = false;
    } catch (e) {
      isLoading = false;
      debugPrint('列表数据请求错误: $e');
      // 处理错误状态 - 使用全局的 refreshController
      if (refresh) {
        refreshController.refreshCompleted();
      } else {
        refreshController.loadComplete();
      }
    }
  }

  /// 收藏事件处理
  Future<void> clickFavorite(int itemId, bool shouldFavorite) async {
    if (global.connectStatus.currentStatus == NetworkStatus.none) {
      showToast(shouldFavorite ? "收藏失败" : "取消收藏失败");
      return;
    }
    try {
      final result = await http.post(
        shouldFavorite
            ? '/homePage/favorite-store'
            : '/homePage/favorite-destroy',
        data: {"link_id": '$itemId'},
      );
      if (result.code == 0) {
        showToast(shouldFavorite ? "收藏成功" : "取消收藏成功");
        // 更新 tabDataMap 中每个 HomeTabDataState 的 dataList 中的 item
        final index = tabList.indexWhere((item) => item.id == itemId);
        final data = index == -1 ? null : tabList[index];
        if (data != null) {
          final favoriteTotal =
              (data.favoriteTotal) + (shouldFavorite ? 1 : -1);
          tabList[index] = data.copyWith(
            isFavorite: shouldFavorite ? 1 : 0,
            favoriteTotal: favoriteTotal,
          );
        }
      }
    } catch (e) {
      debugPrint('获取详情页数据失败: $e');
    }
  }

  /// 取消收藏事件
  void favoriteEventDialog(int itemId) {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "取消收藏",
        subTitle: "是否确认取消收藏该模版",
        sureAction: () => clickFavorite(itemId, false),
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 获取是否有草稿信息
  Future<void> showDraftDialog() async {
    if (!global.isLogin) {
      debugPrint('未登录=====或者登录失败');
      return;
    }
    final isHave = await DraftManager().hasDraft();
    if (isHave) {
      debugPrint('已经存在草稿列表: $isHave');
      final canvasModel = await DraftManager().loadDraft();
      if (canvasModel == null) {
        return;
      }
      debugPrint('已经获取到草稿列表: ${canvasModel.id}');
      if (canvasModel.id == 0) {
        showSingleDraftDialog();
      } else {
        requestServiceDraft(canvasModel);
      }
    } else {
      debugPrint('没有保存的草稿');
    }
  }

  /// 服务端没有保存的相关的草稿
  void showSingleDraftDialog() {
    SmartDialog.show(
      builder: (context) => ConfirmPopWidget(
        title: "继续编辑",
        subTitle: "您上次编辑的草稿未正常保存，是\n否返回编辑器继续编辑？",
        cancelAction: () {
          DraftManager().deleteDraft();
        },
        sureAction: () async {
          loadDraftDialog();
        },
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 服务端保存了相关的草稿
  void requestServiceDraft(CanvasModel model) async {
    try {
      final result = await http.post<DraftEditModel>(
        '/homePage/design/draft/read',
        data: {'id': model.id},
        converter: DraftEditModel.fromJson,
      );

      if (result.code == 0 && result.data != null) {
        debugPrint(
          "本地草稿列表==${model.timestamp}=====${result.data!.editTime}===",
        );

        if (model.timestamp > result.data!.editTime) {
          showSingleDraftDialog();
        } else {
          showMutipleDraftDialog(result.data!, model);
        }
      } else {
        showSingleDraftDialog();
      }
    } catch (e) {
      debugPrint('==本地没有要编辑的草稿==  error: $e');
    }
  }

  /// 服务端没有保存的相关的草稿
  void showMutipleDraftDialog(
    DraftEditModel editModel,
    CanvasModel canvalsModel,
  ) {
    SmartDialog.show(
      builder: (context) => DraftContinueEditWidget(
        localDraftTime: canvalsModel.timestamp,
        serverDraftTime: editModel.editTime,
        onLocalPreview: () async {
          final canvasSize = '${canvalsModel.width}:${canvalsModel.height}';
          final draftImgPath = await DraftManager().getScreenshotFilePath();
          Get.toNamed(
            AppRoutes.draftPreview,
            arguments: {
              "canvasSize": canvasSize,
              "isLocal": true,
              "imgPath": draftImgPath,
            },
          );
        },
        onServerPreview: () {
          Get.toNamed(
            AppRoutes.draftPreview,
            arguments: {
              "canvasSize": editModel.canvasSize,
              "isLocal": false,
              "imgPath": '${editModel.originalImage}${editModel.thumbnail}',
            },
          );
        },
        selectType: (type) {
          isLocal.value = (type == DraftType.local) ? true : false;
        },
        sureAction: () async {
          if (isLocal.value) {
            loadDraftDialog();
          } else {
            await loadServerDraft(editModel);
          }
        },
        cancelAction: () {
          DraftManager().deleteDraft(); // 删掉本地草稿
        },
      ),
      alignment: Alignment.center,
      animationType: SmartAnimationType.centerFade_otherSlide,
      animationTime: Duration(milliseconds: 250),
      maskColor: "#000000".color.withValues(alpha: 0.5),
      clickMaskDismiss: false,
      useAnimation: true,
      usePenetrate: false,
    );
  }

  /// 异步加载草稿并跳转到画布页面
  Future<void> loadDraftDialog() async {
    final draft = await DraftManager().loadDraft();
    if (draft == null) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      return;
    }
    // 根据当前屏幕重新计算画布矩阵
    draft.getMatrix4();
    SmartDialog.dismiss(status: SmartStatus.loading);
    Get.toNamed(
      AppRoutes.canvalsPage,
      arguments: {"model": draft, "type": PageSource.draft},
    );
  }

  /// 加载服务器草稿（下载字体和压缩包后加载）
  Future<void> loadServerDraft(DraftEditModel editModel) async {
    try {
      // 显示加载对话框
      showLoading('正在准备草稿...');

      // 准备服务器草稿（下载字体和压缩包）
      await DraftDownloadService.instance.prepareServerDraft(
        editModel,
        onProgress: (progress) {
          // 可以在这里更新进度显示
          debugPrint('DraftDownloadService: 进度 ${(progress * 100).toInt()}%');
        },
      );

      // 关闭加载对话框
      SmartDialog.dismiss();
      // 加载草稿并跳转
      await loadDraftDialog();
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.dismiss(status: SmartStatus.loading);
      debugPrint('加载服务器草稿失败: $e');
      // 可以显示错误提示
      showToast('加载草稿失败，请重试');
    }
  }
}
