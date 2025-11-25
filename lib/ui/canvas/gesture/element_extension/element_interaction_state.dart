import 'package:flutter/material.dart';

class ElementInteractionState {
  Offset? fixedScaleCenter;
  double initialWidth = 0;
  double initialHeight = 0;
  double initialFontSize = 0;

  String? resizingHandle;
  double resizeStartWidth = 0;
  double resizeStartHeight = 0;
  double resizeStartFontSize = 0;
  double resizeStartLineHeight = 1.0;
  double resizeStartFontSpace = 0.0;
  double resizeAspectRatio = 1.0;
  Offset? resizeStartPosition;
  Offset? resizeAnchorPoint;

  Offset? rotateLastPosition;
}
