import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../model/index.dart';
import '../pages/canvals/canvals_controller.dart';
import '../../../file/index.dart';

/// 草稿管理类
/// - 负责自动保存和加载画布草稿（全局单例，整个应用只有一份草稿）
/// - 监听画布属性和元素属性的变化
/// - 使用防抖机制自动保存到本地
/// - 支持加载草稿
class DraftManager {
  static final DraftManager _instance = DraftManager._internal();
  factory DraftManager() => _instance;
  DraftManager._internal();

  CanvalsController? _controller;
  Timer? _saveTimer;
  bool _isAutoSaving = false;

  bool ishChanage = false;

  /// 防抖延迟时间（毫秒）
  static const int _debounceDelayMs = 500;

  /// 开始自动保存
  /// [controller] 画布控制器
  void startAutoSave(CanvalsController controller) {
    // 如果已经监听同一个控制器，则不需要重新设置
    if (_controller == controller) {
      return;
    }

    // 停止之前的监听
    stopAutoSave();

    _controller = controller;

    // 监听元素列表的变化
    controller.elements.listen((elements) {
      _scheduleSave();
    });
  }

  /// 停止自动保存
  void stopAutoSave() {
    // 保存最后一次变更
    if (_saveTimer != null && _saveTimer!.isActive) {
      _saveTimer!.cancel();
      _saveDraft();
    }
    _saveTimer?.cancel();
    _saveTimer = null;
    _controller = null;
  }

  /// 调度保存（防抖）
  void _scheduleSave() {
    // 取消之前的定时器
    _saveTimer?.cancel();

    // 创建新的定时器
    _saveTimer = Timer(Duration(milliseconds: _debounceDelayMs), () {
      _saveDraft();
    });
  }

  /// 保存草稿到本地
  Future<void> _saveDraft() async {
    if (_controller == null || _isAutoSaving) return;

    _isAutoSaving = true;

    try {
      // 构建完整的画布数据（包含元素列表）
      final snapshot = _controller!.buildSnapshot();
      if (snapshot == null) {
        debugPrint('DraftManager: 无法构建画布快照');
        return;
      }

      // 转换为JSON
      final jsonData = snapshot.toJson();
      final jsonString = jsonEncode(jsonData);

      // 获取保存目录（固定路径，不依赖canvasId）
      final draftDir = await _getDraftDirectory();

      // 写入文件
      await FileManager.writeTextFile(
        directory: draftDir,
        fileName: 'draft.json',
        content: jsonString,
      );
      debugPrint('DraftManager: 草稿已保存到 ${draftDir.path}/draft.json');
      ishChanage = true;
    } catch (e, stackTrace) {
      debugPrint('DraftManager: 保存草稿失败: $e\n$stackTrace');
    } finally {
      _isAutoSaving = false;
    }
  }

  /// 加载草稿
  /// 返回画布模型，如果不存在则返回null
  Future<CanvasModel?> loadDraft() async {
    try {
      final draftDir = await _getDraftDirectory();

      // 读取文件内容
      final jsonString = await FileManager.readTextFile(
        directory: draftDir,
        fileName: 'draft.json',
      );

      if (jsonString == null) {
        debugPrint('DraftManager: 草稿文件不存在: ${draftDir.path}/draft.json');
        return null;
      }
      // 解析为画布模型
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final canvasModel = CanvasModel.fromJson(jsonData);
      debugPrint('DraftManager: 草稿已加载: ${draftDir.path}/draft.json');
      return canvasModel;
    } catch (e, stackTrace) {
      debugPrint('DraftManager: 加载草稿失败: $e\n$stackTrace');
      return null;
    }
  }

  /// 删除草稿
  Future<bool> deleteDraft() async {
    try {
      final draftDir = await _getDraftDirectory();

      // 删除文件
      await FileManager.deleteFile(directory: draftDir, fileName: 'draft.json');
      debugPrint('DraftManager: 草稿已删除: ${draftDir.path}/draft.json');

      final directory = await _getDraftDirectory();
      await FileManager.deleteDirectory(directory, deleteDirectory: true);
      ishChanage = false;
      return true;
    } catch (e, stackTrace) {
      debugPrint('DraftManager: 删除草稿失败: $e\n$stackTrace');
      return false;
    }
  }

  /// 检查草稿是否存在
  Future<bool> hasDraft() async {
    try {
      final draftDir = await _getDraftDirectory();
      return await FileManager.isFileExists(
        directory: draftDir,
        fileName: 'draft.json',
      );
    } catch (e) {
      debugPrint('DraftManager: 检查草稿失败: $e');
      return false;
    }
  }

  /// 获取到本地草稿json
  Future<String> getDraftFilePath() async {
    try {
      final draftDir = await _getDraftDirectory();
      final String filePath = p.join(draftDir.path, 'draft.json');
      return filePath;
    } catch (e) {
      return '';
    }
  }

  /// 获取草稿目录（固定路径）
  Future<Directory> _getDraftDirectory() async {
    return await DirectoryManager.getDocumentsSubDirectory('cavals');
  }

  /// 通知画布属性已变更
  /// 当画布属性（如填充颜色、透明度等）改变时调用此方法
  void notifyCanvasPropertyChanged() {
    _scheduleSave();
  }

  /// 通知元素属性已变更
  ///
  /// 当元素属性改变时调用此方法
  void notifyElementPropertyChanged() {
    _scheduleSave();
  }

  /// 通知元素列表已变更
  ///
  /// 当添加、删除、移动元素时调用此方法
  void notifyElementsChanged() {
    _scheduleSave();
  }
}
