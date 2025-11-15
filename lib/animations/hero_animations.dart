import 'package:flutter/material.dart';

/// Hero动画包装器
/// 为Widget提供Hero动画效果
class HeroWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  final bool enabled;

  const HeroWrapper({
    super.key,
    required this.tag,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
    return Hero(
      tag: tag,
      child: child,
    );
  }
}

/// 导航栏Hero动画
/// 为导航栏项目提供Hero转场效果
class NavigationHero extends StatelessWidget {
  final String heroTag;
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const NavigationHero({
    super.key,
    required this.heroTag,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected && selectedIcon != null 
                    ? selectedIcon! 
                    : icon,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 浮动操作按钮Hero动画
/// 为FAB提供Hero转场效果
class FloatingActionButtonHero extends StatelessWidget {
  final String heroTag;
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final double elevation;

  const FloatingActionButtonHero({
    super.key,
    required this.heroTag,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.elevation = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        elevation: elevation,
        child: child,
      ),
    );
  }
}

/// 卡片Hero动画
/// 为卡片组件提供Hero转场效果
class CardHero extends StatelessWidget {
  final String heroTag;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  const CardHero({
    super.key,
    required this.heroTag,
    required this.child,
    this.onTap,
    this.margin,
    this.elevation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Card(
        margin: margin,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

/// 图片Hero动画
/// 为图片提供Hero转场效果
class ImageHero extends StatelessWidget {
  final String heroTag;
  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const ImageHero({
    super.key,
    required this.heroTag,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: image,
            width: width,
            height: height,
            fit: fit,
          ),
        ),
      ),
    );
  }
}

/// Hero动画工具类
class HeroAnimationUtils {
  /// 创建Hero转场路由
  static PageRouteBuilder<T> createHeroRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }

  /// 导航到带有Hero动画的页面
  static Future<T?> navigateWithHero<T>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.of(context).push<T>(
      createHeroRoute<T>(
        page: page,
        duration: duration,
        curve: curve,
      ),
    );
  }
}