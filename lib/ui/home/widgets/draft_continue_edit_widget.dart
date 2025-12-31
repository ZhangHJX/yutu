import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DraftType { local, server }

class DraftContinueEditWidget extends StatefulWidget {
  final int localDraftTime;
  final int serverDraftTime;
  final VoidCallback? onLocalPreview;
  final VoidCallback? onServerPreview;
  final VoidCallback? sureAction;
  final VoidCallback? cancelAction;

  const DraftContinueEditWidget({
    super.key,
    required this.localDraftTime,
    required this.serverDraftTime,
    this.onLocalPreview,
    this.onServerPreview,
    this.sureAction,
    this.cancelAction,
  });

  @override
  State<DraftContinueEditWidget> createState() =>
      _DraftContinueEditWidgetState();
}

class _DraftContinueEditWidgetState extends State<DraftContinueEditWidget> {
  DraftType _selectedType = DraftType.local;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Padding(
            padding: EdgeInsets.only(top: 24.w),
            child: Text(
              "继续编辑",
              style: TextStyle(
                fontSize: 18.w,
                color: "#232535".color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 详情提示
          Padding(
            padding: EdgeInsets.only(top: 17.w),
            child: Text(
              "您上次编辑的草稿未正常保存,且服务器存在一\n份更新的草稿,你要用哪一份继续?",
              style: TextStyle(
                fontSize: 12.w,
                color: "#737373".color,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 20.w),

          // 本地草稿选项
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 17.w),
            child: _buildDraftOption(
              type: DraftType.local,
              label: "本地",
              time: format10TsIntl(widget.localDraftTime),
              onPreview: widget.onLocalPreview,
            ),
          ),

          SizedBox(height: 20.w),

          // 服务器草稿选项
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 17.w),
            child: _buildDraftOption(
              type: DraftType.server,
              label: "服务器",
              time: format10TsIntl(widget.serverDraftTime),
              onPreview: widget.onServerPreview,
            ),
          ),

          SizedBox(height: 44.w),

          // 底部按钮
          Row(
            children: [
              SizedBox(width: 20.w),
              GestureDetector(
                onTap: () {
                  widget.cancelAction?.call();
                  SmartDialog.dismiss();
                },
                child: Container(
                  width: 114.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: "#E8E8E8".color,
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(width: 1, color: "#E6E6E6".color),
                  ),
                  child: Center(
                    child: Text(
                      "取消",
                      style: TextStyle(
                        fontSize: 16.w,
                        color: "#222325".color.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              GestureDetector(
                onTap: () {
                  widget.sureAction?.call();
                  SmartDialog.dismiss();
                },
                child: Container(
                  width: 114.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.w),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3691FF), Color(0xFF8556FF)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "确认",
                      style: TextStyle(
                        fontSize: 16.w,
                        color: "#FFFFFF".color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 26.w),
        ],
      ),
    );
  }

  String format10TsIntl(int ts10) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts10 * 1000).toLocal();
    return DateFormat('yyyy/M/d HH:mm').format(dt);
  }

  Widget _buildDraftOption({
    required DraftType type,
    required String label,
    required String time,
    VoidCallback? onPreview,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        height: 36.w,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? "#DCEDFE".color : "#E8E8E8".color,
          borderRadius: BorderRadius.circular(18.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$label ($time)",
              style: TextStyle(
                fontSize: 12.w,
                color: isSelected
                    ? "#007BFE".color
                    : "#232535".color.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),

            GestureDetector(
              onTap: () {
                onPreview?.call();
              },
              child: Container(
                width: 52.w,
                height: 20.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.w),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFC86CFF), Color(0xFF5B98FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected ? null : "#D8D8D8".color,
                ),
                child: Center(
                  child: Text(
                    "预览",
                    style: TextStyle(
                      fontSize: 12.w,
                      color: isSelected ? "#FFFFFF".color : "#999999".color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
