// 画布撤销/重做功能模块
//
// 提供独立的撤销/重做管理功能，保证其独立性和扩展性
//
// 注意：画布的缩放和移动操作（CanvasStatusManager）不会记录到历史中
// 只有对画布元素的操作才会记录到历史中

// 核心管理器
export 'canvas_history_manager.dart';

// 命令基类
export 'commands/canvas_command.dart';

// 命令类
export 'commands/element_commands.dart';
export 'commands/element_transform_commands.dart';
export 'commands/property_commands.dart';
export 'commands/layer_commands.dart';
export 'commands/canvas_commands.dart';

// 克隆工具
export 'clone_tools/canvas_model_clone.dart';
export 'clone_tools/edit_box_data_clone.dart';
