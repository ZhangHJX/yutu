class ImagePreviewModel {
  ImagePreviewModel({this.imgUrl, this.current = 0, this.list = const []})
    : assert(
        (imgUrl != null && list.isEmpty) || (imgUrl == null && list.isNotEmpty),
        'imgUrl 和 list 不能同时存在，且至少存在一个',
      );

  final String? imgUrl;
  final int current;
  final List<String> list;
}
