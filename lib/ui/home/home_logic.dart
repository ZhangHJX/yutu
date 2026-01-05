import 'package:common/common.dart';
import 'package:flutter/material.dart';
import '../../stores/global.dart';
import '../canvas/draft/index.dart';
import '../../app/routes/index.dart';
import '../canvas/fonts/font_manager.dart';
import '../canvas/model/index.dart';
import 'package:voicetemplate/ui/utils/file/index.dart';
import 'package:voicetemplate/ui/widgets/index.dart';
import '../model/index.dart';
//最新的数据
import './model/home_model.dart';
import 'draft/draft_edit_model.dart';
import 'draft/draft_continue_edit_widget.dart';
import 'draft/draft_download_service.dart';

class HomeLogic extends GetxController with GetTickerProviderStateMixin {
  final global = Get.find<GlobalLogic>();

  /// 推荐列表（响应式）
  final recommendList = <CommonItemModel>[].obs;

  /// Tag列表（响应式）
  final tagList = <TagModel>[].obs;

  // 每个 tab 的数据状态（使用 tagId 作为 key，0 表示全部）
  final RxMap<int, TabDataState> tabDataMap = <int, TabDataState>{}.obs;

  // Tab 索引
  final selectedTabIndex = 0.obs;

  /// 草稿选择
  final isLocal = true.obs;

  /// 获取当前 tab 是否还有更多数据
  RxBool get hasMore {
    final tagId = _getCurrentTagId();
    return tabDataMap[tagId]?.hasMore ?? true.obs;
  }

  GlobalKey refresherKey = GlobalKey();
  RefreshController refreshController = RefreshController(
    initialRefresh: false,
  );

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
    showDraftDialog();
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
      if (refresh) {
        refreshController.refreshCompleted();
      } else {
        if (hasMore.value) {
          refreshController.loadComplete();
        } else {
          refreshController.loadNoData();
        }
      }
    } catch (e) {
      if (refresh) {
        refreshController.refreshFailed();
      } else {
        refreshController.loadFailed();
      }
      debugPrint('获取首页数据失败: $e');
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

  /// 收藏事件处理
  Future<void> clickFavorite(int itemId, bool shouldFavorite) async {
    try {
      final result = await http.post(
        shouldFavorite
            ? '/homePage/favorite-store'
            : '/homePage/favorite-destroy',
        data: {"link_id": '$itemId'},
        showErrorToast: false,
      );

      if (result.code == 0) {
        // 更新 isFavorite 状态
        final newFavoriteStatus = shouldFavorite ? 1 : 0;

        // 更新 recommendList 中的 item
        final recommendIndex = recommendList.indexWhere(
          (item) => item.id == itemId,
        );
        if (recommendIndex != -1) {
          final oldItem = recommendList[recommendIndex];
          recommendList[recommendIndex] = oldItem.copyWith(
            isFavorite: newFavoriteStatus,
          );
        }

        // 更新 tagList 中每个 TagModel 的 list 中的 item
        final updatedTagList = <TagModel>[];
        for (var tag in tagList) {
          final tagIndex = tag.list.indexWhere((item) => item.id == itemId);
          if (tagIndex != -1) {
            final updatedList = List<CommonItemModel>.from(tag.list);
            updatedList[tagIndex] = updatedList[tagIndex].copyWith(
              isFavorite: newFavoriteStatus,
            );
            updatedTagList.add(tag.copyWith(list: updatedList));
          } else {
            updatedTagList.add(tag);
          }
        }
        if (updatedTagList.isNotEmpty) {
          tagList.value = updatedTagList;
        }

        // 更新 tabDataMap 中每个 TabDataState 的 dataList 中的 item
        for (var tabData in tabDataMap.values) {
          final dataIndex = tabData.dataList.indexWhere(
            (item) => item.id == itemId,
          );
          if (dataIndex != -1) {
            final oldItem = tabData.dataList[dataIndex];
            tabData.dataList[dataIndex] = oldItem.copyWith(
              isFavorite: newFavoriteStatus,
            );
          }
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
    // if (!global.isLogin) {
    //   return;
    // }
    // final isHave = await DraftManager().hasDraft();
    // if (isHave) {
    // debugPrint('已经存在草稿列表: $isHave');
    // final canvasModel = await DraftManager().loadDraft();
    // if (canvasModel == null) {
    //   return;
    // }
    // debugPrint('已经获取到草稿列表: ${canvasModel.id}');
    // if (canvasModel.id == 0) {
    //   showSingleDraftDialog();
    // } else {
    requestServiceDraft(CanvasModel());
    // }
    // }
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
      debugPrint('草稿列表已经进行了请求');
      final result = await http.post<DraftEditModel>(
        '/homePage/design/draft/read',
        data: {'id': '2'},
        converter: DraftEditModel.fromJson,
        showErrorToast: true,
      );
      debugPrint("哈哈哈哈哈哈====${result.code}==${result.data}==");
      if (result.code == 0 && result.data != null) {
        debugPrint("哈哈哈哈哈哈====result.code == ${result.data}====");
        showMutipleDraftDialog(result.data!, model);
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
        onLocalPreview: () {
          final canvasSize = '${canvalsModel.width}:${canvalsModel.height}';
          Get.toNamed(
            AppRoutes.draftPreview,
            arguments: {
              "canvasSize": canvasSize,
              "isLocal": true,
              "imgPath": '',
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
      SmartDialog.dismiss();
      return;
    }
    // 根据当前屏幕重新计算画布矩阵
    draft.getMatrix4();
    SmartDialog.dismiss();
    Get.toNamed(AppRoutes.canvalsPage, arguments: draft);
  }

  /// 加载服务器草稿（下载字体和压缩包后加载）
  Future<void> loadServerDraft(DraftEditModel editModel) async {
    try {
      // 显示加载对话框
      SmartDialog.showLoading(
        msg: '正在准备草稿...',
        maskColor: "#000000".color.withValues(alpha: 0.5),
      );

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
      debugPrint('加载服务器草稿失败: $e');
      // 可以显示错误提示
      SmartDialog.showToast('加载草稿失败，请重试');
    }
  }
}
