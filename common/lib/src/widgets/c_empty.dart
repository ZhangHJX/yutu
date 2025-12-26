import 'package:common/common.dart';
import 'package:flutter/material.dart';

class CEmpty extends StatelessWidget {
  const CEmpty({
    super.key,
    this.text,
    this.top,
    this.bottom,
    this.color,
    this.imgPath,
    this.height,
    this.imgHeight,
    this.imgWidth,
    this.fontSize,
  });

  final String? text;
  final String? imgPath;
  final double? top;
  final double? bottom;
  final Color? color;
  final double? height;
  final double? imgHeight;
  final double? imgWidth;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      height: height,
      padding: .only(top: top ?? 0, bottom: bottom ?? 100.w),
      child: Column(
        mainAxisAlignment: .center,
        spacing: 4.w,
        children: [
          CBorderImage(
            imgUrl: imgPath ?? 'assets/images/common/ic_empty.png',
            width: imgWidth ?? 180.w,
            height: imgHeight ?? 140.w,
            showBorder: false,
            isGreyBg: false,
          ),
          Row(
            mainAxisAlignment: .center,
            children: [
              Text(text ?? '空空的什么都没有', style: text989897(fontSize: fontSize ?? 16.w, height: 1)),
            ],
          ),
        ],
      ),
    );
  }
}
