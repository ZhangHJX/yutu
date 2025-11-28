import 'package:flutter/material.dart';

class ProfileInput extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget? suffix;
  final TextEditingController? controller;
  final bool readonly;
  final int maxLines;
  final int? maxLength;

  const ProfileInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.suffix,
    this.readonly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readonly,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    counterText: "",
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
  }
}
