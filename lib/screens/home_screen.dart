import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../services/schedule_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  late Timer _timer;
  Timer? _weatherTimer;
  DateTime _currentTime = DateTime.now();
  final ScheduleService _scheduleService = ScheduleService();
  bool _weatherLoading = true;
  bool _weatherFailed = false;
  String _currentTemp = '--';
  String _currentDesc = '--';
  String _currentIconPath = 'assets/weather-icons/clear_day.svg';
  DateTime? _sunrise;
  DateTime? _sunset;

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
    _loadWeather();
    _setupWeatherTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _weatherTimer?.cancel();
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
    {'day': '今天', 'iconPath': 'assets/weather-icons/clear_day.svg', 'high': 25, 'low': 18, 'desc': '晴'},
    {'day': '明天', 'iconPath': 'assets/weather-icons/cloudy_day_night.svg', 'high': 23, 'low': 16, 'desc': '多云'},
    {'day': '后天', 'iconPath': 'assets/weather-icons/rain_day_night.svg', 'high': 20, 'low': 14, 'desc': '小雨'},
    {'day': '周四', 'iconPath': 'assets/weather-icons/clear_day.svg', 'high': 26, 'low': 19, 'desc': '晴'},
    {'day': '周五', 'iconPath': 'assets/weather-icons/cloudy_day_night.svg', 'high': 24, 'low': 17, 'desc': '多云'},
    {'day': '周六', 'iconPath': 'assets/weather-icons/clear_day.svg', 'high': 27, 'low': 20, 'desc': '晴'},
    {'day': '周日', 'iconPath': 'assets/weather-icons/rain_day_night.svg', 'high': 22, 'low': 15, 'desc': '阵雨'},
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
                          SvgPicture.asset(
                            _currentIconPath,
                            width: 32.w,
                            height: 32.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _weatherLoading || _weatherFailed || _currentTemp == '--' ? '--' : '${_currentTemp}°C',
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
                        _weatherLoading || _weatherFailed ? '--' : _currentDesc,
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
                        SvgPicture.asset(
                          weather['iconPath'] as String,
                          width: 20.w,
                          height: 20.w,
                        ),
                        Text(
                          _weatherLoading || _weatherFailed || weather['high'] == null ? '--' : '${weather['high']}°',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _weatherLoading || _weatherFailed || weather['low'] == null ? '--' : '${weather['low']}°',
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
                        padding: EdgeInsets.fromLTRB(10.w - (isCurrentTime ? 2.0 : 0.0), 10.w, 10.w - (isCurrentTime ? 2.0 : 0.0), 10.w),
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
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            // 删除左侧竖线指示器
                            Container(
                              width: 90.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  SizedBox(height: 2.h),
                                  Text(
                                    course.endTime, // 结束时间
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: isCurrentTime 
                                          ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
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
                                      // 删除右侧“正在上课”标签，仅保留下方“进行中”
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
  
  Future<void> _loadWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final show = prefs.getBool('show_weather') ?? true;
    final cityId = prefs.getString('weather_city_id') ?? '';
    if (!show || cityId.isEmpty) {
      setState(() { _weatherLoading = false; _weatherFailed = true; _currentTemp = '--'; _currentDesc = '--'; });
      return;
    }
    setState(() { _weatherLoading = true; _weatherFailed = false; _currentTemp = '--'; _currentDesc = '--'; });
    final data = await WeatherService.instance.fetchByCityId(cityId, days: 7);
    if (!mounted) return;
    if (data == null) {
      setState(() { _weatherLoading = false; _weatherFailed = true; });
      return;
    }
    final daily = data.daily;
    final list = <Map<String, dynamic>>[];
    for (var i = 0; i < daily.length; i++) {
      final d = daily[i];
      list.add({
        'day': d.day,
        'iconPath': _iconAssetForCode(d.code),
        'high': d.high,
        'low': d.low,
      });
    }
    setState(() {
      _weatherLoading = false;
      _currentTemp = data.temperature ?? '--';
      _currentDesc = _labelForCode(data.currentCode) ?? '--';
      _currentIconPath = _iconAssetForCode(data.currentCode);
      _sunrise = data.sunrise;
      _sunset = data.sunset;
      if (list.isNotEmpty) {
        _weekWeather
          ..clear()
          ..addAll(list);
      }
    });
  }

  String _iconAssetForCode(int? code) {
    final now = DateTime.now();
    bool isDay;
    if (_sunrise != null && _sunset != null) {
      isDay = now.isAfter(_sunrise!) && now.isBefore(_sunset!);
    } else {
      final h = now.hour;
      isDay = h >= 6 && h < 18;
    }
    String choose(String day, String night) => isDay ? day : night;
    if (code == null) return 'assets/weather-icons/cloudy_day_night.svg';
    switch (code) {
      case 0:
        return choose('assets/weather-icons/clear_day.svg', 'assets/weather-icons/clear_night.svg');
      case 1:
        return choose('assets/weather-icons/partly_cloudy_day.svg', 'assets/weather-icons/partly_cloudy_night.svg');
      case 2:
        return 'assets/weather-icons/cloudy_day_night.svg';
      case 3:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
        return 'assets/weather-icons/rain_day_night.svg';
      case 4:
      case 5:
        return 'assets/weather-icons/thunderstorm_day_night.svg';
      case 6:
      case 19:
        return 'assets/weather-icons/sleet_day_night.svg';
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
      case 26:
      case 27:
      case 28:
      case 34:
        return 'assets/weather-icons/snow_day_night.svg';
      case 18:
        return 'assets/weather-icons/fog_day_night.svg';
      case 35:
      case 53:
        return choose('assets/weather-icons/haze_day.svg', 'assets/weather-icons/haze_night.svg');
      case 20:
      case 29:
      case 30:
      case 31:
      case 32:
      case 33:
        return 'assets/weather-icons/wind_day_night.svg';
      default:
        return 'assets/weather-icons/cloudy_day_night.svg';
    }
  }

  String? _labelForCode(int? code) {
    if (code == null) return null;
    switch (code) {
      case 0:
        return '晴';
      case 1:
        return '多云';
      case 2:
        return '阴';
      case 3:
        return '阵雨';
      case 4:
        return '雷阵雨';
      case 5:
        return '雷阵雨并伴有冰雹';
      case 6:
        return '雨夹雪';
      case 7:
        return '小雨';
      case 8:
        return '中雨';
      case 9:
        return '大雨';
      case 10:
        return '暴雨';
      case 11:
        return '大暴雨';
      case 12:
        return '特大暴雨';
      case 13:
        return '阵雪';
      case 14:
        return '小雪';
      case 15:
        return '中雪';
      case 16:
        return '大雪';
      case 17:
        return '暴雪';
      case 18:
        return '雾';
      case 19:
        return '冻雨';
      case 20:
        return '沙尘暴';
      case 21:
        return '小雨-中雨';
      case 22:
        return '中雨-大雨';
      case 23:
        return '大雨-暴雨';
      case 24:
        return '暴雨-大暴雨';
      case 25:
        return '大暴雨-特大暴雨';
      case 26:
        return '小雪-中雪';
      case 27:
        return '中雪-大雪';
      case 28:
        return '大雪-暴雪';
      case 29:
        return '浮沉';
      case 30:
        return '扬沙';
      case 31:
        return '强沙尘暴';
      case 32:
        return '飑';
      case 33:
        return '龙卷风';
      case 34:
        return '若高吹雪';
      case 35:
        return '轻雾';
      case 53:
        return '霾';
      case 99:
        return '未知';
      default:
        return null;
    }
  }

  Future<void> _setupWeatherTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt('weather_refresh_minutes') ?? 5;
    _weatherTimer?.cancel();
    _weatherTimer = Timer.periodic(Duration(minutes: minutes), (t) {
      _loadWeather();
    });
  }

  bool _isCurrentCourse(String timeRange) {
    final now = _currentTime;
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    int? parseToMinutes(String s) {
      final t = s.trim();
      final m = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(t);
      if (m == null) return null;
      final h = int.parse(m.group(1)!);
      final min = int.parse(m.group(2)!);
      return h * 60 + min;
    }
    final parts = timeRange.split('-');
    if (parts.length != 2) return false;
    final startMinutes = parseToMinutes(parts[0]);
    final endMinutes = parseToMinutes(parts[1]);
    if (startMinutes == null || endMinutes == null) return false;
    return currentTimeInMinutes >= startMinutes && currentTimeInMinutes <= endMinutes;
  }
}