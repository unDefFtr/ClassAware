import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _allApps = [];
  List<Map<String, dynamic>> _filteredApps = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // 使用 ValueNotifier 来优化搜索性能
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');
  
  // MethodChannel for native Android communication
  static const platform = MethodChannel('com.example.classaware/launcher');

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重复加载应用列表

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    
    // 监听搜索变化，使用防抖优化
    _searchNotifier.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchNotifier.value;
    if (query != _searchQuery) {
      _searchQuery = query;
      _filterApps(query);
    }
  }



  Future<void> _loadInstalledApps() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 使用原生Android方法获取可启动的应用
      final List<dynamic> launchableApps = await platform.invokeMethod('getLaunchableApps');
      
      List<Map<String, dynamic>> apps = [];
      
      for (var appData in launchableApps) {
        final Map<String, dynamic> app = Map<String, dynamic>.from(appData);
        
        // 原生Android代码已经包含图标数据
        apps.add(app);
      }

      if (mounted) {
        setState(() {
          _allApps = apps;
          _filteredApps = List.from(apps);
          _isLoading = false;
        });
      }
      
      print('成功加载 ${_allApps.length} 个可启动应用');
    } catch (e) {
      print('加载应用失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载应用失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterApps(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredApps = List.from(_allApps);
        } else {
          _filteredApps = _allApps
              .where((app) => (app['name'] as String).toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
      });
    }
  }

  Future<void> _launchApp(Map<String, dynamic> app) async {
    try {
      await InstalledApps.startApp(app['packageName'] as String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动应用失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保持页面状态
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          
          // 主要内容区域：左侧快捷启动，右侧应用列表
          Expanded(
            child: Row(
              children: [
                // 左侧快捷启动区域
                Container(
                  width: isLandscape ? 140.w : 120.w, // 横屏时增加宽度
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildQuickApps(),
                ),
                
                // 右侧应用列表区域
                Expanded(
                  child: _buildAppsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: SearchBar(
        hintText: '搜索应用...',
        leading: const Icon(Icons.search),
        onChanged: (value) {
          _searchNotifier.value = value;
        },
        padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(horizontal: 16.w),
        ),
      ),
    );
  }

  Widget _buildQuickApps() {
    // 常用应用包名列表（更新为更常见的用户应用）
    final quickAppPackages = [
      'com.tencent.mm',      // 微信
      'com.tencent.mobileqq', // QQ
      'com.taobao.taobao',   // 淘宝
      'com.alibaba.android.rimet', // 钉钉
      'com.ss.android.ugc.aweme', // 抖音
      'com.sina.weibo',      // 微博
      'com.netease.cloudmusic', // 网易云音乐
      'com.tencent.qqmusic',    // QQ音乐
      'com.baidu.BaiduMap',     // 百度地图
      'com.autonavi.minimap',   // 高德地图
      'com.jingdong.app.mall',  // 京东
      'com.tmall.wireless',     // 天猫
      'com.xunmeng.pinduoduo',  // 拼多多
      'com.zhihu.android',      // 知乎
      'tv.danmaku.bili',        // 哔哩哔哩
      'com.tencent.qqlive',     // 腾讯视频
      'com.youku.phone',        // 优酷
      'com.iqiyi.i18n',         // 爱奇艺
    ];
    
    // 从已安装应用中筛选快速应用
    final quickApps = _allApps
        .where((app) => quickAppPackages.contains(app['packageName'] as String))
        .take(8)
        .toList();
    
    // 如果找不到足够的快速应用，用前几个已安装的应用补充
    if (quickApps.length < 8) {
      final remainingApps = _allApps
          .where((app) => !quickAppPackages.contains(app['packageName'] as String))
          .take(8 - quickApps.length)
          .toList();
      quickApps.addAll(remainingApps);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速启动',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: quickApps.length,
            itemBuilder: (context, index) {
              final app = quickApps[index];
              return RepaintBoundary( // 添加重绘边界优化
                child: GestureDetector(
                  onTap: () => _launchApp(app),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: Column(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.transparent,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: app['icon'] != null && app['icon'].toString().isNotEmpty
                                ? Image.memory(
                                    base64Decode(app['icon']),
                                    width: 48.w,
                                    height: 48.w,
                                    fit: BoxFit.contain,
                                    cacheWidth: (48.w * MediaQuery.of(context).devicePixelRatio).round(),
                                    cacheHeight: (48.w * MediaQuery.of(context).devicePixelRatio).round(),
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.apps,
                                        size: 24.sp,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.apps,
                                    size: 24.sp,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        SizedBox(
                          width: 80.w,
                          child: Text(
                            app['name'] as String,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppsList() {
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 64.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isEmpty ? '暂无已安装的应用' : '未找到匹配的应用',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 自适应参数由下方 LayoutBuilder 计算

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h), // 添加垂直边距
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 8.h), // MD3推荐的标题内边距
            child: Text(
              '所有应用 (${_filteredApps.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600, // MD3推荐的字重
                letterSpacing: 0.15, // 改善可读性
              ),
            ),
          ),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final minTile = 96.0;
                final spacing = (w * 0.01).clamp(4.0, 16.0);
                final cols = (w / (minTile + spacing)).floor().clamp(4, 18);
                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    return RepaintBoundary(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _launchApp(app),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Padding(
                            padding: EdgeInsets.all(2.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48.w,
                                  height: 48.w,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: app['icon'] != null && app['icon'].toString().isNotEmpty
                                        ? Image.memory(
                                            base64Decode(app['icon']),
                                            width: 48.w,
                                            height: 48.w,
                                            fit: BoxFit.contain,
                                            cacheWidth: (48.w * MediaQuery.of(context).devicePixelRatio).round(),
                                            cacheHeight: (48.w * MediaQuery.of(context).devicePixelRatio).round(),
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.apps,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 28.w,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.apps,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 28.w,
                                          ),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Expanded(
                                  child: Text(
                                    app['name'] as String,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 检查应用是否可以启动的辅助方法（已不再使用，但保留以备将来需要）
  Future<bool> _canLaunchApp(String packageName) async {
    try {
      // 使用Android的启动Intent来检查应用是否有可启动的Activity
      final uri = Uri.parse('package:$packageName');
      return await canLaunchUrl(uri);
    } catch (e) {
      // 如果检查失败，返回false以排除该应用
      return false;
    }
  }
}