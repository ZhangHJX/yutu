import 'package:flutter/material.dart';

/// 登录token的key
String tokenKey = 'app_token_key';

/// 用户信息
String userInfoKey = 'app_user_info_key';

// 编辑框
const double editBorderWidth = 3.0; // 边框宽度
const double editHitCircleSize = 25.0; // 控制点点击范围

const double rotationButtonSize = 26.0; //旋转按钮大小
const double rotationButtonPadding = 15.0; //旋转按钮到边框的间距

Map<String, String> mimeTypeMap = {
  "jpeg": "image/jpeg",
  "jpg": "image/jpeg",
  "gif": "image/gif",
  "png": "image/png",
  "heic": "image/heic",
  "heif": "image/heif",
  "svg": "image/svg+xml",
  "webp": "image/webp",
  "bmp": "image/bmp",
};

FontWeight getTextFontWeight(int w) {
  if (w <= 150) return FontWeight.w100;
  if (w <= 250) return FontWeight.w200;
  if (w <= 350) return FontWeight.w300;
  if (w <= 450) return FontWeight.w400;
  if (w <= 550) return FontWeight.w500;
  if (w <= 650) return FontWeight.w600;
  if (w <= 750) return FontWeight.w700;
  if (w <= 850) return FontWeight.w800;
  if (w > 850) return FontWeight.w900;
  return FontWeight.w400;
}
