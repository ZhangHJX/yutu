# 日志系统使用说明

## 初始化

在应用启动时初始化日志系统：

```dart
import 'package:common/common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志系统
  await AppLogger.instance.init();
  
  runApp(MyApp());
}
```

## 基本使用

日志系统提供了简单的 API，开发者只需要传入字符串，系统会自动拼接时间：

```dart
import 'package:common/common.dart';

// Debug 日志
AppLogger.instance.d('这是一条调试日志');

// Info 日志
AppLogger.instance.i('这是一条信息日志');

// Warning 日志
AppLogger.instance.w('这是一条警告日志');

// Error 日志
AppLogger.instance.e('这是一条错误日志');

// Error 日志（带异常信息）
AppLogger.instance.e('操作失败', error, stackTrace);

// Fatal 日志
AppLogger.instance.f('这是一条致命错误日志', error, stackTrace);
```

## 日志行为

- **Debug 模式**：日志会同时输出到控制台和文件
- **Release 模式**：日志只写入到文件，不输出到控制台
- **时间戳**：每条日志都会自动添加时间戳，格式：`[YYYY-MM-DD HH:mm:ss.SSS] [LEVEL] message`
- **文件切分**：系统会自动管理日志文件，最多保留 5 个文件，总大小不超过 5MB
- **文件命名**：日志文件名格式为 `YYYYMMDDHHmmss.log`（创建时间的年月日时分秒）

## 日志上报

### 方式一：打包为 zip 后上传

```dart
import 'package:common/common.dart';

// 打包日志文件
final zipPath = await LogUploader.instance.packLogsToZip();
if (zipPath != null) {
  // 上传 zip 文件
  // 例如使用 dio 上传
  // await dio.post('/upload', data: FormData.fromMap({'file': await MultipartFile.fromFile(zipPath)}));
}

// 或者使用封装好的上传方法
final success = await LogUploader.instance.uploadLogs(
  uploadCallback: (zipPath) async {
    // 实现你的上传逻辑
    // 返回 true 表示上传成功，false 表示失败
    return true;
  },
);
```

### 方式二：直接上传多个文件

```dart
import 'package:common/common.dart';

final success = await LogUploader.instance.uploadLogFilesDirectly(
  uploadCallback: (filePaths) async {
    // 实现你的上传逻辑，filePaths 是所有日志文件的路径列表
    // 返回 true 表示上传成功，false 表示失败
    return true;
  },
);
```

## 日志文件位置

日志文件存储在：`getApplicationSupportDirectory()/logs/`

可以通过以下方式获取日志目录：

```dart
final logDir = await FileLogManager.instance.getLogDirectory();
```

## 注意事项

1. 日志写入是异步的，但使用了 `flush: true` 确保数据及时刷新到磁盘
2. 系统会自动清理旧日志文件，无需手动管理
3. 日志文件按创建时间命名，便于识别和管理
