import 'package:flutter/material.dart';
import 'tab_bar_item.dart';
import 'frame_sequence_anim.dart';

Widget buildTabIcon(TabBarItem item, bool selected, int index) {
  if (selected &&
      item.selectedFrames != null &&
      item.selectedFrames!.isNotEmpty) {
    return FrameSequenceAnim(
      frames: item.selectedFrames ?? [],
      fps: 24,
      loop: index == 3,
      width: item.width,
      height: item.height,
    );
  }

  // 未选中 / 没配置帧动画 -> 静态图
  return Image.asset(
    selected ? item.selectePath : item.normalPath,
    width: item.width,
    height: item.height,
  );
}
