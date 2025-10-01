import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/settings_screen.dart';

// 页面缓存包装器，防止页面重复构建
class AutomaticKeepAliveWrapper extends StatefulWidget {
  const AutomaticKeepAliveWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AutomaticKeepAliveWrapper> createState() => _AutomaticKeepAliveWrapperState();
}

class _AutomaticKeepAliveWrapperState extends State<AutomaticKeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保持页面状态
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true; // 保持页面状态
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);
  runApp(const ClassAwareApp());
}

class ClassAwareApp extends StatelessWidget {
  const ClassAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1200, 800), // 更适合Web的设计尺寸，3:2比例
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true, // 使用继承的MediaQuery
      ensureScreenSize: true, // 确保屏幕尺寸正确
      builder: (context, child) {
        return MaterialApp(
          title: '电子班牌',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            // 针对触屏优化的主题设置，增大字体和组件尺寸
            visualDensity: VisualDensity.comfortable,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: 1.1, // 稍微减小字体缩放因子
            ),
          ),
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // 采用 flutter_server_box 的动画逻辑
  late final PageController _pageController;
  final _selectIndex = ValueNotifier(0);
  bool _switchingPage = false;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    AppsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // 初始化页面控制器，参考 flutter_server_box
    _pageController = PageController(initialPage: _selectIndex.value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectIndex.dispose();
    super.dispose();
  }



  void _onDestinationSelected(int index) {
    // 采用 flutter_server_box 的页面切换逻辑
    if (_selectIndex.value == index) return; // 避免重复选择
    if (index < 0 || index >= _screens.length) return; // 边界检查
    
    _selectIndex.value = index;
    _switchingPage = true;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 677), // 保持原有动画时长
      curve: Curves.fastLinearToSlowEaseIn, // 恢复原有动画曲线
    );
    Future.delayed(const Duration(milliseconds: 677), () {
      _switchingPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          RepaintBoundary(
            child: ListenableBuilder(
              listenable: _selectIndex,
              builder: (context, _) => NavigationRail(
                selectedIndex: _selectIndex.value,
                onDestinationSelected: _onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
                // groupAlignment: 0.0, // 居中对齐
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('主页'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.apps_outlined),
                    selectedIcon: Icon(Icons.apps),
                    label: Text('所有应用'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('设置'),
                  ),
                ],
              ),
            ),
          ),
          // 右侧内容区域 - 使用 PageView 替代自定义动画系统，并启用页面缓存
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _screens.length,
              physics: const NeverScrollableScrollPhysics(), // 禁用手势滑动
              itemBuilder: (_, index) => RepaintBoundary(
                child: AutomaticKeepAliveWrapper(
                  child: _screens[index],
                ),
              ),
              onPageChanged: (value) {
                FocusScope.of(context).unfocus();
                if (!_switchingPage) {
                  _selectIndex.value = value;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
