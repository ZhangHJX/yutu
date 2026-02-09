class PickerInfoModel {
  /// 主键 id，0 表示新记录
  int id;
  String fileName;
  String filePath;
  double width;
  double height;
  int fileSize;
  String hashValue;

  PickerInfoModel({
    this.id = 0,
    this.fileName = '',
    this.filePath = '',
    this.width = 0.0,
    this.height = 0.0,
    this.fileSize = 0,
    this.hashValue = '',
  });

  /// 从 PickerInfoModel 创建（不包含 filePath）
  factory PickerInfoModel.fromPickerInfo(PickerInfoModel picker) {
    return PickerInfoModel(
      fileName: picker.fileName,
      width: picker.width,
      height: picker.height,
      fileSize: picker.fileSize,
      hashValue: picker.hashValue,
    );
  }

  factory PickerInfoModel.fromMap(Map<String, dynamic> map) {
    return PickerInfoModel(
      id: map['pk'] as int? ?? 0,
      fileName: map['fileName'] as String? ?? '',
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      fileSize: map['fileSize'] as int? ?? 0,
      hashValue: map['hashValue'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'hashValue': hashValue,
    };
  }
}
