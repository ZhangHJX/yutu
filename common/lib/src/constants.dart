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
  "zip": "application/zip",
};

/// 字体相关配置
const String defaultConfigFamliy = "AlibabaPuHuiTi";
const double defaultConfigFontSize = 16;
const FontWeight defaultConfigFontWeight = FontWeight.w400;
const String defaultConfigStyleName = '系统默认';
const String fontDialog = 'TextPropertyDialogController';

/// 图片相关全局变量
const String imageDialog = 'CanvalsImageDialog';
const String saveDialog = 'CanvalsSaveTemplateDialog';
