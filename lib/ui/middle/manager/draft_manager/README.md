# DraftModel ObjectBox Store

## 使用说明

### 1. 生成 ObjectBox 代码

在使用 `DraftObjectBoxStore` 之前，需要先运行以下命令生成 ObjectBox 代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

这将生成 `objectbox.g.dart` 文件，包含 `getObjectBoxModel()` 函数和 `DraftModel_` 查询类。

### 2. 初始化 Store

在应用启动时（例如 `app_config_init.dart` 或 `main.dart`）初始化：

```dart
await DraftObjectBoxStore.instance.init();
```

### 3. 使用示例

```dart
// 保存草稿
final draft = DraftModel(
  uuid: 'unique-uuid',
  text: '草稿内容',
);
final id = await DraftObjectBoxStore.instance.save(draft);

// 根据 uuid 获取
final savedDraft = await DraftObjectBoxStore.instance.getByUuid('unique-uuid');

// 更新草稿
draft.text = '更新后的内容';
await DraftObjectBoxStore.instance.update(draft);

// 删除草稿
await DraftObjectBoxStore.instance.deleteByUuid('unique-uuid');

// 获取所有草稿（按时间戳排序）
final allDrafts = await DraftObjectBoxStore.instance.getAllOrderByTimestamp();

// 关闭 Store（应用退出时）
DraftObjectBoxStore.instance.close();
```

## API 说明

### 初始化
- `init()`: 初始化 Store，创建数据库连接

### 保存和更新
- `save(DraftModel model)`: 保存或更新草稿（如果 uuid 已存在则更新）
- `update(DraftModel model)`: 更新现有草稿

### 查询
- `getById(int id)`: 根据 id 获取草稿
- `getByUuid(String uuid)`: 根据 uuid 获取草稿
- `getAll()`: 获取所有草稿
- `getAllOrderByTimestamp({bool descending = true})`: 按时间戳排序获取所有草稿

### 删除
- `deleteById(int id)`: 根据 id 删除
- `deleteByUuid(String uuid)`: 根据 uuid 删除
- `clearAll()`: 清空所有记录

### 其他
- `getCount()`: 获取记录总数
- `close()`: 关闭 Store，释放资源

