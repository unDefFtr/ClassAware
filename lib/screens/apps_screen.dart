import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<Map<String, dynamic>> _allApps = [];
  List<Map<String, dynamic>> _filteredApps = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // 使用 ValueNotifier 来优化搜索性能
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _loadSampleApps();
    
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

  void _loadSampleApps() {
    // 显示一些常用的教育类应用示例
    _allApps = [
      {
        'name': '钉钉',
        'icon': Icons.business,
        'color': Colors.blue,
        'package': 'com.alibaba.android.rimet',
      },
      {
        'name': '腾讯会议',
        'icon': Icons.video_call,
        'color': Colors.green,
        'package': 'com.tencent.wemeet.app',
      },
      {
        'name': '学习强国',
        'icon': Icons.school,
        'color': Colors.red,
        'package': 'cn.xuexi.android',
      },
      {
        'name': '网易云课堂',
        'icon': Icons.play_lesson,
        'color': Colors.orange,
        'package': 'com.netease.edu.study',
      },
      {
        'name': '百度网盘',
        'icon': Icons.cloud,
        'color': Colors.purple,
        'package': 'com.baidu.netdisk',
      },
      {
        'name': '微信',
        'icon': Icons.chat,
        'color': Colors.green,
        'package': 'com.tencent.mm',
      },
      {
        'name': '支付宝',
        'icon': Icons.payment,
        'color': Colors.blue,
        'package': 'com.eg.android.AlipayGphone',
      },
      {
        'name': '抖音',
        'icon': Icons.music_video,
        'color': Colors.black,
        'package': 'com.ss.android.ugc.aweme',
      },
    ];
    
    // 初始化时显示所有应用
    _filteredApps = List.from(_allApps);
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
    await _launchAppByPackage(app['package'] as String);
  }

  @override
  Widget build(BuildContext context) {
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
          
          // 快捷应用区域
          _buildQuickApps(),
          
          // 所有应用列表
          Expanded(
            child: _buildAppsList(),
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
    final quickApps = [
      {
        'name': '钉钉',
        'icon': Icons.business,
        'color': Colors.blue,
        'package': 'com.alibaba.android.rimet',
      },
      {
        'name': '腾讯会议',
        'icon': Icons.video_call,
        'color': Colors.green,
        'package': 'com.tencent.wemeet.app',
      },
      {
        'name': '学习强国',
        'icon': Icons.school,
        'color': Colors.red,
        'package': 'cn.xuexi.android',
      },
      {
        'name': '网易云课堂',
        'icon': Icons.play_lesson,
        'color': Colors.orange,
        'package': 'com.netease.edu.study',
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷应用',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 100.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickApps.length,
              itemBuilder: (context, index) {
                final app = quickApps[index];
                return Container(
                  width: 80.w,
                  margin: EdgeInsets.only(right: 16.w),
                  child: Column(
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.h,
                        decoration: BoxDecoration(
                          color: (app['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: IconButton(
                          onPressed: () => _launchAppByPackage(app['package'] as String),
                          icon: Icon(
                            app['icon'] as IconData,
                            color: app['color'] as Color,
                            size: 28.w,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        app['name'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
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

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '所有应用 (${_filteredApps.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
              ),
              itemCount: _filteredApps.length,
              itemBuilder: (context, index) {
                final app = _filteredApps[index];
                return GestureDetector(
                  onTap: () => _launchApp(app),
                  child: Column(
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.h,
                        decoration: BoxDecoration(
                          color: (app['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          app['icon'] as IconData,
                          color: app['color'] as Color,
                          size: 28.w,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Expanded(
                        child: Text(
                          app['name'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchAppByPackage(String packageName) async {
    try {
      final uri = Uri.parse('package:$packageName');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // 如果无法启动应用，显示提示信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('无法启动应用: $packageName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // 处理启动应用时的错误
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
}