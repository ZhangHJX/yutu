import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'mine_logic.dart';

class MinePage extends StatelessWidget {
  MinePage({super.key});

  final logic = Get.put(MineLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: "#F5F5F5".color,
      body: Stack(
        children: [
          _buildHeaderBackground(),
          SafeArea(
            child: Obx(() {
              return Column(
                children: [
                  _buildHeaderBar(),
                  _buildMineInfoContent(),
                  if (logic.isLogin.value) _buildLoggedInContent(),
                  if (logic.isLogin.value) _buildToolsCard(),
                  _buildSoftwareInfoCard(),
                  if (logic.isLogin.value) _buildLoginOutCard(),

                  Spacer(),
                  Text(
                    '语音厅设计助手 V1.0\n让设计更简单',
                    style: TextStyle(
                      fontSize: 11.w,
                      color: "#9E9E9E".color,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 51.w),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 顶部渐变背景
  Widget _buildHeaderBackground() {
    return Container(
      height: 146.w,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB1D5FF), Color(0xFFF5F6FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildHeaderBar() {
    return Padding(
      padding: EdgeInsets.only(
        left: 22.w,
        top: 10.w,
        right: 19.w,
        bottom: 10.w,
      ),
      child: Row(
        children: [
          Image.asset(
            "assets/images/mine/mine_top_icon.png",
            width: 45.w,
            height: 28.w,
            fit: BoxFit.cover,
          ),

          const Spacer(),

          GestureDetector(
            onTap: logic.onTapMyServices,
            child: Image.asset(
              "assets/images/mine/mine_top_services.png",
              width: 22.w,
              height: 22.w,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  /// 个人信息
  Widget _buildMineInfoContent() {
    final user = logic.global.userInfo.value;
    return Padding(
      padding: EdgeInsets.only(left: 22.w, top: 9.w, right: 20.w),
      child: Row(
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/images/mine/mine_info_icon_bg.png",
                ), // 或 NetworkImage(...)
                fit: BoxFit.cover, // 拉伸方式：cover / contain 等
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: ClipOval(
                      child: user.avatar.isEmpty
                          ? Container(
                              width: 56.w,
                              height: 56.w,
                              color: const Color(0xFFF2F3F7),
                              child: const Icon(Icons.person_outline, size: 32),
                            )
                          :
                            // : Image.network(
                            //     user.avatar,
                            //     width: 56,
                            //     height: 56,
                            //     fit: BoxFit.cover,
                            //   ),
                            Image.asset(
                              "assets/images/mine/mine_info_editor.png",
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/images/mine/mine_info_editor.png",
                    width: 18.w,
                    height: 18.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          Expanded(
            child: GestureDetector(
              onTap: logic.login,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '点击登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: "#121F33".color,
                    ),
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    '登录后获取更多功能信息',
                    style: TextStyle(fontSize: 13.w, color: "#848484".color),
                  ),
                ],
              ),
            ),
          ),

          CButton.icon(
            size: 32.w,
            onPressed: logic.onTapPersonInfo,
            child: Image.asset(
              "assets/images/mine/mine_info_go.png",
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  /// 我的设计
  Widget _buildLoggedInContent() {
    return Container(
      margin: EdgeInsets.only(top: 21.w, left: 14.w, right: 13.w),
      height: 162.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12.w)),
        image: DecorationImage(
          image: AssetImage("assets/images/mine/mine_design_bg.png"),
          fit: BoxFit.cover, // 拉伸方式：cover / contain 等
        ),
      ),
      child: _buildDesignBlock(),
    );
  }

  Widget _buildDesignBlock() {
    final user = logic.global.userInfo.value;
    final designs = user.designImages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: logic.onTapMyDesign,
          child: SizedBox(
            height: 39.w,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 13.w),
                Image.asset(
                  "assets/images/mine/mine_design_icon.png",
                  width: 23.w,
                  height: 24.w,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 10.w),
                Text(
                  '我的设计',
                  style: TextStyle(
                    color: "#2F3C77".color,
                    fontSize: 16.w,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Image.asset(
                  "assets/images/mine/mine_item_row.png",
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 13.w),
              ],
            ),
          ),
        ),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12.w)),
            ),
            child: designs.isEmpty
                ? _buildMyDesignCard()
                : Padding(
                    padding: EdgeInsets.only(
                      left: 13.w,
                      top: 18.w,
                      bottom: 19.w,
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: designs.length,
                      separatorBuilder: (context, index) {
                        return SizedBox(width: 5.w);
                      },
                      itemBuilder: (_, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            designs[index],
                            height: 86.w,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 110,
                                height: 90,
                                alignment: Alignment.center,
                                color: Colors.white24,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 90,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // 我的设计无数据
  Widget _buildMyDesignCard() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5.w),
            child: Image.asset(
              "assets/images/mine/mine_design_empty.png",
              width: 100.w,
              height: 93.w,
              fit: BoxFit.cover,
            ),
          ),
          Text(
            '暂无内容,快去创建设计吧~',
            style: TextStyle(
              color: "#9E9E9E".color,
              fontSize: 12.w,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// 常用工具卡片
  Widget _buildToolsCard() {
    final tools = [
      MineToolsModel(
        icon: "assets/images/mine/mine_tools_caogao.png",
        title: '我的草稿',
        onTap: logic.onTapMyDraft,
      ),

      MineToolsModel(
        icon: "assets/images/mine/mine_tools_collection.png",
        title: '我的收藏',
        onTap: logic.onTapMyFavorite,
      ),
      MineToolsModel(
        icon: "assets/images/mine/mine_tools_sucai.png",
        title: '我的素材',
        onTap: logic.onTapMyResource,
      ),

      MineToolsModel(
        icon: "assets/images/mine/mine_tools_kefu.png",
        title: '我的客服',
        onTap: logic.onTapService,
      ),
    ];

    return Container(
      height: 132.w,
      margin: EdgeInsets.only(left: 14.w, right: 13.w, top: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15.w, top: 10.w),
            child: Text(
              '常用工具',
              style: TextStyle(
                fontSize: 15.w,
                fontWeight: FontWeight.w600,
                color: "#2F3C77".color,
              ),
            ),
          ),
          SizedBox(height: 16.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tools.length, (index) {
                final tool = tools[index];
                return _buildToolItem(tool);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(MineToolsModel model) {
    return GestureDetector(
      onTap: model.onTap,
      child: Column(
        children: [
          Image.asset(model.icon, width: 38.w, height: 38.w, fit: BoxFit.cover),
          SizedBox(height: 4.w),
          Text(
            model.title,
            style: TextStyle(fontSize: 12.w, color: "#444550".color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 软件信息卡片（登录前后通用）
  Widget _buildSoftwareInfoCard() {
    return GestureDetector(
      onTap: logic.goToAppInfo,
      child: Container(
        height: 46.w,
        margin: EdgeInsets.only(
          left: 13.w,
          right: 14.w,
          top: logic.isLogin.value ? 10.w : 21.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 13.w, right: 22.w),
          child: Row(
            children: [
              Text(
                '软件信息',
                style: TextStyle(
                  fontSize: 14.w,
                  color: "#121F33".color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Image.asset(
                "assets/images/mine/mine_item_row.png",
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 软件信息卡片（登录前后通用）
  Widget _buildLoginOutCard() {
    return GestureDetector(
      onTap: logic.logout,
      child: Container(
        height: 46.w,
        width: ScreenTools.screenWidth,
        padding: EdgeInsets.only(left: 13.w),
        margin: EdgeInsets.only(left: 13.w, right: 14.w, top: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.w),
        ),
        alignment: Alignment.centerLeft, // 关键
        child: Text(
          '退出登录',
          style: TextStyle(
            fontSize: 14.w,
            color: "#121F33".color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class MineToolsModel {
  String icon; // 图标（可以是 asset 路径）
  String title; // 标题
  VoidCallback? onTap; // 点击事件 ✅

  MineToolsModel({this.icon = '', this.title = '', this.onTap});
}
