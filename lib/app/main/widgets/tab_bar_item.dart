/// TabBar项目模型
class TabBarItem {
  final String normalPath;
  final String selectePath;
  final double width;
  final double height;
  final String label;

  /// ✅ 新增：选中时播放的帧序列（不传则走普通静态图）
  final List<String>? selectedFrames;

  /// ✅ 新增：每帧间隔（不传走默认）
  final Duration frameDuration;

  const TabBarItem({
    required this.normalPath,
    required this.selectePath,
    required this.label,
    required this.width,
    required this.height,
    this.selectedFrames,
    this.frameDuration = const Duration(milliseconds: 60),
  });
}
