import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'mine_logic.dart';
import './pages/widgets/created_works_text.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
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
              final bool isLogin = logic.global.isLogin;
              return Column(
                children: [
                  _buildHeaderBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMineInfoContent(),
                          if (isLogin) _buildLoggedInContent(),
                          if (isLogin) _buildToolsCard(),
                          if (isLogin) _buildSetPasswordCard(),
                          _buildSoftwareInfoCard(),
                          if (isLogin) _buildLoginOutCard(),

                          SizedBox(height: 15.w),

                          /// 登录状态：文案跟随内容在滚动区域中
                          if (isLogin) ...[
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

                          /// 未登录时，可以留一点底部空隙，避免内容太贴近底部
                          if (!isLogin) SizedBox(height: 15.w),
                        ],
                      ),
                    ),
                  ),

                  /// 未登录状态：文案固定在页面底部（不跟随滚动）
                  if (!isLogin)
                    Padding(
                      padding: EdgeInsets.only(bottom: 51.w),
                      child: Text(
                        '语音厅设计助手 V1.0\n让设计更简单',
                        style: TextStyle(
                          fontSize: 11.w,
                          color: "#9E9E9E".color,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
        ],
      ),
    );
  }

  /// 个人信息
  Widget _buildMineInfoContent() {
    final icon = logic.global.avatar ?? "";
    final avatar = icon.isEmpty
        ? "assets/images/mine/mine_info_empty.png"
        : icon;
    return Padding(
      padding: EdgeInsets.only(left: 22.w, top: 9.w, right: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: logic.onTapPersonInfo,
            child: Container(
              width: 62.w,
              height: 62.w,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/images/mine/mine_info_icon_bg.png",
                  ), // 或 NetworkImage(...)
                  fit: BoxFit.cover, // 拉伸方式：cover / contain 等
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CBorderImage(size: 54.w, imgUrl: avatar, isCircle: true),

                  if (logic.global.isLogin)
                    Positioned(
                      bottom: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: logic.onTapPersonInfo,
                        child: Image.asset(
                          "assets/images/mine/mine_info_editor.png",
                          width: 18.w,
                          height: 18.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
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
                    logic.global.isLogin
                        ? logic.global.userInfo.value.nickname
                        : '点击登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: "#121F33".color,
                    ),
                  ),
                  SizedBox(height: 4.w),

                  if (logic.global.isLogin)
                    CreatedWorksText(count: logic.global.userInfo.value.count),
                  if (!logic.global.isLogin)
                    Text(
                      '登录后获取更多功能信息',
                      style: TextStyle(fontSize: 13.w, color: "#848484".color),
                    ),
                ],
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: logic.onTapMyDesign,
          child: SizedBox(
            height: 39.w,
            width: double.infinity,
            child: Row(
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
                Expanded(child: Container(color: Colors.transparent)),
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

        Obx(() {
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12.w)),
              ),
              child: logic.designList.isEmpty
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
                        itemCount: logic.designList.length,
                        separatorBuilder: (context, index) {
                          return SizedBox(width: 5.w);
                        },
                        itemBuilder: (_, index) {
                          final item = logic.designList[index];
                          List<String> parts =
                              item.canvasSize?.split(':') ?? [];
                          if (parts.isEmpty) {
                            parts = ["1", "1"];
                          }
                          final ratio =
                              double.parse(parts[0]) / double.parse(parts[1]);
                          return Material(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.w),
                              side: BorderSide(
                                width: 1,
                                color: "#E8EBFF".color,
                              ),
                            ),
                            child: SizedBox(
                              height: 86.w,
                              width: 86.w * ratio,
                              child: CachedNetworkImage(
                                imageUrl:
                                    '${item.originalImage}${item.thumbnail}',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: "#F5F5F5".color,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: "#9082FF".color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          );
        }),
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

  /// 设置密码
  Widget _buildSetPasswordCard() {
    return GestureDetector(
      onTap: logic.onTapPassWord,
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
          '设置密码',
          style: TextStyle(
            fontSize: 14.w,
            color: "#121F33".color,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          top: logic.global.isLogin ? 10.w : 21.w,
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
