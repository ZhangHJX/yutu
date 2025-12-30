import 'package:common/common.dart';
import 'package:flutter/material.dart';

class MiddlePage extends StatelessWidget {
  const MiddlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 底部背景图片
          // 注意：请根据实际背景图片路径替换此处
          Image.asset(
            'assets/images/login/app_login_bg.png', // 临时使用登录背景，请替换为实际背景图
            fit: BoxFit.cover,
          ),

          // 2. 顶部按钮区域
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 返回按钮
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/login/login_back_icon.png',
                          width: 16.w,
                          height: 16.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // 收藏按钮
                  GestureDetector(
                    onTap: () {
                      // 处理收藏逻辑
                    },
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_border,
                        color: Colors.yellow,
                        size: 20.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 底部内容视图
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.w),
                  topRight: Radius.circular(20.w),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行：标题和标签
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '梦幻渐变海报梦幻渐变海报',
                          style: TextStyle(
                            fontSize: 20.w,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.w,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFE6F4FF),
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                        child: Text(
                          '官方',
                          style: TextStyle(
                            fontSize: 12.w,
                            color: Color(0xFF64A2FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.w),

                  // 第二行：收藏样式和图片、设计方文字结合体
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Color(0xFFC86CFF),
                            size: 16.w,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '9999收藏',
                            style: TextStyle(
                              fontSize: 14.w,
                              color: Color(0xFFC86CFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 16.w),
                      Row(
                        children: [
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: Icon(
                              Icons.person,
                              size: 12.w,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '官方设计',
                            style: TextStyle(
                              fontSize: 14.w,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16.w),

                  // 第三行：描述
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Text(
                      '适合房间宣传、活动预告的通用海报模板',
                      style: TextStyle(
                        fontSize: 14.w,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.w),

                  // 第四行：风格标签（可以换行）
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.w,
                    children: [
                      _buildTag('动漫'),
                      _buildTag('恋爱'),
                      _buildTag('简约'),
                      _buildTag('活力'),
                      _buildTag('赛博'),
                    ],
                  ),

                  SizedBox(height: 24.w),

                  // 底部渐变按钮
                  CButton(
                    text: '立即使用',
                    width: double.infinity,
                    height: 48.w,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFC86CFF), // 紫色
                        Color(0xFF5B98FF), // 蓝色
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
                    onPressed: () {
                      // 处理使用按钮点击
                    },
                  ),

                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
      decoration: BoxDecoration(
        color: Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.w,
          color: Colors.grey[800],
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
