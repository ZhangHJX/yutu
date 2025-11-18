class GestureConfig {
  /// 单指拖动的最小距离（防止轻微抖动触发 pan）
  final double panMinDistance;

  /// Scale/Rotate 的灵敏度可以放在这里扩展
  final double scaleSensitivity;
  final double rotationSensitivity;

  const GestureConfig({
    this.panMinDistance = 0.5,
    this.scaleSensitivity = 1.0,
    this.rotationSensitivity = 1.0,
  });
}
