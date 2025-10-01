import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:installed_apps/installed_apps.dart';
import 'dart:typed_data';

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
      
      // 获取已安装的用户应用（excludeSystemApps: true 过滤系统应用）
      final apps = await InstalledApps.getInstalledApps(true, true);
      
      // 转换为Map格式
      final appMaps = apps.map((app) => {
        'name': app.name,
        'packageName': app.packageName,
        'icon': app.icon,
      }).toList();
      
      if (mounted) {
        setState(() {
          _allApps = appMaps;
          _filteredApps = List.from(appMaps);
          _isLoading = false;
        });
      }
    } catch (e) {
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
      appBar: AppBar(
        title: const Text('所有应用'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
      ),
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
                          height: 48.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: app['icon'] != null
                                ? Image.memory(
                                    Uint8List.fromList(app['icon'] as List<int>),
                                    width: 48.w,
                                    height: 48.h,
                                    fit: BoxFit.cover,
                                    cacheWidth: (48.w * MediaQuery.of(context).devicePixelRatio).round(), // 缓存优化
                                    cacheHeight: (48.h * MediaQuery.of(context).devicePixelRatio).round(),
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    
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

    // 根据屏幕方向和尺寸调整网格参数，符合MD3密度标准
    final crossAxisCount = isLandscape ? 10 : 6; // 优化行数，平衡密度和可用性
    final scrollWidth = isLandscape 
        ? screenWidth * 1.6 // 适度的横向滚动空间
        : screenWidth * 1.3;

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
          // 使用Flexible包装，允许内容在可用空间内自适应
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollWidth,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(), // 禁用GridView的滚动
                  shrinkWrap: true, // 让GridView自适应内容高度
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.1, // 调整宽高比，减少卡片高度
                    crossAxisSpacing: 2.w, // 减少水平间距
                    mainAxisSpacing: 4.h, // 减少垂直间距
                  ),
                  itemCount: _filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    return RepaintBoundary( // 添加重绘边界，减少不必要的重绘
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _launchApp(app),
                          borderRadius: BorderRadius.circular(20.r),
                          child: Padding(
                            padding: EdgeInsets.all(2.w), // 减少内边距
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48.w,
                                  height: 48.h,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: app['icon'] != null
                                         ? Image.memory(
                                             Uint8List.fromList(app['icon'] as List<int>),
                                             width: 48.w,
                                             height: 48.h,
                                             fit: BoxFit.cover,
                                             cacheWidth: (48.w * MediaQuery.of(context).devicePixelRatio).round(), // 缓存优化
                                             cacheHeight: (48.h * MediaQuery.of(context).devicePixelRatio).round(),
                                           )
                                         : Icon(
                                             Icons.apps,
                                             color: Theme.of(context).colorScheme.primary,
                                             size: 28.w,
                                           ),
                                  ),
                                ),
                                SizedBox(height: 4.h), // 增加图标和文字间距
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}