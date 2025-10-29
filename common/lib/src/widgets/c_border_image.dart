import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CBorderImage extends StatelessWidget {
  CBorderImage({
    required this.imgUrl,
    this.width,
    this.height,
    super.key,
    this.borderRadius,
    double? borderWidth,
    this.isShowBorder = true,
    this.isCircle = false,
    this.showGrayBg = true,
    this.size,
    this.fit = BoxFit.cover,
    this.canPreview = false,
    this.isHero = true,
    this.color,
  }) : assert(!(borderRadius != null && isCircle), 'borderRadius和isCircle不能同时使用'),
       assert(!isCircle || (size != null || width != null), '设置了isCircle, 则必须设置size或width'),
       borderWidth = borderWidth ?? hairline;

  final BorderRadius? borderRadius;
  final String imgUrl;
  final double? width;
  final double? height;

  final double borderWidth;

  final bool isShowBorder;

  final bool showGrayBg;

  final bool isCircle;

  final double? size;

  final BoxFit? fit;

  final bool canPreview;

  final bool isHero;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final finalBorderRadius = isCircle
        ? BorderRadius.circular(size ?? width! / 2)
        : (borderRadius ?? BorderRadius.zero);

    Widget image = switch (imgUrl) {
      final String url when url.startsWith('http') => Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        color: color,
      ),
      final String url when url.startsWith('assets/') => Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        color: color,
      ),
      final String url when url.startsWith('/') => Image.file(
        File.fromUri(Uri.file(url)),
        fit: fit,
        width: width,
        height: height,
        color: color,
      ),
      _ => SizedBox(width: width, height: height),
    };

    if (canPreview) {
      image = GestureDetector(
        onTap: () => Get.toNamed('/image_preview', arguments: ImagePreviewModel(imgUrl: imgUrl)),
        child: isHero ? Hero(tag: '${_generateUniqueHeroTag()}_$imgUrl', child: image) : image,
      );
    }

    return Container(
      width: size ?? width,
      height: size ?? height,
      decoration: BoxDecoration(
        color: showGrayBg ? cImg : null,
        border: isShowBorder ? Border.all(color: cImg, width: borderWidth) : null,
        borderRadius: finalBorderRadius,
      ),
      child: (isCircle || borderRadius != null)
          ? ClipRRect(borderRadius: finalBorderRadius, child: image)
          : image,
    );
  }

  /// 生成唯一的 Hero 标签
  String _generateUniqueHeroTag() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class CAssetImage extends CBorderImage {
  CAssetImage({
    required super.imgUrl,
    super.key,
    super.width,
    super.height,
    super.borderRadius,
    super.isShowBorder = false,
    super.showGrayBg = false,
    super.isCircle,
    super.size,
    super.fit,
    super.canPreview,
    super.isHero = false,
    super.color,
  });
}
