import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/schedule_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  final ScheduleService _scheduleService = ScheduleService();

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重复初始化定时器

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    // 加载本地课表数据
    _scheduleService.loadScheduleFromLocal();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保持页面状态
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final screenMargin = isTablet ? 17.0 : 13.0;
    final cardPadding = isTablet ? 17.0 : 13.0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenMargin,
            vertical: isTablet ? 11.0 : 7.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final ar = w / (h == 0 ? 1 : h);
              final isWide = w >= 1000 || ar >= 1.4;
              final isMedium = w >= 760 || ar >= 1.2;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildTimeWeatherCard(cardPadding),
                          ),
                          SizedBox(height: 7.h),
                          Expanded(
                            child: _buildClassInfoCard(cardPadding),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      flex: 4,
                      child: _buildTodaySchedule(cardPadding),
                    ),
                  ],
                );
              }
              if (isMedium) {
                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTimeWeatherCard(cardPadding),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: _buildClassInfoCard(cardPadding),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Expanded(
                      child: _buildTodaySchedule(cardPadding),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: h * 0.35,
                      child: _buildTimeWeatherCard(cardPadding),
                    ),
                    SizedBox(height: 7.h),
                    SizedBox(
                      height: h * 0.25,
                      child: _buildClassInfoCard(cardPadding),
                    ),
                    SizedBox(height: 7.h),
                    SizedBox(
                      height: h * 0.6,
                      child: _buildTodaySchedule(cardPadding),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 示例7天天气数据
  final List<Map<String, dynamic>> _weekWeather = [
    {'day': '今天', 'icon': Icons.wb_sunny, 'high': 25, 'low': 18, 'desc': '晴'},
    {'day': '明天', 'icon': Icons.cloud, 'high': 23, 'low': 16, 'desc': '多云'},
    {'day': '后天', 'icon': Icons.grain, 'high': 20, 'low': 14, 'desc': '小雨'},
    {'day': '周四', 'icon': Icons.wb_sunny, 'high': 26, 'low': 19, 'desc': '晴'},
    {'day': '周五', 'icon': Icons.cloud, 'high': 24, 'low': 17, 'desc': '多云'},
    {'day': '周六', 'icon': Icons.wb_sunny, 'high': 27, 'low': 20, 'desc': '晴'},
    {'day': '周日', 'icon': Icons.grain, 'high': 22, 'low': 15, 'desc': '阵雨'},
  ];

  Widget _buildTimeWeatherCard(double cardPadding) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部分：时间和天气并排
            Row(
              children: [
                // 左侧：时间显示
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(_currentTime),
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        DateFormat('yyyy年MM月dd日').format(_currentTime),
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),
                // 右侧：天气信息
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.wb_sunny,
                            size: 32.w,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '25°C',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '晴天',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '空气质量良好',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            // 下半部分：7天天气预报
            Text(
              '未来7天',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Row(
                children: List.generate(_weekWeather.length, (index) {
                  final weather = _weekWeather[index];
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          weather['day'],
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(
                          weather['icon'],
                          size: 20.w,
                          color: weather['icon'] == Icons.wb_sunny
                              ? Colors.orange
                              : weather['icon'] == Icons.grain
                                  ? Colors.blue
                                  : Colors.grey,
                        ),
                        Text(
                          '${weather['high']}°',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${weather['low']}°',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoCard(double cardPadding) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(cardPadding), // 使用响应式内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  size: 32.w, // 减小图标
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '高三(1)班',
                          style: TextStyle(
                            fontSize: 22.sp, // 减小字体
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '班主任：张老师',
                          style: TextStyle(
                            fontSize: 16.sp, // 减小字体
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h), // 减少间距，参考server_box
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildInfoItem('学生人数', '45人', Icons.people)),
                SizedBox(width: 8.w),
                Expanded(child: _buildInfoItem('出勤率', '98%', Icons.check_circle)),
              ],
            ),
            SizedBox(height: 10.h), // 减少间距，参考server_box
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), // 减小内边距
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10.r), // 减小圆角
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10.w, // 减小图标
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      '正常上课中',
                      style: TextStyle(
                        fontSize: 16.sp, // 减小字体
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24.w, // 减小图标
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 6.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18.sp, // 减小字体
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp, // 减小字体
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySchedule(double cardPadding) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(cardPadding), // 使用响应式内边距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 28.w, // 减小图标，从32.w改为28.w
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 10.w), // 减小间距，从12.w改为10.w
                Text(
                  '今日课程表',
                  style: TextStyle(
                    fontSize: 22.sp, // 减小字体，从26.sp改为22.sp
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 13.h), // 减少间距，参考server_box
            Expanded(
              child: Builder(
                builder: (context) {
                  final todayCourses = _scheduleService.getCoursesForDay(DateTime.now());
                  
                  if (todayCourses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 60.w,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '今日无课程安排',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '请在课表页面导入课表数据',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    itemCount: todayCourses.length,
                    separatorBuilder: (context, index) => SizedBox(height: 7.h),
                    itemBuilder: (context, index) {
                      final course = todayCourses[index];
                      final isCurrentTime = _isCurrentCourse('${course.startTime}-${course.endTime}');
                      
                      return Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: isCurrentTime 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12.r),
                          border: isCurrentTime 
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                          boxShadow: isCurrentTime 
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // 添加正在上课的指示器
                            if (isCurrentTime)
                              Container(
                                width: 4.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                            if (isCurrentTime) SizedBox(width: 12.w),
                            Container(
                              width: 90.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        course.startTime, // 开始时间
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isCurrentTime 
                                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (isCurrentTime) ...[
                                        SizedBox(width: 4.w),
                                        Container(
                                          width: 6.w,
                                          height: 6.w,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    course.endTime, // 结束时间
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: isCurrentTime 
                                          ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 18.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          course.name,
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrentTime 
                                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (isCurrentTime)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Text(
                                            '正在上课',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${course.teacher} • ${course.room}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: isCurrentTime 
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentTime)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '进行中',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentCourse(String timeRange) {
    // 简单的时间判断逻辑，实际应用中可以更精确
    final now = _currentTime;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;
    
    // 解析时间范围 (例如: "08:00-08:45")
    final times = timeRange.split('-');
    if (times.length != 2) return false;
    
    final startTime = times[0].split(':');
    final endTime = times[1].split(':');
    
    if (startTime.length != 2 || endTime.length != 2) return false;
    
    final startMinutes = int.parse(startTime[0]) * 60 + int.parse(startTime[1]);
    final endMinutes = int.parse(endTime[0]) * 60 + int.parse(endTime[1]);
    
    return currentTimeInMinutes >= startMinutes && currentTimeInMinutes <= endMinutes;
  }
}