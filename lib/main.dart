import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';

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
        final scheme = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        );
        return MaterialApp(
          title: '电子班牌',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: scheme.surface,
            cardTheme: CardThemeData(
              color: scheme.surface,
              elevation: 0,
            ),
            // 针对触屏优化的主题设置，增大字体和组件尺寸
            visualDensity: VisualDensity.comfortable,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: 1.1,
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
  late final VoidCallback _authListener;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    AppsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    
    // 初始化页面控制器，参考 flutter_server_box
    _pageController = PageController(initialPage: _selectIndex.value);
    _authListener = _onAuthActiveChanged;
    AuthService.instance.authActive.addListener(_authListener);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectIndex.dispose();
    AuthService.instance.authActive.removeListener(_authListener);
    super.dispose();
  }



  Future<void> _handleDestination(int index) async {
    if (_selectIndex.value == index) return;
    if (index < 0 || index >= _screens.length) return;
    final prevIndex = _selectIndex.value;
    final prefs = await SharedPreferences.getInstance();
    final authEnabled = prefs.getBool('auth_enabled') ?? false;
    final lockApps = prefs.getBool('lock_apps') ?? false;
    final lockSettings = prefs.getBool('lock_settings') ?? false;
    bool needAuth = false;
    String reason = '需要身份验证';
    if (authEnabled) {
      if (index == 2 && lockApps) { needAuth = true; reason = '访问所有应用'; }
      if (index == 3 && lockSettings) { needAuth = true; reason = '访问设置'; }
    }
    if (needAuth) {
      if (!mounted) return;
      final ok = await AuthService.instance.ensureAuthenticated(context, reason: reason);
      if (!ok) return;
    }
    _selectIndex.value = index;
    _switchingPage = true;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 677),
      curve: Curves.fastLinearToSlowEaseIn,
    );
    final wasSensitive = (prevIndex == 2 && lockApps) || (prevIndex == 3 && lockSettings);
    final destSensitive = (index == 2 && lockApps) || (index == 3 && lockSettings);
    if (wasSensitive && !destSensitive) {
      await AuthService.instance.lockIfHighSecurity();
    }
    Future.delayed(const Duration(milliseconds: 677), () {
      _switchingPage = false;
    });
  }

  Future<void> _onAuthActiveChanged() async {
    if (AuthService.instance.isAuthenticated) return;
    final prefs = await SharedPreferences.getInstance();
    final authEnabled = prefs.getBool('auth_enabled') ?? false;
    if (!authEnabled) return;
    final lockApps = prefs.getBool('lock_apps') ?? false;
    final lockSettings = prefs.getBool('lock_settings') ?? false;
    final idx = _selectIndex.value;
    final needForceHome = (idx == 2 && lockApps) || (idx == 3 && lockSettings);
    if (!needForceHome) return;
    _selectIndex.value = 0;
    _switchingPage = true;
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 677), curve: Curves.fastLinearToSlowEaseIn);
    Future.delayed(const Duration(milliseconds: 677), () { _switchingPage = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: _selectIndex,
                  builder: (context, _) => NavigationRail(
                    selectedIndex: _selectIndex.value,
                    onDestinationSelected: (i) async { await _handleDestination(i); },
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('主页'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.schedule_outlined),
                        selectedIcon: Icon(Icons.schedule),
                        label: Text('课表'),
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
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _screens.length,
                  physics: const NeverScrollableScrollPhysics(),
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
          Positioned(
            bottom: 12,
            right: 12,
            child: ListenableBuilder(
              listenable: AuthService.instance.authActive,
              builder: (context, _) {
                if (!AuthService.instance.isAuthenticated) return const SizedBox.shrink();
                return _buildAdminBadge();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text('管理员模式', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              AuthService.instance.forceLock();
              setState(() {});
            },
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('手动锁定'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
