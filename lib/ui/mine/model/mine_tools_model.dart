import 'package:flutter/foundation.dart'; // 里面有 VoidCallback

class MineToolsModel {
  String icon; // 图标（可以是 asset 路径）
  String title; // 标题
  VoidCallback? onTap; // 点击事件 ✅

  MineToolsModel({this.icon = '', this.title = '', this.onTap});
}
