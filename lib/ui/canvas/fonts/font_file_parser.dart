import 'dart:io';
import 'package:common/common.dart';
import 'package:flutter/foundation.dart';
import 'font_models.dart';

/// 只负责解析单个 TTF/OTF 文件的 name / OS/2 表
///
/// 实现的是一个非常精简的 TTF/OTF 解析器，只拿：
/// - nameID = 1  (Font Family)
/// - nameID = 2  (Font Subfamily / Style)
/// - OS/2.usWeightClass
class FontFileParser {
  static Future<FontWeightMeta?> parseFontFile({
    required File file,
    required Directory rootDir,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes < 100) return null;
    final bd = ByteData.sublistView(bytes);

    // 1. 读取 offset table
    final numTables = _readUint16(bd, 4);
    int nameOffset = -1;
    int nameLength = 0;
    int os2Offset = -1;

    // 2. 遍历 table directory
    const tableDirStart = 12;
    const tableRecordSize = 16;
    for (int i = 0; i < numTables; i++) {
      final recordOffset = tableDirStart + i * tableRecordSize;
      final tag = _readTag(bd, recordOffset);
      final offset = _readUint32(bd, recordOffset + 8);
      final length = _readUint32(bd, recordOffset + 12);

      if (tag == 'name') {
        nameOffset = offset;
        nameLength = length;
      } else if (tag == 'OS/2') {
        os2Offset = offset;
      }
    }

    if (nameOffset <= 0) {
      debugPrint('FontFileParser: no name table in ${file.path}');
      return null;
    }

    final (familyName, styleName) =
        _parseNameTable(bd, nameOffset, nameLength) ?? ('Unknown', 'Regular');

    final weight = os2Offset > 0 ? _parseOs2Weight(bd, os2Offset) : 400;

    // 保存字体文件相对于安装根目录的路径，后续用于加载字体文件
    final relativePath = relative(file.path, from: rootDir.path);

    return FontWeightMeta(
      relativePath: relativePath,
      familyName: familyName,
      styleName: styleName,
      weight: weight,
    );
  }

  static (String, String)? _parseNameTable(
    ByteData bd,
    int nameOffset,
    int nameLength,
  ) {
    if (nameOffset + 6 > bd.lengthInBytes) return null;
    final count = _readUint16(bd, nameOffset + 2);
    final stringOffset = _readUint16(bd, nameOffset + 4);

    String? familyName;
    String? subfamilyName;

    for (int i = 0; i < count; i++) {
      final recOffset = nameOffset + 6 + i * 12;
      if (recOffset + 12 > bd.lengthInBytes) break;

      final nameId = _readUint16(bd, recOffset + 6);
      final length = _readUint16(bd, recOffset + 8);
      final offset = _readUint16(bd, recOffset + 10);

      if (nameId != 1 && nameId != 2) continue;
      final strStart = nameOffset + stringOffset + offset;
      final strEnd = strStart + length;
      if (strEnd > bd.lengthInBytes) continue;

      final raw = bd.buffer.asUint8List(strStart, length);
      // name 表通常使用 UTF-16BE
      String decoded;
      try {
        decoded = _decodeUtf16Be(raw);
      } catch (_) {
        decoded = String.fromCharCodes(raw);
      }

      decoded = decoded.trim();
      if (decoded.isEmpty) continue;

      if (nameId == 1 && familyName == null) {
        familyName = decoded;
      } else if (nameId == 2 && subfamilyName == null) {
        subfamilyName = decoded;
      }

      if (familyName != null && subfamilyName != null) break;
    }

    if (familyName == null && subfamilyName == null) return null;
    return (familyName ?? 'Unknown', subfamilyName ?? 'Regular');
  }

  static int _parseOs2Weight(ByteData bd, int os2Offset) {
    // OS/2 表结构中，usWeightClass 为第 4 个字段，偏移 4*2 = 8
    if (os2Offset + 10 > bd.lengthInBytes) return 400;
    final weight = _readUint16(bd, os2Offset + 8);
    if (weight < 100 || weight > 900) return 400;
    return weight;
  }

  static int _readUint16(ByteData bd, int offset) =>
      bd.getUint16(offset, Endian.big);

  static int _readUint32(ByteData bd, int offset) =>
      bd.getUint32(offset, Endian.big);

  static String _readTag(ByteData bd, int offset) {
    final bytes = Uint8List(4);
    for (int i = 0; i < 4; i++) {
      bytes[i] = bd.getUint8(offset + i);
    }
    return String.fromCharCodes(bytes);
  }
}

String _decodeUtf16Be(List<int> input) {
  if (input.length.isOdd) {
    input = input.sublist(0, input.length - 1);
  }
  final bd = ByteData.sublistView(Uint8List.fromList(input));
  final codeUnits = <int>[];
  for (int i = 0; i < bd.lengthInBytes; i += 2) {
    codeUnits.add(bd.getUint16(i, Endian.big));
  }
  return String.fromCharCodes(codeUnits);
}
