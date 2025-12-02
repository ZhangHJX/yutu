import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'commands/canvas_command.dart';

/// 画布撤销/重做管理器
class CanvasHistoryManager {
  final List<CanvasCommand> _undoStack = [];
  final List<CanvasCommand> _redoStack = [];

  /// 最大历史记录数量
  static const int maxHistorySize = 20;

  // 响应式状态变量
  final RxBool _canUndo = false.obs;
  final RxBool _canRedo = false.obs;

  /// 撤销/重做时的回调函数
  /// 在撤销或重做操作执行前调用，用于执行额外的操作（如取消选中状态）
  VoidCallback? onUndoRedo;

  CanvasHistoryManager({this.onUndoRedo}) {
    _updateState();
  }

  // ====================== 公共 API ======================

  /// 是否可以撤销（响应式）
  bool get canUndo => _canUndo.value;

  /// 是否可以撤销（响应式流，用于UI监听）
  RxBool get canUndoStream => _canUndo;

  /// 是否可以重做（响应式）
  bool get canRedo => _canRedo.value;

  /// 是否可以重做（响应式流，用于UI监听）
  RxBool get canRedoStream => _canRedo;

  /// 执行命令并推入撤销栈
  ///
  /// 这是记录操作到历史的主要方法
  /// 执行新命令时会自动清空重做栈
  ///
  /// [command] 要执行的命令对象
  void executeCommand(CanvasCommand command) {
    command.execute();
    _undoStack.add(command);

    // 限制历史记录数量
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    // 执行新命令时，清空重做栈
    _redoStack.clear();
    _updateState();
  }

  /// 撤销上一次操作
  ///
  /// 如果无法撤销（没有可撤销的操作），则不会执行任何操作
  /// 在执行撤销前会先调用 onUndoRedo 回调（如果已设置）
  void undo() {
    if (!_canUndo.value) return;

    // 先执行回调（如取消选中状态）
    onUndoRedo?.call();

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    // 限制重做栈历史记录数量
    if (_redoStack.length > maxHistorySize) {
      _redoStack.removeAt(0);
    }

    _updateState();
  }

  /// 重做上一次撤销的操作
  ///
  /// 如果无法重做（没有可重做的操作），则不会执行任何操作
  /// 在执行重做前会先调用 onUndoRedo 回调（如果已设置）
  void redo() {
    if (!_canRedo.value) return;

    // 先执行回调（如取消选中状态）
    onUndoRedo?.call();

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);

    // 再次限制撤销栈历史记录数量（重做同样可能导致超出）
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _updateState();
  }

  /// 清空所有历史记录
  ///
  /// 通常在新建画布或重置画布时调用
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _updateState();
  }

  /// 获取当前撤销栈的大小（用于调试）
  int get undoStackSize => _undoStack.length;

  /// 获取当前重做栈的大小（用于调试）
  int get redoStackSize => _redoStack.length;

  // ====================== 私有方法 ======================

  /// 更新响应式状态
  void _updateState() {
    _canUndo.value = _undoStack.isNotEmpty;
    _canRedo.value = _redoStack.isNotEmpty;
  }
}
