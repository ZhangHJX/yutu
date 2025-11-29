import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

class ProfileInput extends StatefulWidget {
  final String label;
  final String? hint;
  final Widget? suffix;
  final TextEditingController? controller;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;

  const ProfileInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.suffix,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
  });

  @override
  State<ProfileInput> createState() => _ProfileInputState();
}

class _ProfileInputState extends State<ProfileInput> {
  late TextEditingController _controller;
  bool _disposeController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _disposeController = false;
    } else {
      _controller = TextEditingController();
      _disposeController = true;
    }
  }

  @override
  void didUpdateWidget(covariant ProfileInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_disposeController) {
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _disposeController = false;
      } else {
        _controller = TextEditingController();
        _disposeController = true;
      }
    }
  }

  @override
  void dispose() {
    if (_disposeController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(widget.label, style: const TextStyle(fontSize: 15)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      controller: _controller,
                      readOnly: widget.readOnly,
                      maxLines: widget.maxLines,
                      maxLength: widget.maxLength,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hint,
                        counterText: "",
                      ),
                    ),
                  ),
                  if (widget.suffix != null) widget.suffix!,
                ],
              ),
              if (widget.showCounter && widget.maxLength != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    final current = value.text.characters.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "$current/${widget.maxLength}",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
