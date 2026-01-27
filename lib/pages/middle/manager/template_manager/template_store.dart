import 'package:sqflite/sqflite.dart';
import 'package:voicetemplate/file/index.dart';
import 'package:path/path.dart' as p;
import '../manager_model.dart';
import 'package:common/common.dart' hide Database;

/// SQLite Store 管理类
/// 负责模板数据的存储、更新、删除等操作
class TemplateStore {
  TemplateStore._();
  static TemplateStore? _instance;
  static TemplateStore get instance {
    _instance ??= TemplateStore._();
    return _instance!;
  }

  Database? _database;
  bool _isInitialized = false;
  static const String _tableName = 'templates';
  static const int _version = 2; // 升级版本，删除 editTime 列

  /// 初始化数据库
  Future<void> init() async {
    if (_isInitialized && _database != null) {
      AppLogger.info('TemplateStore: 已经初始化，跳过');
      return;
    }

    try {
      // 获取存储目录（使用 Support 目录，适合数据库文件）
      final supportDir = await DirectoryManager.getSupportDirectory();
      final dbDir = await DirectoryManager.getOrCreateSubDirectory(
        supportDir,
        'templates',
      );

      final dbPath = p.join(dbDir.path, 'templates.db');

      _database = await openDatabase(
        dbPath,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _isInitialized = true;
      AppLogger.info('TemplateStore: 初始化成功, 数据库路径: $dbPath');
    } catch (e, stackTrace) {
      AppLogger.error('TemplateStore: 初始化失败:', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        pk INTEGER PRIMARY KEY AUTOINCREMENT,
        canvasId INTEGER UNIQUE NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_canvasId ON $_tableName(canvasId)
    ''');
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');

    AppLogger.info('TemplateStore: 数据库表创建成功');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 当前版本变更较大，直接丢弃旧表重建
    AppLogger.info('TemplateStore: 数据库升级: $oldVersion -> $newVersion, 重建表结构');
    await db.execute('DROP TABLE IF EXISTS $_tableName');
    await _onCreate(db, newVersion);
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _database == null) {
      await init();
    }
  }

  /// 保存模板数据
  /// [model] ManagerModel 数据
  /// 如果业务 id（canvasId）已存在，则更新；否则创建新记录
  /// 返回 true 表示成功，false 表示失败
  Future<bool> save(ManagerModel model) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('TemplateStore: 数据库未初始化');
    }

    try {
      if (model.id == 0) {
        AppLogger.info('TemplateStore: 业务 id 为空，无法保存');
        return false;
      }

      // 检查记录是否存在
      final existing = await getById(model.id);
      if (existing != null) {
        // 更新现有记录
        AppLogger.info('TemplateStore: 更新记录, canvasId=${model.id}');
        return await update(model);
      }

      // 创建新记录（使用 INSERT OR REPLACE 确保 canvasId 唯一性）
      await _database!.insert(
        _tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.info('TemplateStore: 保存成功, canvasId=${model.id}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('TemplateStore: 保存失败:', e, stackTrace);
      return false;
    }
  }

  /// 更新模板数据
  /// [model] ManagerModel 数据
  /// 根据业务 id（canvasId）更新记录
  Future<bool> update(ManagerModel model) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('TemplateStore: 数据库未初始化');
    }

    try {
      if (model.id == 0) {
        AppLogger.info('TemplateStore: 业务 id 为空，无法更新');
        return false;
      }

      // 使用 canvasId 作为更新条件
      final count = await _database!.update(
        _tableName,
        model.toMap(),
        where: 'canvasId = ?',
        whereArgs: [model.id],
      );
      final success = count > 0;
      if (success) {
        AppLogger.info('TemplateStore: 更新成功, canvasId=${model.id}');
      } else {
        AppLogger.info('TemplateStore: 更新失败，记录不存在, canvasId=${model.id}');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('TemplateStore: 更新失败: ', e, stackTrace);
      return false;
    }
  }

  /// 根据业务 id（canvasId）删除
  Future<bool> deleteById(int id) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('TemplateStore: 数据库未初始化');
    }

    try {
      if (id == 0) {
        AppLogger.info('TemplateStore: 业务 id 为空，无法删除');
        return false;
      }

      // 直接使用 canvasId 作为删除条件
      final count = await _database!.delete(
        _tableName,
        where: 'canvasId = ?',
        whereArgs: [id],
      );
      final success = count > 0;
      if (success) {
        AppLogger.info('TemplateStore: 删除成功, canvasId=$id');
      } else {
        AppLogger.info('TemplateStore: 删除失败，记录不存在, canvasId=$id');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('TemplateStore: 删除失败: ', e, stackTrace);
      return false;
    }
  }

  /// 根据业务 id（canvasId）获取
  Future<ManagerModel?> getById(int id) async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('TemplateStore: 数据库未初始化');
    }

    try {
      if (id == 0) {
        return null;
      }

      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        where: 'canvasId = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }

      return ManagerModel.fromMap(maps.first);
    } catch (e) {
      AppLogger.error('TemplateStore: 获取失败:', e);
      return null;
    }
  }

  /// 获取所有记录
  Future<List<ManagerModel>> getAll() async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('TemplateStore: 数据库未初始化');
    }

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _tableName,
        orderBy: 'timestamp DESC',
      );
      return maps.map((map) => ManagerModel.fromMap(map)).toList();
    } catch (e) {
      AppLogger.error('TemplateStore: 获取所有记录失败:', e);
      return [];
    }
  }

  /// 清空所有记录
  Future<bool> clearAll() async {
    await _ensureInitialized();
    if (_database == null) {
      throw Exception('TemplateStore: 数据库未初始化');
    }
    try {
      await _database!.delete(_tableName);
      AppLogger.info('TemplateStore: 清空所有记录成功');
      return true;
    } catch (e) {
      AppLogger.error('TemplateStore: 清空所有记录失败:', e);
      return false;
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
      _isInitialized = false;
      AppLogger.info('TemplateStore: 数据库已关闭');
    } catch (e) {
      AppLogger.error('TemplateStore: 关闭失败:', e);
    }
  }
}
