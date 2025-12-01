import 'package:vector_math/vector_math_64.dart';
import '../../model/index.dart';

/// CanvasElement 深度克隆工具
///
/// 使用 JSON 序列化方式实现深度克隆，自动包含所有可序列化的属性
/// 注意：transform 属性不会被序列化，克隆后会重置为 Matrix4.identity()
class CanvasElementClone {
  /// 深度克隆 CanvasElement 对象
  ///
  /// 使用 JSON 序列化/反序列化方式创建所有属性的完全副本
  /// 这种方式会自动包含所有可序列化的属性，无需手动维护属性列表
  ///
  /// [source] 要克隆的 CanvasElement 对象
  /// 返回一个新的 CanvasElement 实例，包含所有属性的副本
  static CanvasElement clone(CanvasElement source) {
    // 使用 JSON 序列化/反序列化实现深度克隆
    final cloned = CanvasElement.fromJson(source.toJson());

    // transform 属性不会被序列化，需要单独处理
    // 由于 transform 是根据其他属性计算得出的，克隆后重置为默认值即可
    cloned.transform = Matrix4.identity();

    return cloned;
  }
}
