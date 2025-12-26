import 'package:common/common.dart';
import 'package:flutter/material.dart';

/// 处理滑动切换和点击切换，避免循环触发
TabController useSyncedTabController({
  required int length,
  required RxInt currentIndex,
  required ParamCallback<int> onIndexChanged,
  TickerProvider? vsync,
  Duration animationDuration = const Duration(milliseconds: 300),
}) {
  final tabController = useTabController(
    initialLength: length,
    initialIndex: currentIndex.value,
    vsync: vsync,
  );

  // 使用useRef避免闭包问题和不必要的重新渲染
  final changeSourceRef = useRef(TabChangeSource.none);
  final lastIndexRef = useRef(currentIndex.value);

  // 缓存节流函数，避免每次build都重新创建
  final throttledHandler = useMemoized(() {
    return _throttle(() {
      // 如果是编程式切换，不处理
      if (changeSourceRef.value == .programmatic) {
        return;
      }

      final tab = tabController.animation?.value.round() ?? 0;
      // 增加额外检查避免重复触发
      if (tab != lastIndexRef.value && tab != currentIndex.value) {
        // 标记为滑动切换
        changeSourceRef.value = .swipe;
        lastIndexRef.value = tab;

        // 更新外部状态
        onIndexChanged(tab);

        // 使用微任务延迟重置，避免立即重置导致的竞态条件
        Future.microtask(() {
          changeSourceRef.value = .none;
        });
      }
    }, milliseconds: 16); // 使用16ms (60fps) 提高响应性
  }, []);

  // 监听动画变化，处理滑动切换
  useEffect(() {
    final animation = tabController.animation;
    if (animation != null) {
      animation.addListener(throttledHandler);
      return () => animation.removeListener(throttledHandler);
    }
    return null;
  }, [tabController, throttledHandler]);

  // 监听外部状态变化，处理点击切换
  useEffect(() {
    final subscription = currentIndex.listen((targetIndex) {
      // 如果正在滑动或者索引相同，忽略
      if (changeSourceRef.value == .swipe ||
          targetIndex == lastIndexRef.value) {
        return;
      }

      final currentTabIndex = tabController.index;
      if (targetIndex != currentTabIndex) {
        // 标记为编程式切换
        changeSourceRef.value = .programmatic;
        lastIndexRef.value = targetIndex;

        // 执行切换动画
        tabController.animateTo(targetIndex, duration: animationDuration);

        // 监听动画完成事件
        void handleStatusChange(AnimationStatus status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            changeSourceRef.value = .none;
            tabController.animation?.removeStatusListener(handleStatusChange);
          }
        }

        tabController.animation?.addStatusListener(handleStatusChange);
      }
    });

    return subscription.cancel;
  }, [tabController, animationDuration]);

  return tabController;
}

// Tab切换来源枚举
enum TabChangeSource {
  none, // 未在切换过程中
  swipe, // 来自用户滑动
  programmatic, // 来自点击Tab或代码控制
}

// 节流函数，限制高频调用
VoidCallback _throttle(VoidCallback func, {required int milliseconds}) {
  DateTime lastCall = DateTime.now();

  return () {
    final now = DateTime.now();
    if (now.difference(lastCall).inMilliseconds > milliseconds) {
      func();
      lastCall = now;
    }
  };
}
