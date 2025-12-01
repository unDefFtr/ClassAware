import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';

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
  List<DaySun> _sunList = const [];
  int _studentCount = 45;
  int _teacherCount = 5;
  String _className = '高三(1)班';
  String _headTeacher = '张老师';
  int _profileTick = 0;
  bool _editMode = false;
  List<_HomeCard> _cardOrder = [_HomeCard.timeWeather, _HomeCard.classInfo, _HomeCard.schedule];
  bool _gridOverlay = false;
  int? _overlayHighlightSlot;
  final GlobalKey _editDoneKey = GlobalKey();
  double _editOverlayHeight = 0.0;
  int? _recentDropSlot;
  Offset? _recentDropLocalOffset;
  _HomeCard? _recentOtherCard;
  int? _recentOtherSlot;
  Offset? _recentOtherStartGlobal;
  final List<GlobalKey> _slotKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重复初始化定时器

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
      _tickProfileRefresh();
    });
    // 加载本地课表数据
    _scheduleService.loadScheduleFromLocal();
    _loadWeather();
    _setupWeatherTimer();
    _loadCounts();
    _loadProfile();
    _loadCardOrder();
    _loadGridOverlay();
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = _editDoneKey.currentContext;
                final box = ctx?.findRenderObject() as RenderBox?;
                final hBtn = box?.size.height ?? 0.0;
                if (hBtn != _editOverlayHeight) {
                  setState(() { _editOverlayHeight = hBtn; });
                }
              });
              if (isWide) {
                return Stack(
                  children: [
                    AnimatedScale(
                      scale: _computeEditScale(h),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: _slotWrapper(0, _computeEditScale(h), _buildCardFor(_cardOrder[0], cardPadding)),
                              ),
                              SizedBox(height: 7.h),
                              Expanded(
                                child: _slotWrapper(1, _computeEditScale(h), _buildCardFor(_cardOrder[1], cardPadding)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          flex: 4,
                          child: _slotWrapper(2, _computeEditScale(h), _buildCardFor(_cardOrder[2], cardPadding)),
                        ),
                      ],
                      ),
                    ),
                    if (_editMode)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: FilledButton.tonal(
                          key: _editDoneKey,
                          onPressed: _exitEditMode,
                          child: const Text('完成'),
                        ),
                      ),
                    if (_gridOverlay)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedScale(
                            scale: _computeEditScale(h),
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: CustomPaint(
                              painter: _GridOverlayPainter(
                                mode: _GridMode.wide,
                                gapW: 7.w,
                                gapH: 7.h,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                highlightSlot: _overlayHighlightSlot,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              if (isMedium) {
                return Stack(
                  children: [
                    AnimatedScale(
                      scale: _computeEditScale(h),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _slotWrapper(0, _computeEditScale(h), _buildCardFor(_cardOrder[0], cardPadding)),
                              ),
                              SizedBox(width: 7.w),
                              Expanded(
                                child: _slotWrapper(1, _computeEditScale(h), _buildCardFor(_cardOrder[1], cardPadding)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Expanded(
                          child: _slotWrapper(2, _computeEditScale(h), _buildCardFor(_cardOrder[2], cardPadding)),
                        ),
                      ],
                      ),
                    ),
                    if (_editMode)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: FilledButton.tonal(
                          key: _editDoneKey,
                          onPressed: _exitEditMode,
                          child: const Text('完成'),
                        ),
                      ),
                    if (_gridOverlay)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedScale(
                            scale: _computeEditScale(h),
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: CustomPaint(
                              painter: _GridOverlayPainter(
                                mode: _GridMode.medium,
                                gapW: 7.w,
                                gapH: 7.h,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                highlightSlot: _overlayHighlightSlot,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Stack(
                children: [
                  AnimatedScale(
                    scale: _computeEditScale(h),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.linearToEaseOut,
                    child: SingleChildScrollView(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: h * 0.35,
                          child: _slotWrapper(0, _computeEditScale(h), _buildCardFor(_cardOrder[0], cardPadding)),
                        ),
                        SizedBox(height: 7.h),
                        SizedBox(
                          height: h * 0.25,
                          child: _slotWrapper(1, _computeEditScale(h), _buildCardFor(_cardOrder[1], cardPadding)),
                        ),
                        SizedBox(height: 7.h),
                        SizedBox(
                          height: h * 0.6,
                          child: _slotWrapper(2, _computeEditScale(h), _buildCardFor(_cardOrder[2], cardPadding)),
                        ),
                      ],
                      ),
                    ),
                  ),
                  if (_gridOverlay)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedScale(
                          scale: _computeEditScale(h),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: CustomPaint(
                            painter: _GridOverlayPainter(
                              mode: _GridMode.portrait,
                              gapW: 7.w,
                              gapH: 7.h,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                              highlightSlot: _overlayHighlightSlot,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _computeEditScale(double viewHeight) {
    if (!_editMode) return 1.0;
    final margin = 12.h;
    final neededTop = (_editOverlayHeight > 0 ? _editOverlayHeight : 48.0) + margin;
    final s = 1.0 - 2.0 * (neededTop / (viewHeight == 0 ? 1.0 : viewHeight));
    return s.clamp(0.85, 1.0);
  }

  Widget _buildCardFor(_HomeCard id, double cardPadding) {
    switch (id) {
      case _HomeCard.timeWeather:
        return _buildTimeWeatherCard(cardPadding);
      case _HomeCard.classInfo:
        return _buildClassInfoCard(cardPadding);
      case _HomeCard.schedule:
        return _buildTodaySchedule(cardPadding);
    }
  }

  Widget _slotWrapper(int slotIndex, double currentScale, Widget child) {
    final cardId = _cardOrder[slotIndex];
    final keyedChild = KeyedSubtree(key: ValueKey(cardId), child: child);
    if (!_editMode) {
      return GestureDetector(
        onLongPress: _enterEditMode,
        child: keyedChild,
      );
    }
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final fbW = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.w;
        final fbH = constraints.maxHeight.isFinite ? constraints.maxHeight : 120.h;
        final feedbackScale = currentScale;
        return DragTarget<_HomeCard>(
          onWillAcceptWithDetails: (details) {
            if (_gridOverlay) {
              setState(() { _overlayHighlightSlot = slotIndex; });
            }
            return true;
          },
          onAcceptWithDetails: (details) {
            final box = context.findRenderObject() as RenderBox?;
            final localPoint = box?.globalToLocal(details.offset) ?? Offset.zero;
            final startLocal = localPoint - Offset(fbW / 2, fbH / 2);
            setState(() { _recentDropLocalOffset = startLocal; });
            final srcIndex = _cardOrder.indexOf(details.data);
            final otherCard = _cardOrder[slotIndex];
            final slotTopLeft = box?.localToGlobal(Offset.zero) ?? Offset.zero;
            final toCenterGlobal = slotTopLeft + Offset(fbW / 2, fbH / 2);
            _recentOtherCard = otherCard;
            _recentOtherSlot = srcIndex;
            _recentOtherStartGlobal = toCenterGlobal;
            _moveCardToSlot(details.data, slotIndex);
            if (_gridOverlay) {
              setState(() { _overlayHighlightSlot = null; });
            }
          },
          onLeave: (_) {
            if (_gridOverlay) {
              setState(() { _overlayHighlightSlot = null; });
            }
          },
          builder: (context, candidate, rejected) {
            final snappedChild = (_recentDropSlot == slotIndex)
                ? TweenAnimationBuilder<Offset>(
                    tween: Tween<Offset>(
                      begin: _recentDropLocalOffset ?? Offset.zero,
                      end: Offset.zero,
                    ),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(width: fbW, height: fbH, child: keyedChild),
                    builder: (ctx, o, ch) => Transform.translate(offset: o, child: ch!),
                  )
                : keyedChild;
            return KeyedSubtree(
              key: _slotKeys[slotIndex],
              child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: candidate.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                ),
                Draggable<_HomeCard>(
                  data: cardId,
                  dragAnchorStrategy: childDragAnchorStrategy,
                  feedback: IgnorePointer(
                    ignoring: true,
                    child: Transform.scale(
                      scale: feedbackScale,
                      child: Opacity(
                        opacity: 0.9,
                        child: SizedBox(width: fbW, height: fbH, child: keyedChild),
                      ),
                    ),
                  ),
                  childWhenDragging: SizedBox(
                    width: fbW,
                    height: fbH,
                    child: Opacity(
                      opacity: 0.2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                  child: snappedChild,
                ),
              ],
            ),
          );
          },
        );
      },
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          _className,
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
                          '班主任：$_headTeacher',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildInfoItem('学生人数', '${_studentCount}人', Icons.people)),
                SizedBox(width: 8.w),
                Expanded(child: _buildInfoItem('老师人数', '${_teacherCount}人', Icons.person)),
              ],
            ),
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
      _sunList = data.sunList;
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
    DaySun? todayRange;
    if (_sunList.isNotEmpty) {
      todayRange = _sunList.firstWhere(
        (e) => e.from.year == now.year && e.from.month == now.month && e.from.day == now.day,
        orElse: () => _sunList.first,
      );
    }
    if (todayRange != null) {
      // 日间判定：在 [from, to) 区间内
      isDay = (now.isAfter(todayRange.from) || now.isAtSameMomentAs(todayRange.from)) && now.isBefore(todayRange.to);
    } else if (_sunrise != null && _sunset != null) {
      isDay = (now.isAfter(_sunrise!) || now.isAtSameMomentAs(_sunrise!)) && now.isBefore(_sunset!);
    } else {
      final h = now.hour;
      isDay = h >= 6 && h < 18;
    }
    if (kDebugMode) {
      final rangeStr = todayRange != null
          ? '${todayRange.from.toLocal()} -> ${todayRange.to.toLocal()}'
          : (_sunrise != null && _sunset != null
              ? '${_sunrise!.toLocal()} -> ${_sunset!.toLocal()}'
              : 'fallback 06:00-18:00');
      Log.d('now=${now.toLocal()} range=$rangeStr isDay=$isDay code=$code', tag: 'WeatherIcon');
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
  
  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentCount = prefs.getInt('student_count') ?? 45;
      _teacherCount = prefs.getInt('teacher_count') ?? 5;
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cls = prefs.getString('class_name') ?? '高三(1)班';
    final tch = prefs.getString('teacher_name') ?? '张老师';
    if (cls != _className || tch != _headTeacher) {
      setState(() {
        _className = cls;
        _headTeacher = tch;
      });
    }
  }

  void _tickProfileRefresh() {
    _profileTick = (_profileTick + 1) % 5;
    if (_profileTick == 0) {
      _loadProfile();
      _loadCounts();
      _loadGridOverlay();
    }
  }

  Future<void> _loadGridOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool('grid_overlay') ?? false;
    if (v != _gridOverlay) {
      setState(() { _gridOverlay = v; });
    }
  }

  Future<void> _loadCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('home_card_order');
    if (list == null || list.length != 3) return;
    final mapped = list.map(_homeCardFromKey).whereType<_HomeCard>().toList();
    if (mapped.length == 3) {
      setState(() { _cardOrder = mapped; });
    }
  }

  Future<void> _saveCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('home_card_order', _cardOrder.map(_homeCardKey).toList());
  }

  Future<void> _enterEditMode() async {
    if (_editMode) return;
    final ok = await AuthService.instance.ensureAuthenticated(context, reason: '编辑主页面');
    if (!mounted) return;
    if (ok) setState(() { _editMode = true; });
  }

  void _exitEditMode() {
    if (!_editMode) return;
    setState(() { _editMode = false; });
  }

  void _moveCardToSlot(_HomeCard card, int slotIndex) {
    final currentIndex = _cardOrder.indexOf(card);
    if (currentIndex == -1 || currentIndex == slotIndex) return;
    final next = List<_HomeCard>.from(_cardOrder);
    final temp = next[slotIndex];
    next[slotIndex] = card;
    next[currentIndex] = temp;
    setState(() { _cardOrder = next; _recentDropSlot = slotIndex; });
    _saveCardOrder();
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      if (_recentDropSlot == slotIndex) {
        setState(() {
          _recentDropSlot = null;
          _recentDropLocalOffset = null;
          _recentOtherCard = null;
          _recentOtherSlot = null;
          _recentOtherStartGlobal = null;
        });
      }
    });
  }

  void _previewMoveToSlot(_HomeCard card, int slotIndex) {}

  String _homeCardKey(_HomeCard c) {
    switch (c) {
      case _HomeCard.timeWeather: return 'timeWeather';
      case _HomeCard.classInfo: return 'classInfo';
      case _HomeCard.schedule: return 'schedule';
    }
  }

  _HomeCard? _homeCardFromKey(String k) {
    switch (k) {
      case 'timeWeather': return _HomeCard.timeWeather;
      case 'classInfo': return _HomeCard.classInfo;
      case 'schedule': return _HomeCard.schedule;
      default: return null;
    }
  }
}

