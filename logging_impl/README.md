# logging_impl

日志实现库，基于 `logger: ^2.6.2` 和 `AdvancedFileOutput`。

## 功能特性

- ✅ 支持 info 和 error 两个日志级别
- ✅ Debug 模式：输出到控制台（美化格式）
- ✅ Release 模式：写入到文件（SupportDirectory）
- ✅ 自动文件轮转：总大小不超过 5MB，最多保留 10 个文件（app.log, app.1.log, ..., app.9.log）
- ✅ 自动时间戳：开发者只需传入消息字符串
- ✅ 提供日志路径查询接口

## 使用方法

### 1. 初始化

在应用启动时（如 `main.dart`）初始化日志系统：

```dart
import 'package:logging_impl/logging_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志系统
  await AppLogger.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. 记录日志

#### Info 日志

```dart
import 'package:logging_impl/logging_impl.dart';

// 记录 info 级别日志（时间戳会自动添加）
AppLogger.instance.info('用户登录成功');
AppLogger.instance.info('数据加载完成，共 ${count} 条记录');
```

#### Error 日志

```dart
import 'package:logging_impl/logging_impl.dart';

// 记录 error 级别日志
AppLogger.instance.error('网络请求失败');

// 带错误对象
try {
  // some code
} catch (e) {
  AppLogger.instance.error('处理数据时发生错误', error: e);
}

// 带错误对象和堆栈跟踪
try {
  // some code
} catch (e, stackTrace) {
  AppLogger.instance.error(
    '处理数据时发生错误',
    error: e,
    stackTrace: stackTrace,
  );
}
```

### 3. 获取日志路径

```dart
// 获取当前日志文件路径
final logPath = AppLogger.instance.getLogPath();
print('日志文件路径: $logPath');

// 获取日志目录路径
final logDirPath = AppLogger.instance.getLogDirectoryPath();
print('日志目录路径: $logDirPath');
```

## 日志格式

### Debug 模式（控制台输出）

```
💡 [2025-01-26 10:30:45] 用户登录成功
```

### Release 模式（文件输出）

```
[INFO] [2025-01-26 10:30:45] 用户登录成功
[ERROR] [2025-01-26 10:30:46] 网络请求失败
Error: Connection timeout
```

## 文件轮转策略

- **当前文件**：`app.log`（正在写入）
- **历史文件**：`app.1.log`、`app.2.log`、...、`app.9.log`（按时间倒序，最多9个历史文件）
- **总大小限制**：5MB（所有10个文件的总大小）
- **轮转规则**：当总大小超过 5MB 时：
  1. 删除最老的 `app.9.log`
  2. `app.8.log` → `app.9.log`
  3. `app.7.log` → `app.8.log`
  4. ...（依次向后移动）
  5. `app.1.log` → `app.2.log`
  6. `app.log` → `app.1.log`
  7. 创建新的空 `app.log`

## 日志存储位置

日志文件保存在应用的 SupportDirectory 下的 `logs` 目录：

- **Android**: `/data/data/<package_name>/app_flutter/logs/`
- **iOS**: `<AppContainer>/Library/Application Support/logs/`

## 性能优化

日志系统经过性能优化，确保不会影响应用操作的流畅度：

1. **非阻塞设计**：
   - 日志写入优先，轮转检查异步执行
   - 所有文件IO操作都是异步的，不阻塞主线程

2. **智能检查策略**：
   - **快速检查**（每10秒）：只检查当前文件大小，轻量级操作
   - **完整检查**（每30秒）：检查所有文件总大小，仅在快速检查通过时执行

3. **并行IO操作**：
   - 文件大小检查使用并行读取，减少等待时间
   - 轮转操作中的删除和重命名并行执行

4. **防并发保护**：
   - 使用标志位防止并发轮转操作
   - 正在轮转时跳过新的检查请求

5. **字符串优化**：
   - 使用 StringBuffer 优化时间戳格式化
   - 减少字符串拼接开销

## 注意事项

1. **初始化时机**：必须在首次使用日志功能前调用 `initialize()`
2. **时间戳**：时间戳会自动添加，开发者只需传入消息字符串
3. **日志级别**：只支持 info 和 error，其他级别会被过滤
4. **文件轮转**：轮转检查采用智能策略，快速检查每10秒，完整检查每30秒
5. **错误处理**：如果文件操作失败，系统会降级到控制台输出，确保日志功能可用
6. **性能保证**：日志系统设计为非阻塞，不会影响应用操作的流畅度
