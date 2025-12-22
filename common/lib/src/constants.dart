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

int getNumberFontWeight(String styleName) {
  switch (styleName) {
    case '极细':
      return 100;
    case '特细':
      return 200;
    case '细体':
      return 300;
    case '系统默认':
    case '常规':
      return 400;
    case '中等':
      return 500;
    case '半粗':
      return 600;
    case '粗体':
      return 700;
    case '特粗':
      return 800;
    case '黑体/重':
      return 900;
    default:
      return 400;
  }
}

String flutterFontWeight(int w) {
  if (w <= 150) return '极细';
  if (w <= 250) return '特细';
  if (w <= 350) return '细体';
  if (w <= 450) return '系统默认';
  if (w <= 550) return '中等';
  if (w <= 650) return '半粗';
  if (w <= 750) return '粗体';
  if (w <= 850) return '特粗';
  if (w > 850) return '黑体/重';
  return '系统默认';
}

/// 字体相关配置
const String defaultConfigFamliy = "AlibabaPuHuiTi";
const double defaultConfigFontSize = 16;
const FontWeight defaultConfigFontWeight = FontWeight.w400;
const String defaultConfigStyleName = '系统默认';
