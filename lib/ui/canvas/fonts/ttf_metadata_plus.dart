import 'dart:io';
import 'dart:typed_data';

class TTfMetadataPlus {
  /// OS/2.usWeightClass（100~900，已规范化到 Flutter 可用范围）
  final int weight;

  /// ✅ Style name（优先 nameID=17，其次 nameID=2；必要时从 nameID=6 推导）
  final String? styleName;

  /// PostScript name（nameID=6）
  final String? postScriptName;

  const TTfMetadataPlus({
    required this.weight,
    this.styleName,
    this.postScriptName,
  });

  static Future<TTfMetadataPlus> fromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const TTfMetadataPlus(weight: 400);
    }

    final bytes = await file.readAsBytes();
    return fromBytes(bytes);
  }

  static TTfMetadataPlus fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const TTfMetadataPlus(weight: 400);
    }

    final data = ByteData.sublistView(bytes);

    final int normalizedWeight = _normalizeWeightClass(
      _readOs2WeightClass(data),
    );
    final bool italic =
        _readOs2IsItalic(data) ?? _readHeadMacStyleIsItalic(data) ?? false;

    final _NameTable nameTable = _readNameTable(data);

    final String? family =
        _normalizeName(nameTable.typographicFamilyName) ??
        _normalizeName(nameTable.familyName);

    final String? styleCandidate =
        _normalizeName(nameTable.typographicSubfamilyName) ??
        _normalizeName(nameTable.subfamilyName);

    final String? psName = _normalizeName(nameTable.postScriptName);

    final String? resolvedStyleName = _resolveStyleName(
      familyName: family,
      styleCandidate: styleCandidate,
      postScriptName: psName,
      weight: normalizedWeight,
      isItalic: italic,
    );

    return TTfMetadataPlus(
      weight: normalizedWeight,
      styleName: resolvedStyleName,
      postScriptName: psName,
    );
  }

  static String? _normalizeName(String? value) {
    if (value == null) return null;
    final String v = value.trim();
    if (v.isEmpty) return null;
    return v.replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// ------- style resolve（核心） -------

String? _resolveStyleName({
  required String? familyName,
  required String? styleCandidate,
  required String? postScriptName,
  required int weight,
  required bool isItalic,
}) {
  final String? family = _normalizeForCompare(familyName);
  final String? candidate = _normalizeForCompare(styleCandidate);

  // 1) candidate 可用且不等于 family → 直接用
  if (styleCandidate != null &&
      styleCandidate.trim().isNotEmpty &&
      (family == null || candidate == null || family != candidate)) {
    return styleCandidate.trim();
  }

  // 2) candidate 为空或等于 family → 从 PostScriptName 推导
  final String? inferredFromPs = _inferStyleFromPostScript(postScriptName);
  if (inferredFromPs != null && inferredFromPs.isNotEmpty) {
    return inferredFromPs;
  }

  // 3) 兜底：用 weight 推一个标准名
  return _inferStyleFromWeight(weight, isItalic: isItalic);
}

String? _normalizeForCompare(String? value) {
  if (value == null) return null;
  final String v = value.trim();
  if (v.isEmpty) return null;
  return v.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}

/// PostScript 示例：AlibabaPuHuiTi_3_115_Black -> Black
///             AlibabaPuHuiTi_3_55_Regular_L3 -> Regular L3
String? _inferStyleFromPostScript(String? postScriptName) {
  if (postScriptName == null) return null;
  final String ps = postScriptName.trim();
  if (ps.isEmpty) return null;

  final List<String> parts = ps
      .split('_')
      .where((e) => e.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;

  int lastNumericIndex = -1;
  for (int i = 0; i < parts.length; i++) {
    if (_isNumeric(parts[i])) {
      lastNumericIndex = i;
    }
  }

  final List<String> styleParts =
      (lastNumericIndex != -1 && lastNumericIndex < parts.length - 1)
      ? parts.sublist(lastNumericIndex + 1)
      : (parts.length >= 2 ? parts.sublist(1) : parts);

  String style = styleParts.join(' ').trim();
  if (style.isEmpty) return null;

  return _prettyStyleName(style);
}

bool _isNumeric(String s) {
  final String v = s.trim();
  if (v.isEmpty) return false;
  return RegExp(r'^\d+$').hasMatch(v);
}

String _prettyStyleName(String style) {
  var s = style.trim();
  if (s.isEmpty) return s;

  // ExtraBold -> Extra Bold
  s = s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');

  // RegularL3 -> Regular L3
  s = s.replaceAllMapped(RegExp(r'([A-Za-z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');

  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

String _inferStyleFromWeight(int weight, {required bool isItalic}) {
  String base;
  switch (weight) {
    case 100:
      base = 'Thin';
      break;
    case 200:
      base = 'ExtraLight';
      break;
    case 300:
      base = 'Light';
      break;
    case 400:
      base = 'Regular';
      break;
    case 500:
      base = 'Medium';
      break;
    case 600:
      base = 'SemiBold';
      break;
    case 700:
      base = 'Bold';
      break;
    case 800:
      base = 'ExtraBold';
      break;
    case 900:
      base = 'Black';
      break;
    default:
      base = 'W$weight';
      break;
  }

  if (!isItalic) return base;
  return '$base Italic';
}

/// ------- OS/2 weight / italic -------

int _normalizeWeightClass(int? raw) {
  if (raw == null || raw <= 0) return 400;

  int value = raw;

  // round 到 100 桶
  value = ((value + 50) ~/ 100) * 100;

  // clamp 到 100~900
  if (value < 100) value = 100;
  if (value > 900) value = 900;

  return value;
}

/// OS/2 表：version(2) + xAvgCharWidth(2) + usWeightClass(2) => offset +4
int? _readOs2WeightClass(ByteData data) {
  final int? os2Offset = _findTableOffset(data, 'OS/2');
  if (os2Offset == null) return null;
  if (os2Offset + 6 > data.lengthInBytes) return null;
  return data.getUint16(os2Offset + 4);
}

/// 读取 OS/2.fsSelection 的 italic 位（bit 0）
bool? _readOs2IsItalic(ByteData data) {
  final int? os2Offset = _findTableOffset(data, 'OS/2');
  if (os2Offset == null) return null;

  const int fsSelectionOffset = 62;
  if (os2Offset + fsSelectionOffset + 2 > data.lengthInBytes) return null;

  final int fsSelection = data.getUint16(os2Offset + fsSelectionOffset);
  return (fsSelection & 0x0001) != 0;
}

/// head.macStyle bit1（Italic）
bool? _readHeadMacStyleIsItalic(ByteData data) {
  final int? headOffset = _findTableOffset(data, 'head');
  if (headOffset == null) return null;

  const int macStyleOffset = 44;
  if (headOffset + macStyleOffset + 2 > data.lengthInBytes) return null;

  final int macStyle = data.getUint16(headOffset + macStyleOffset);
  return (macStyle & 0x0002) != 0;
}

/// ------- SFNT table offset -------

int? _findTableOffset(ByteData data, String tag) {
  if (data.lengthInBytes < 12) return null;

  final int numTables = data.getUint16(4);
  const int tableDir = 12;

  for (int i = 0; i < numTables; i++) {
    final int entry = tableDir + i * 16;
    if (entry + 16 > data.lengthInBytes) return null;

    final String t = String.fromCharCodes([
      data.getUint8(entry),
      data.getUint8(entry + 1),
      data.getUint8(entry + 2),
      data.getUint8(entry + 3),
    ]);

    if (t != tag) continue;

    final int offset = data.getUint32(entry + 8);
    if (offset >= data.lengthInBytes) return null;
    return offset;
  }

  return null;
}

/// ------- name table -------

class _NameTable {
  final String? familyName; // nameID 1
  final String? subfamilyName; // nameID 2
  final String? postScriptName; // nameID 6
  final String? typographicFamilyName; // nameID 16
  final String? typographicSubfamilyName; // nameID 17

  const _NameTable({
    this.familyName,
    this.subfamilyName,
    this.postScriptName,
    this.typographicFamilyName,
    this.typographicSubfamilyName,
  });
}

_NameTable _readNameTable(ByteData data) {
  final int? nameOffset = _findTableOffset(data, 'name');
  if (nameOffset == null) return const _NameTable();
  if (nameOffset + 6 > data.lengthInBytes) return const _NameTable();

  final int count = data.getUint16(nameOffset + 2);
  final int stringStorageOffset = nameOffset + data.getUint16(nameOffset + 4);

  _BestNameCandidate? fam1;
  _BestNameCandidate? sub2;
  _BestNameCandidate? ps6;
  _BestNameCandidate? fam16;
  _BestNameCandidate? sub17;

  for (int i = 0; i < count; i++) {
    final int recordOffset = nameOffset + 6 + i * 12;
    if (recordOffset + 12 > data.lengthInBytes) break;

    final int platformId = data.getUint16(recordOffset);
    final int encodingId = data.getUint16(recordOffset + 2);
    final int languageId = data.getUint16(recordOffset + 4);
    final int nameId = data.getUint16(recordOffset + 6);
    final int length = data.getUint16(recordOffset + 8);
    final int offset = data.getUint16(recordOffset + 10);

    final int strPos = stringStorageOffset + offset;
    if (length <= 0) continue;
    if (strPos + length > data.lengthInBytes) continue;

    final String? decoded = _decodeNameString(
      data: data,
      offset: strPos,
      length: length,
      platformId: platformId,
      encodingId: encodingId,
    );
    if (decoded == null || decoded.trim().isEmpty) continue;

    final candidate = _BestNameCandidate(
      value: decoded.trim(),
      platformId: platformId,
      encodingId: encodingId,
      languageId: languageId,
    );

    switch (nameId) {
      case 1:
        fam1 = _pickBetter(fam1, candidate);
        break;
      case 2:
        sub2 = _pickBetter(sub2, candidate);
        break;
      case 6:
        ps6 = _pickBetter(ps6, candidate);
        break;
      case 16:
        fam16 = _pickBetter(fam16, candidate);
        break;
      case 17:
        sub17 = _pickBetter(sub17, candidate);
        break;
      default:
        break;
    }
  }

  return _NameTable(
    familyName: fam1?.value,
    subfamilyName: sub2?.value,
    postScriptName: ps6?.value,
    typographicFamilyName: fam16?.value,
    typographicSubfamilyName: sub17?.value,
  );
}

class _BestNameCandidate {
  final String value;
  final int platformId;
  final int encodingId;
  final int languageId;

  const _BestNameCandidate({
    required this.value,
    required this.platformId,
    required this.encodingId,
    required this.languageId,
  });
}

/// 选择更优的 name 记录：
/// 1) 平台优先：Windows(3) > Unicode(0) > Mac(1)
/// 2) 语言优先：zh-CN(0x0804) > en-US(0x0409) > 其他
_BestNameCandidate _pickBetter(
  _BestNameCandidate? current,
  _BestNameCandidate next,
) {
  if (current == null) return next;

  final int nextScore = _nameRecordScore(next);
  final int currentScore = _nameRecordScore(current);

  if (nextScore > currentScore) return next;
  return current;
}

int _nameRecordScore(_BestNameCandidate c) {
  int score = 0;

  if (c.platformId == 3) score += 300;
  if (c.platformId == 0) score += 200;
  if (c.platformId == 1) score += 100;

  // 中文优先，其次英文
  if (c.languageId == 0x0804) score += 50; // zh-CN
  if (c.languageId == 0x0409) score += 30; // en-US

  if (c.platformId == 3 && c.encodingId == 1) score += 5;

  return score;
}

String? _decodeNameString({
  required ByteData data,
  required int offset,
  required int length,
  required int platformId,
  required int encodingId,
}) {
  if (offset < 0 || length <= 0 || offset + length > data.lengthInBytes) {
    return null;
  }

  final Uint8List bytes = data.buffer.asUint8List(
    data.offsetInBytes + offset,
    length,
  );

  if (platformId == 0 || platformId == 3) {
    if (bytes.length.isOdd) return null;
    final List<int> codeUnits = <int>[];
    for (int i = 0; i < bytes.length; i += 2) {
      codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(codeUnits);
  }

  if (platformId == 1) {
    return String.fromCharCodes(bytes);
  }

  return String.fromCharCodes(bytes);
}
