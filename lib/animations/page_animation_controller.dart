import 'package:flutter/material.dart';
import 'custom_page_route.dart';

/// 页面动画控制器
/// 负责管理页面切换动画的状态和性能优化
class PageAnimationController extends ChangeNotifier {
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isAnimating = false;
  
  /// 当前页面索引
  int get currentIndex => _currentIndex;
  
  /// 上一个页面索引
  int get previousIndex => _previousIndex;
  
  /// 是否正在动画中
  bool get isAnimating => _isAnimating;

  /// 切换到指定页面
  void switchToPage(int index) {
    if (_currentIndex == index || _isAnimating || index < 0) return;
    
    _previousIndex = _currentIndex;
    _currentIndex = index;
    _isAnimating = true;
    
    notifyListeners();
    
    // 动画完成后重置状态
    Future.delayed(const Duration(milliseconds: 400), () { // 与新的动画时长同步
      _isAnimating = false;
      notifyListeners();
    });
  }

  /// 获取转场动画类型
  PageTransitionType getTransitionType() {
    if (_currentIndex > _previousIndex) {
      return PageTransitionType.slideRight;
    } else {
      return PageTransitionType.slideLeft;
    }
  }

  /// 重置控制器状态
  void reset() {
    _currentIndex = 0;
    _previousIndex = 0;
    _isAnimating = false;
    notifyListeners();
  }
}

/// 页面动画包装器
/// 为页面内容提供动画容器和性能优化
class AnimatedPageWrapper extends StatelessWidget {
  final Widget child;
  final int pageIndex;
  final PageAnimationController controller;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    required this.pageIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return RepaintBoundary(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400), // 统一使用较短的动画时长
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // 根据页面切换方向决定动画类型
              final isForward = controller.currentIndex > controller.previousIndex;
              
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(isForward ? 0.2 : -0.2, 0.0), // 减小滑动距离
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(controller.currentIndex),
              child: controller.currentIndex == pageIndex ? child : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// 优化的页面切换器
/// 使用IndexedStack提供更好的性能
class OptimizedPageSwitcher extends StatelessWidget {
  final List<Widget> pages;
  final PageAnimationController controller;
  final bool maintainState;

  const OptimizedPageSwitcher({
    super.key,
    required this.pages,
    required this.controller,
    this.maintainState = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (maintainState) {
          // 使用IndexedStack保持页面状态
          return RepaintBoundary(
            child: IndexedStack(
              index: controller.currentIndex,
              children: pages.map((page) => RepaintBoundary(child: page)).toList(),
            ),
          );
        } else {
          // 使用AnimatedSwitcher提供转场动画
          return RepaintBoundary(
            child: ClipRect( // 添加裁剪防止内容溢出
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400), // 统一使用较短的动画时长
                  switchInCurve: Curves.easeOutCubic, // 统一使用简单的动画曲线
                  switchOutCurve: Curves.easeInCubic, // 退出时使用更快的曲线
                transitionBuilder: (Widget child, Animation<double> animation) {
                   final isForward = controller.currentIndex > controller.previousIndex;
                   
                   return ClipRect( // 确保动画内容不会溢出
                     child: SlideTransition(
                       position: Tween<Offset>(
                          begin: Offset(isForward ? 0.2 : -0.2, 0.0), // 减小滑动距离，避免过度动画
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic, // 使用与主动画相同的曲线
                        )),
                       child: FadeTransition( // 添加淡入淡出效果
                         opacity: animation,
                         child: child,
                       ),
                     ),
                   );
                 },
                child: Container(
                  key: ValueKey<int>(controller.currentIndex),
                  child: pages[controller.currentIndex],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}