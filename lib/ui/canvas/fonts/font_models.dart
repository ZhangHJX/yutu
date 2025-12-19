import 'dart:convert';

/// 字体当前状态
/// - [missing]   ：本地没有，需要下载
/// - [downloading]：正在通过 background_downloader 下载 zip
/// - [installing]：已下载，正在解压/解析/安装（Isolate 中执行）
/// - [ready]     ：已安装，可直接使用
/// - [failed]    ：下载或安装失败
enum FontStatus { missing, downloading, installing, ready, failed }

/// 单个字重的信息（解析自 name + OS/2）
class FontWeightMeta {
  /// 字体文件相对目录（相对于 font 安装目录）
  final String relativePath;

  /// familyName
  final String familyName;

  /// familyName
  final String styleName;

  /// OS/2 表中的 usWeightClass（100~900）
  final int weight;

  const FontWeightMeta({
    required this.relativePath,
    required this.familyName,
    required this.styleName,
    this.weight = 400,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'relativePath': relativePath,
    'familyName': familyName,
    'styleName': styleName,
    'weight': weight,
  };

  factory FontWeightMeta.fromJson(Map<String, dynamic> json) => FontWeightMeta(
    relativePath: json['relativePath'] as String,
    familyName: json['familyName'] as String,
    styleName: json['styleName'] as String,
    weight: json['weight'] as int,
  );
}

/// 单个 fontId 的完整 meta 信息； 一个 fontId 下可能有多个字重（多个 ttf/otf 文件）
/// meta.json 的整体结构（后续如需版本迁移，可在此处扩展）
class FontFamilyMeta {
  /// 业务侧 fontId（来自模板/接口）
  final int fontId;

  /// 业务侧版本号，避免旧 zip 叠加
  final String version;

  /// 推荐展示的系列名  font_fontId_v$version
  final String familyKey;

  /// 已解析的所有字重
  final List<FontWeightMeta> weights;

  const FontFamilyMeta({
    required this.fontId,
    required this.version,
    required this.familyKey,
    required this.weights,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fontId': fontId,
    'version': version,
    'familyKey': familyKey,
    'weights': weights.map((e) => e.toJson()).toList(),
  };

  factory FontFamilyMeta.fromJson(Map<String, dynamic> json) => FontFamilyMeta(
    fontId: json['fontId'] as int,
    version: json['version'] as String,
    familyKey: json['familyKey'] as String,
    weights: (json['weights'] as List<dynamic>)
        .map((e) => FontWeightMeta.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );

  String encode() => jsonEncode(toJson());

  static FontFamilyMeta decode(String source) =>
      FontFamilyMeta.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
