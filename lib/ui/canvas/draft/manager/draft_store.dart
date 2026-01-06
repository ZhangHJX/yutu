import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'draft_model.dart';
import 'package:voicetemplate/file/index.dart';
import 'package:path/path.dart' as p;

/// SQLite Store 管理类
/// 负责 DraftModel 的存储、更新、删除等操作
class DraftStore {
  DraftStore._();
  static DraftStore? _instance;
  static DraftStore get instance {
    _instance ??= DraftStore._();
    return _instance!;
  }

  Database? _database;
  bool _isInitialized = false;
  static const String _tableName = 'drafts';
  static const int _version = 1;

  /// 初始化数据库
  Future<void> init() async {
    if (_isInitialized && _database != null) {
      debugPrint('DraftStore: 已经初始化，跳过');
      return;
    }

    try {
      // 获取存储目录（使用 Support 目录，适合数据库文件）
      final supportDir = await DirectoryManager.getSupportDirectory();
      final dbDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'sqflite_draft',
      );

      final dbPath = p.join(dbDir.path, 'drafts.db');

      _database = await openDatabase(
        dbPath,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _isInitialized = true;
      debugPrint('DraftStore: 初始化成功, 数据库路径: $dbPath');
    } catch (e, stackTrace) {
      debugPrint('DraftStore: 初始化失败: $e\n$stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        textJson TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_uuid ON $_tableName(uuid)
    ''');
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');

    debugPrint('DraftStore: 数据库表创建成功');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 如果需要升级，在这里处理
    debugPrint('DraftStore: 数据库升级: $oldVersion -> $newVersion');
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _database == null) {
      await init();
    }
  }

  /// 保存 DraftModel
  /// 如果 uuid 已存在，则更新；否则创建新记录
  /// 返回 true 表示成功，false 表示失败
  Future<bool> save(DraftModel model) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('DraftStore: 数据库未初始化');
    }

    try {
      if (model.uuid.isEmpty) {
        debugPrint('DraftStore: uuid 为空，无法保存');
        return false;
      }

      // 检查记录是否存在
      final existing = await getByUuid(model.uuid);
      if (existing != null) {
        // 更新现有记录（使用 uuid 作为条件）
        debugPrint('DraftStore: 更新记录, uuid=${model.uuid}');
        return await update(model);
      }

      // 创建新记录（使用 INSERT OR REPLACE 确保 uuid 唯一性）
      await _database!.insert(
        _tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('DraftStore: 保存成功, uuid=${model.uuid}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('DraftStore: 保存失败: $e\n$stackTrace');
      return false;
    }
  }

  /// 更新 DraftModel
  /// 根据 uuid 更新记录
  Future<bool> update(DraftModel model) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('DraftStore: 数据库未初始化');
    }

    try {
      if (model.uuid.isEmpty) {
        debugPrint('DraftStore: uuid 为空，无法更新');
        return false;
      }

      // 使用 uuid 作为更新条件
      final count = await _database!.update(
        _tableName,
        model.toMap(),
        where: 'uuid = ?',
        whereArgs: [model.uuid],
      );
      final success = count > 0;
      if (success) {
        debugPrint('DraftStore: 更新成功, uuid=${model.uuid}');
      } else {
        debugPrint('DraftStore: 更新失败，记录不存在, uuid=${model.uuid}');
      }
      return success;
    } catch (e, stackTrace) {
      debugPrint('DraftStore: 更新失败: $e\n$stackTrace');
      return false;
    }
  }

  /// 根据 uuid 删除
  Future<bool> deleteByUuid(String uuid) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('DraftStore: 数据库未初始化');
    }

    try {
      if (uuid.isEmpty) {
        debugPrint('DraftStore: uuid 为空，无法删除');
        return false;
      }

      // 直接使用 uuid 作为删除条件
      final count = await _database!.delete(
        _tableName,
        where: 'uuid = ?',
        whereArgs: [uuid],
      );
      final success = count > 0;
      if (success) {
        debugPrint('DraftStore: 删除成功, uuid=$uuid');
      } else {
        debugPrint('DraftStore: 删除失败，记录不存在, uuid=$uuid');
      }
      return success;
    } catch (e, stackTrace) {
      debugPrint('DraftStore: 删除失败: $e\n$stackTrace');
      return false;
    }
  }

  /// 根据 uuid 获取
  Future<DraftModel?> getByUuid(String uuid) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('DraftStore: 数据库未初始化');
    }

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'uuid = ?',
        whereArgs: [uuid],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return DraftModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('DraftStore: 获取失败: $e');
      return null;
    }
  }

  /// 获取所有记录
  Future<List<DraftModel>> getAll() async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('DraftStore: 数据库未初始化');
    }

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
      );
      return maps.map((map) => DraftModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('DraftStore: 获取所有记录失败: $e');
      return [];
    }
  }

  /// 清空所有记录
  Future<bool> clearAll() async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('DraftStore: 数据库未初始化');
    }
    try {
      await _database!.delete(_tableName);
      debugPrint('DraftStore: 清空所有记录成功');
      return true;
    } catch (e) {
      debugPrint('DraftStore: 清空所有记录失败: $e');
      return false;
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
      _isInitialized = false;
      debugPrint('DraftStore: 数据库已关闭');
    } catch (e) {
      debugPrint('DraftStore: 关闭失败: $e');
    }
  }
}
