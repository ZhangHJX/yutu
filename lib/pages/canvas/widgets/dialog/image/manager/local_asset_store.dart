import 'package:sqflite/sqflite.dart';
import 'package:voicetemplate/core/file_manager/directory_path/index.dart';
import 'package:voicetemplate/core/file_manager/picker_image/picker_info_model.dart';
import 'package:path/path.dart' as p;
import 'package:common/common.dart' hide Database;

/// SQLite Store 管理类
/// 负责素材数据（PickerInfoModel 除 filePath 外字段）的存储、更新、删除等操作
class LocalAssetStore {
  LocalAssetStore._();
  static LocalAssetStore? _instance;
  static LocalAssetStore get instance {
    _instance ??= LocalAssetStore._();
    return _instance!;
  }

  Database? _database;
  bool _isInitialized = false;
  static const String _tableName = 'localAsset';
  static const int _version = 1;

  /// 初始化数据库
  Future<void> init() async {
    if (_isInitialized && _database != null) {
      AppLogger.info('LocalAssetStore: 已经初始化，跳过');
      return;
    }

    try {
      final supportDir = await DirectoryManager.getSupportDirectory();
      final dbDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'localAsset',
      );

      final dbPath = p.join(dbDir.path, 'localAsset.db');

      _database = await openDatabase(
        dbPath,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _isInitialized = true;
      AppLogger.info('LocalAssetStore: 初始化成功, 数据库路径: $dbPath');
    } catch (e, stackTrace) {
      AppLogger.error('LocalAssetStore: 初始化失败:', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        pk INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        fileSize INTEGER NOT NULL,
        hashValue TEXT NOT NULL
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_hashValue ON $_tableName(hashValue)
    ''');
    await db.execute('''
      CREATE INDEX idx_fileName ON $_tableName(fileName)
    ''');

    AppLogger.info('LocalAssetStore: 数据库表创建成功');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('LocalAssetStore: 数据库升级: $oldVersion -> $newVersion, 重建表结构');
    await db.execute('DROP TABLE IF EXISTS $_tableName');
    await _onCreate(db, newVersion);
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _database == null) {
      await init();
    }
  }

  /// 根据 hashValue 数组查询库中已存在的 hashValue
  /// 返回在 [hashValues] 中且表中已有记录的 hashValue 列表
  Future<List<String>> getExistingHashValues(List<String> hashValues) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }
    if (hashValues.isEmpty) return [];

    try {
      final placeholders = List.filled(hashValues.length, '?').join(',');
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        columns: ['hashValue'],
        where: 'hashValue IN ($placeholders)',
        whereArgs: hashValues,
      );
      return maps
          .map((m) => m['hashValue'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      AppLogger.error('LocalAssetStore: getExistingHashValues 失败:', e);
      return [];
    }
  }

  /// 保存素材数据
  /// [model] PickerInfoModel 数据（不含 filePath）
  /// 若 fileName 已存在则更新，否则插入新记录
  Future<bool> save(PickerInfoModel model) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }

    try {
      if (model.fileName.isNotEmpty) {
        final existing = await getByFileName(model.fileName);
        if (existing != null) {
          AppLogger.info('LocalAssetStore: 更新记录, fileName=${model.fileName}');
          return await update(model);
        }
      }

      await _database!.insert(
        _tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info('LocalAssetStore: 保存成功');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('LocalAssetStore: 保存失败:', e, stackTrace);
      return false;
    }
  }

  /// 更新素材数据
  /// 根据 fileName 更新记录
  Future<bool> update(PickerInfoModel model) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }

    try {
      if (model.fileName.isEmpty) {
        AppLogger.info('LocalAssetStore: fileName 为空，无法更新');
        return false;
      }

      final count = await _database!.update(
        _tableName,
        model.toMap(),
        where: 'fileName = ?',
        whereArgs: [model.fileName],
      );
      final success = count > 0;
      if (success) {
        AppLogger.info('LocalAssetStore: 更新成功, fileName=${model.fileName}');
      } else {
        AppLogger.info(
          'LocalAssetStore: 更新失败，记录不存在, fileName=${model.fileName}',
        );
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('LocalAssetStore: 更新失败: ', e, stackTrace);
      return false;
    }
  }

  /// 根据 fileName 删除
  Future<bool> deleteByFileName(String fileName) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }

    try {
      if (fileName.isEmpty) {
        AppLogger.info('LocalAssetStore: fileName 为空，无法删除');
        return false;
      }

      final count = await _database!.delete(
        _tableName,
        where: 'fileName = ?',
        whereArgs: [fileName],
      );
      final success = count > 0;
      if (success) {
        AppLogger.info('LocalAssetStore: 删除成功, fileName=$fileName');
      } else {
        AppLogger.info('LocalAssetStore: 删除失败，记录不存在, fileName=$fileName');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('LocalAssetStore: 删除失败: ', e, stackTrace);
      return false;
    }
  }

  /// 根据 fileName 获取
  Future<PickerInfoModel?> getByFileName(String fileName) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }

    try {
      if (fileName.isEmpty) {
        return null;
      }

      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'fileName = ?',
        whereArgs: [fileName],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return PickerInfoModel.fromMap(maps.first);
    } catch (e) {
      AppLogger.error('LocalAssetStore: 获取失败:', e);
      return null;
    }
  }

  /// 获取所有记录
  Future<List<PickerInfoModel>> getAll() async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        orderBy: 'pk DESC',
      );
      return maps.map((map) => PickerInfoModel.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('LocalAssetStore: 获取所有记录失败:', e);
      return [];
    }
  }

  /// 清空所有记录
  Future<bool> clearAll() async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('LocalAssetStore: 数据库未初始化');
    }
    try {
      await _database!.delete(_tableName);
      AppLogger.info('LocalAssetStore: 清空所有记录成功');
      return true;
    } catch (e) {
      AppLogger.error('LocalAssetStore: 清空所有记录失败:', e);
      return false;
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
      _isInitialized = false;
      AppLogger.info('LocalAssetStore: 数据库已关闭');
    } catch (e) {
      AppLogger.error('LocalAssetStore: 关闭失败:', e);
    }
  }
}
