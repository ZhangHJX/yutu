import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:voicetemplate/pages/widgets/index.dart';
import 'package:voicetemplate/core/index.dart';
import 'middle_logic.dart';

class MiddlePage extends StatelessWidget {
  MiddlePage({super.key});
  final logic = Get.put(MiddleLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return Stack(
          children: [
            Obx(() {
              final imgSize = logic.getBgImageSize(
                logic.middleInfo.value?.canvasSize ?? '1:1',
              );
              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: imgSize.$1,
                  height: imgSize.$2,
                  child: CachedNetworkImage(
                    imageUrl: logic.imgUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.white),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.white),
                  ),
                ),
              );
            }),

            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(height: ScreenTools.statusBarHeight),

                    Container(
                      width: double.infinity,
                      height: 51.w,
                      padding: EdgeInsets.only(left: 10.w, right: 26.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CButton(
                            width: 51.w,
                            height: 51.w,
                            icon: Image.asset(
                              'assets/images/canvals/edit_back_icon.png',
                              width: 26.w,
                              height: 26.w,
                            ),
                            onPressed: () => Get.back(),
                          ),

                          // 收藏按钮
                          if (logic.type != PageSource.favorite ||
                              logic.type != PageSource.draft)
                            GestureDetector(
                              onTap: () {
                                if (!logic.global.isLogin) {
                                  Get.toNamed(AppRoutes.appLogin);
                                  return;
                                }

                                if (logic.isFavorite.value == 1) {
                                  logic.favoriteEventDialog();
                                } else {
                                  logic.clickFavoriteEvent(true);
                                }
                              },
                              child: SizedBox(
                                width: 36.w,
                                height: 36.w,
                                child: Center(
                                  child: Obx(
                                    () => Image.asset(
                                      logic.isFavorite.value == 1
                                          ? "assets/images/home/home_collectin_btn_finsh.png"
                                          : "assets/images/home/home_collectin_btn.png",
                                      width: 26.w,
                                      height: 26.w,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.w),
                      topRight: Radius.circular(20.w),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：标题相关
                      Padding(
                        padding: EdgeInsets.only(
                          left: 21.w,
                          right: 21.w,
                          top: 16.w,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                logic.middleInfo.value?.title ?? '',
                                style: TextStyle(
                                  fontSize: 18.w,
                                  fontWeight: FontWeight.w500,
                                  color: '#2C2C2C'.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            SizedBox(width: 8.w),

                            Container(
                              width: 38.w,
                              height: 16.w,
                              decoration: BoxDecoration(
                                color: '#DCEDFE'.color,
                                borderRadius: BorderRadius.circular(8.w),
                              ),
                              child: Center(
                                child: Text(
                                  logic.middleInfo.value?.isOfficial == 1
                                      ? '官方'
                                      : '个人',
                                  style: TextStyle(
                                    fontSize: 12.w,
                                    color: '#007BFE'.color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10.w),

                      // 第二行：收藏样式和图片、设计方文字结合体
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 21.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.only(left: 9.w, right: 12.w),
                              height: 25.w,
                              decoration: BoxDecoration(
                                color: '#A968FF'.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.5.w),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/home/middle_collection_icon.png',
                                    width: 16.w,
                                    height: 15.34.w,
                                  ),
                                  SizedBox(width: 5.w),

                                  Text(
                                    '${logic.middleInfo.value?.favoriteTotal ?? 0}收藏',
                                    style: TextStyle(
                                      fontSize: 12.w,
                                      color: Color(0xFFB759FF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/home/middle_person_icon.png',
                                  width: 16.w,
                                  height: 16.w,
                                ),

                                SizedBox(width: 7.w),

                                Text(
                                  '${logic.middleInfo.value?.isOfficial == 1 ? '官方' : '个人'}设计',
                                  style: TextStyle(
                                    fontSize: 12.w,
                                    color: '#007BFE'.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 13.w),

                      // 第三行：描述
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(left: 21.w, right: 16.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 12.w,
                        ),
                        height: 72.w,
                        decoration: BoxDecoration(
                          color: '#F1F1F1'.color,
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        child: Text(
                          logic.middleInfo.value?.desc ?? '',
                          style: TextStyle(
                            fontSize: 12.w,
                            color: '#757373'.color,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      SizedBox(height: 8.w),

                      // 第四行：风格标签（可以换行）
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 19.w),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.w,
                          children: logic.tagArray.map((model) {
                            return _buildTag(model.name);
                          }).toList(),
                        ),
                      ),

                      // 底部渐变按钮
                      Padding(
                        padding: EdgeInsets.only(
                          left: 28.w,
                          right: 28.w,
                          top: 35.w,
                          bottom: 11.w,
                        ),
                        child: CButton(
                          text: '立即使用',
                          width: double.infinity,
                          height: 48.w,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF8556FF), // 蓝色
                              Color(0xFF3691FF), // 紫色
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: 24.w,
                          textColor: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 16.w,
                            fontWeight: FontWeight.w500,
                          ),
                          onPressed: () => logic.handleImmediatelyUse(),
                        ),
                      ),

                      // 底部安全区域
                      SizedBox(height: ScreenTools.bottomBarHeight),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.w),
      decoration: BoxDecoration(
        color: Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: GradientText(
        text,
        colors: [
          Color(0xFFC86CFF), // #C86CFF
          Color(0xFF5B98FF), // #5B98FF
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        style: TextStyle(fontSize: 12.w, fontWeight: FontWeight.w500),
      ),
    );
  }
}