enum _HomeCard { timeWeather, classInfo, schedule }

enum _GridMode { wide, medium, portrait }

class _GridOverlayPainter extends CustomPainter {
  final _GridMode mode;
  final double gapW;
  final double gapH;
  final Color color;
  final int? highlightSlot;
  _GridOverlayPainter({required this.mode, required this.gapW, required this.gapH, required this.color, this.highlightSlot});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final paintHL = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    Rect r(double x, double y, double w, double h) => Rect.fromLTWH(x, y, w, h);
    switch (mode) {
      case _GridMode.wide:
        final totalW = size.width;
        final totalH = size.height;
        final leftW = (totalW - gapW) * 3 / 7;
        final rightW = (totalW - gapW) * 4 / 7;
        final leftH = (totalH - gapH) / 2;
        final leftTop = r(0, 0, leftW, leftH);
        final leftBottom = r(0, leftH + gapH, leftW, leftH);
        final right = r(leftW + gapW, 0, rightW, totalH);
        final rects = [leftTop, leftBottom, right];
        for (var i = 0; i < rects.length; i++) {
          canvas.drawRect(rects[i], paint);
          if (highlightSlot == i) canvas.drawRect(rects[i], paintHL);
        }
        break;
      case _GridMode.medium:
        final totalW = size.width;
        final totalH = size.height;
        final topH = (totalH - gapH) / 2;
        final bottomH = totalH - topH - gapH;
        final leftW = (totalW - gapW) / 2;
        final rightW = leftW;
        final topLeft = r(0, 0, leftW, topH);
        final topRight = r(leftW + gapW, 0, rightW, topH);
        final bottom = r(0, topH + gapH, totalW, bottomH);
        final rects = [topLeft, topRight, bottom];
        for (var i = 0; i < rects.length; i++) {
          canvas.drawRect(rects[i], paint);
          if (highlightSlot == i) canvas.drawRect(rects[i], paintHL);
        }
        break;
      case _GridMode.portrait:
        final totalW = size.width;
        final totalH = size.height;
        final aH = totalH * 0.35;
        final bH = totalH * 0.25;
        final cH = totalH * 0.6;
        final top = r(0, 0, totalW, aH);
        final mid = r(0, aH + gapH, totalW, bH);
        final bot = r(0, aH + gapH + bH + gapH, totalW, cH);
        final rects = [top, mid, bot];
        for (var i = 0; i < rects.length; i++) {
          canvas.drawRect(rects[i], paint);
          if (highlightSlot == i) canvas.drawRect(rects[i], paintHL);
        }
        break;
    }
  }
  @override
  bool shouldRepaint(covariant _GridOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode || oldDelegate.gapW != gapW || oldDelegate.gapH != gapH || oldDelegate.color != color;
  }
}
