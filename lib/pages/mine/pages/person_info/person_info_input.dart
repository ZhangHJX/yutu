import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final void Function(String value) changeValue;

  const ProfileInput({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    required this.changeValue,
  });

  @override
  State<ProfileInput> createState() => _ProfileInputState();
}

class _ProfileInputState extends State<ProfileInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 10.w),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16.w,
                  color: "#232535".color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Spacer(),
            if (widget.readOnly)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  "(已绑定)",
                  style: TextStyle(
                    fontSize: 12.w,
                    color: "#1677FF".color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),

        SizedBox(height: 15),

        Container(
          padding: EdgeInsets.only(
            left: 13.w,
            right: 13.w,
            top: widget.showCounter ? 12.w : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      readOnly: widget.readOnly,
                      maxLines: widget.maxLines,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(widget.maxLength),
                      ],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: "#848484".color,
                          fontSize: 14.w,
                        ),
                      ),
                      style: TextStyle(
                        color: widget.readOnly
                            ? "#848484".color
                            : "#121F33".color,
                      ),
                      onChanged: (value) {
                        widget.changeValue(value);
                      },
                    ),
                  ),
                ],
              ),

              if (widget.showCounter && widget.maxLength != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, child) {
                    final current = value.text.characters.length;
                    return Text(
                      "$current/${widget.maxLength}",
                      style: TextStyle(fontSize: 14.w, color: "#848484".color),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
