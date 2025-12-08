import 'package:common/common.dart';

/// 仅负责 GetStorage 相关 API 的封装
class GetStorageService {
  GetStorageService(this._box);

  final GetStorage _box;

  /// 读取一个值
  /// [defaultValue] 可选：如果没有该 key，返回默认值。
  T? readValue<T>(String key, {T? defaultValue}) {
    if (key.isEmpty) {
      return defaultValue;
    }
    final T? value = _box.read<T>(key);
    if (value == null) {
      return defaultValue;
    }
    return value;
  }

  /// 写入一个值
  Future<void> writeValue<T>(String key, T value) async {
    if (key.isEmpty) {
      return;
    }
    await _box.write(key, value);
  }

  /// 更新指定 key 的值：读 → 回调修改 → 写回
  Future<void> updateValue<T>(
    String key,
    T Function(T? oldValue) updateCallback,
  ) async {
    if (key.isEmpty) {
      return;
    }
    final T? oldValue = _box.read<T>(key);
    final T newValue = updateCallback(oldValue);
    await _box.write(key, newValue);
  }

  //更新模型
  Future<void> updateModel<T>({
    required String key,
    required T Function(T oldModel) updater,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T model) toJson,
    required T defaultValue,
  }) async {
    final dynamic raw = _box.read(key);

    T currentModel = defaultValue;

    if (raw is Map) {
      try {
        currentModel = fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        currentModel = defaultValue;
      }
    }

    final T newModel = updater(currentModel);

    await _box.write(key, toJson(newModel));
  }

  /// 删除指定 key
  Future<void> removeValue(String key) async {
    if (key.isEmpty) {
      return;
    }
    if (!_box.hasData(key)) {
      return;
    }
    await _box.remove(key);
  }

  /// 清空当前 box 中的所有数据
  Future<void> clearAll() async {
    await _box.erase();
  }

  /// 当前 key 是否存在
  bool containsKey(String key) {
    if (key.isEmpty) {
      return false;
    }
    return _box.hasData(key);
  }
}

/*
1、listenKey：监听某个 key 的值变化（类似一个简单的观察者）。

    box.listenKey('token', (value) {
      // token 改变时触发
      debugPrint('token changed: $value');
    });

2、更新一个 int 计数器
  await updateValue<int>(
    'counter',
    (oldValue) {
      final int current = oldValue ?? 0;
      return current + 1;
    },
  );

3、更新一个 List
    await updateValue<List<String>>(
      'recent_fonts',
      (oldValue) {
        // oldValue 可能为 null，要做好兜底
        final List<String> list = List<String>.from(oldValue ?? <String>[]);

        if (!list.contains('系统默认')) {
          list.add('系统默认');
        }
        return list;
      },
    );

4、更新一个 JSON Map（推荐你这边存 JSON 用这种）
    await updateValue<Map<String, dynamic>>(
      'user_info',
      (oldValue) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(oldValue ?? <String, dynamic>{});

        data['nickname'] = '设计达人';
        data['avatar'] = 'https://xxx.com/avatar.png';

        return data;
      },
    );

5、更新一个 JSON List（画布列表那种）
    await updateValue<List<Map<String, dynamic>>>(
      'canvas_list',
      (oldValue) {
        final List<Map<String, dynamic>> list =
            (oldValue ?? <Map<String, dynamic>>[])
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

        // 比如新增一个画布
        list.add(<String, dynamic>{
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': '新画布',
          'width': 1080,
          'height': 1920,
        });

        return list;
      },
    );

6、封装一个专门更新 model 的工具（更优雅）

      Future<void> updateUserModel(
         required String key
        T Function(UserModel old) updater,
      ) {
        return updateModel<UserModel>(
          key: key,
          defaultValue: UserModel(),
          fromJson: (json) => UserModel.fromJson(json),
          toJson: (model) => model.toJson(),
          updater: updater,
        );
      }

      // 调用示例：
      Future<void> changeNickname() {
        return updateUserModel("user_model",(old) {
          return old.copyWith(nickname: '新昵称');
        });
      }

      Future<void> setLoginState(bool isLogin) {
        return updateUserModel("user_model", (old) {
          return old.copyWith(isLogin: isLogin);
        });
      }
*/

/*
GetX 的响应式监听 Worker API，专门用来监听 Rx 变量的变化
1、ever：每次监听值变化就执行一次回调。
    ever(userInfo, (user) {
          box.write(userInfoKey, user);
          getAddressList();
    });

2、everAll：监听 多个 Rx 变量，只要其中任意一个变化就触发一次回调。
    适用场景：例如一个页面有多个 Rx 状态：筛选条件、搜索关键词、排序方式，只要有一项变，都触发一个统一逻辑
    everAll(
    <RxInterface<dynamic>>[keyword, sortType, filterType],
    (List<dynamic> values) {
       // 任意一个条件变化，刷新列表
        fetchList();
    },
  );

3、once： 只在第一次变化时触发一次回调，之后不再触发
  适用场景：
	    •	某个状态第一次变为“就绪”、“成功”、“加载完成”时执行一次操作。
	    •	比如第一次拿到用户信息就弹欢迎提示、执行一次引导。
    once<UserModel>(_user, (UserModel value) {
        if (value.isLogin) {
          // 只在第一次变成登录状态时执行
          Get.snackbar('欢迎', '欢迎回来，${value.nickname}');
        }
    });

4、debounce： 防抖：值停止变化一段时间后才触发一次回调；期间如果一直变，就一直延后触发
  	适用场景：
	    •	搜索框输入：用户停止输入 500ms 后再请求接口。
	    •	文本编辑：停下 1s 后自动保存草稿（和 GetStorage 常搭配）。
    debounce<String>(
        searchKeyword,
        (String keyword) {
          fetchSearchResult(keyword);
        },
        time: const Duration(milliseconds: 500),
    );

5、interval： 节流：一段时间内只响应一次变化，之后重新开始计时。
    适用场景：
      •	滚动监听、拖动位置监听：状态变化非常频繁，但你只想每 200ms 做一次处理。
      •	比如画布缩放 / 拖动过程中，只间隔一段时间同步一次状态到本地。
    interval<double>(
        progress,
        (double value) {
          // 比如上报进度，或者做一些相对重的操作
          debugPrint('当前进度：$value');
        },
        time: const Duration(milliseconds: 200),
    );
*/
