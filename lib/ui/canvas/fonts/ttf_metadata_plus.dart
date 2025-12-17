import 'dart:io';
import 'package:flutter/services.dart';
import 'package:common/common.dart';

class TTfMetadataPlus {
  final TtfMetadata metrics;

  /// OS/2.usWeightClass（100~900）
  final int weight;

  const TTfMetadataPlus({required this.metrics, required this.weight});

  static Future<TTfMetadataPlus> fromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      final metrics = TtfMetadata(TtfFileSource(path: path));
      return TTfMetadataPlus(metrics: metrics, weight: 400);
    }

    final bytes = await file.readAsBytes();
    return fromBytes(bytes, metrics: TtfMetadata(TtfFileSource(path: path)));
  }

  static TTfMetadataPlus fromBytes(
    Uint8List bytes, {
    required TtfMetadata metrics,
  }) {
    final data = ByteData.sublistView(bytes);
    final os2Weight = _readOs2WeightClass(data);

    return TTfMetadataPlus(metrics: metrics, weight: os2Weight ?? 400);
  }
}

/// OS/2 表：version(2) + xAvgCharWidth(2) + usWeightClass(2) => offset +4
int? _readOs2WeightClass(ByteData data) {
  final os2Offset = _findTableOffset(data, 'OS/2');
  if (os2Offset == null) {
    return null;
  }
  if (os2Offset + 6 > data.lengthInBytes) {
    return null;
  }
  return data.getUint16(os2Offset + 4);
}

int? _findTableOffset(ByteData data, String tag) {
  if (data.lengthInBytes < 12) {
    return null;
  }

  final numTables = data.getUint16(4);
  final tableDir = 12;

  for (var i = 0; i < numTables; i++) {
    final entry = tableDir + i * 16;
    if (entry + 16 > data.lengthInBytes) {
      return null;
    }

    final t = String.fromCharCodes([
      data.getUint8(entry),
      data.getUint8(entry + 1),
      data.getUint8(entry + 2),
      data.getUint8(entry + 3),
    ]);

    if (t != tag) {
      continue;
    }

    final offset = data.getUint32(entry + 8);
    if (offset >= data.lengthInBytes) {
      return null;
    }
    return offset;
  }

  return null;
}
