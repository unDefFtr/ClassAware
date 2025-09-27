import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  // 示例课程表数据
  final List<Map<String, dynamic>> _todaySchedule = [
    {
      'time': '08:00-08:45',
      'subject': '语文',
      'teacher': '张老师',
      'room': '教室A101',
    },
    {
      'time': '08:55-09:40',
      'subject': '数学',
      'teacher': '李老师',
      'room': '教室A101',
    },
    {
      'time': '09:50-10:35',
      'subject': '英语',
      'teacher': '王老师',
      'room': '教室A101',
    },
    {
      'time': '10:45-11:30',
      'subject': '物理',
      'teacher': '赵老师',
      'room': '实验室B201',
    },
    {
      'time': '14:00-14:45',
      'subject': '化学',
      'teacher': '陈老师',
      'room': '实验室B202',
    },
    {
      'time': '14:55-15:40',
      'subject': '体育',
      'teacher': '刘老师',
      'room': '操场',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w), // MD3标准内边距
          child: Row(
            children: [
              // 左侧列：时间天气卡片 + 班级信息卡片
              Expanded(
                flex: 3, // 从1增加到3
                child: Column(
                  children: [
                    // 左上角：时间和天气卡片
                    Expanded(
                      flex: 1,
                      child: _buildTimeWeatherCard(),
                    ),
                    SizedBox(height: 16.h), // MD3标准卡片间距
                    // 左下角：班级信息卡片
                    Expanded(
                      flex: 1,
                      child: _buildClassInfoCard(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w), // MD3标准卡片间距
              // 右侧：课程表卡片
              Expanded(
                flex: 4, // 从2增加到4，保持相对比例但给左侧更多空间
                child: _buildTodaySchedule(),
              ),
            ],
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

  Widget _buildTimeWeatherCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weekWeather.length,
                itemBuilder: (context, index) {
                  final weather = _weekWeather[index];
                  return Container(
                    width: 60.w,
                    margin: EdgeInsets.only(right: 12.w),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Card(
      elevation: 2, // 增加阴影
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(20.w), // 减小内边距
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
            SizedBox(height: 16.h), // 减小间距
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildInfoItem('学生人数', '45人', Icons.people)),
                SizedBox(width: 8.w),
                Expanded(child: _buildInfoItem('出勤率', '98%', Icons.check_circle)),
              ],
            ),
            SizedBox(height: 16.h), // 减小间距
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

  Widget _buildTodaySchedule() {
    return Card(
      elevation: 2, // 增加阴影
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(16.w), // MD3标准内边距
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
            SizedBox(height: 18.h), // 减小间距，从24.h改为18.h
            Expanded(
              child: ListView.separated(
                itemCount: _todaySchedule.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h), // MD3标准列表项间距
                itemBuilder: (context, index) {
                  final course = _todaySchedule[index];
                  final isCurrentTime = _isCurrentCourse(course['time']);
                  
                  return Container(
                    padding: EdgeInsets.all(12.w), // MD3标准列表项内边距
                    decoration: BoxDecoration(
                      color: isCurrentTime 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.r), // 减小圆角，从16.r改为12.r
                      border: isCurrentTime 
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 90.w, // 稍微增加宽度以适应两行显示
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                course['time'].split('-')[0], // 开始时间
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrentTime 
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                course['time'].split('-')[1], // 结束时间
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
                        SizedBox(width: 18.w), // 稍微增加间距以适应两行时间显示
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['subject'],
                                style: TextStyle(
                                  fontSize: 20.sp, // 减小字体，从24.sp改为20.sp
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentTime 
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4.h), // 减小间距，从6.h改为4.h
                              Text(
                                '${course['teacher']} • ${course['room']}',
                                style: TextStyle(
                                  fontSize: 16.sp, // 减小字体，从18.sp改为16.sp
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
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), // 减小内边距
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8.r), // 减小圆角，从10.r改为8.r
                            ),
                            child: Text(
                              '进行中',
                              style: TextStyle(
                                fontSize: 14.sp, // 减小字体，从16.sp改为14.sp
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
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