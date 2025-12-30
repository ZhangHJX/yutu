import 'package:flutter/material.dart';
import 'frame_animated_asset.dart';
import 'tab_bar_item.dart';

Widget buildTabIcon(TabBarItem item, bool selected) {
  if (selected &&
      item.selectedFrames != null &&
      item.selectedFrames!.isNotEmpty) {
    return FrameAnimatedAsset(
      frames: item.selectedFrames!,
      playing: true, // 选中开始播
      width: item.width,
      height: item.height,
      frameDuration: item.frameDuration,
      resetOnStop: true,
      loop: true,
    );
  }

  // 未选中 / 没配置帧动画 -> 静态图
  return Image.asset(
    selected ? item.selectePath : item.normalPath,
    width: item.width,
    height: item.height,
  );
}
