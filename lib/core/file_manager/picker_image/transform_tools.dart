import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TransformTools {
  static Future<Uint8List?> gifToPngFrame(
    Uint8List gifBytes, {
    int frameIndex = 0,
  }) async {
    // 直接解码指定帧，而不是解码整个动画
    final frameImage = img.decodeGif(gifBytes, frame: frameIndex);
    if (frameImage == null) {
      return null;
    }

    return Uint8List.fromList(img.encodePng(frameImage));
  }
}
