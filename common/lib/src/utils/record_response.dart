import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class RecordResponse {
  factory RecordResponse() {
    _instance ??= RecordResponse._internal();
    return _instance!;
  }

  RecordResponse._internal();

  static RecordResponse? _instance;

  static const String mockDirName = 'mock';

  bool _enableRecording = kDebugMode;

  String? _manualProjectRoot;

  void setRecordingEnabled(bool enabled) {
    _enableRecording = enabled && kDebugMode;
  }

  bool get isRecordingEnabled => _enableRecording;

  void setProjectRoot(String projectRootPath) {
    _manualProjectRoot = projectRootPath;
    _logSuccess('手动设置项目根目录: $projectRootPath');
  }

  Future<void> saveResponse({
    required String requestPath,
    required dynamic responseData,
    String method = 'GET',
    Map<String, dynamic>? queryParams,
  }) async {
    if (!_enableRecording) {
      return;
    }

    try {
      final projectRoot = _manualProjectRoot;
      if (projectRoot == null) {
        // _logError('无法找到项目根目录，当前目录: ${Directory.current.path}');
        return;
      }

      final mockDir = Directory(path.join(projectRoot, mockDirName));
      if (!await mockDir.exists()) {
        await mockDir.create(recursive: true);
        _logSuccess('创建mock目录: ${mockDir.path}');
      }

      final fileName = _generateFileName(requestPath, method, queryParams);
      final filePath = path.join(mockDir.path, fileName);

      final file = File(filePath);
      final fileExists = await file.exists();

      final jsonString = _formatJsonData(responseData);

      await file.writeAsString(jsonString);

      if (fileExists) {
        _logSuccess('已覆写现有文件: $fileName');
      } else {
        _logSuccess('已创建新文件: $fileName');
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> clearMockData() async {
    try {
      final projectRoot = _manualProjectRoot;
      if (projectRoot == null) {
        return;
      }

      final mockDir = Directory(path.join(projectRoot, mockDirName));
      if (await mockDir.exists()) {
        await mockDir.delete(recursive: true);
        await mockDir.create();
        _logSuccess('Mock数据已清空');
      }
    } catch (e) {
      _logError('清空mock数据失败: $e');
    }
  }

  String _generateFileName(String requestPath, String method, Map<String, dynamic>? queryParams) {
    var cleanPath = requestPath.startsWith('/') ? requestPath.substring(1) : requestPath;

    cleanPath = cleanPath
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll('/', '_')
        .replaceAll(' ', '_');

    var fileName = '${method.toLowerCase()}_$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final paramHash = queryParams.toString().hashCode.abs().toString();
      fileName += '_$paramHash';
    }

    return '$fileName.json';
  }

  String _formatJsonData(dynamic data) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (e) {
      return data.toString();
    }
  }

  void _logSuccess(String message) {
    if (kDebugMode) {
      print('🎉 [RecordResponse] $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('❌ [RecordResponse] $message');
    }
  }
}

final recordResponse = RecordResponse();

Future<void> clearMockData() async {
  if (kDebugMode) {
    await recordResponse.clearMockData();
  }
}
