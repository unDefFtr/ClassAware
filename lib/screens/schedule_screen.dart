import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../models/schedule_models.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with AutomaticKeepAliveClientMixin {
  final ScheduleService _scheduleService = ScheduleService();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    await _scheduleService.loadScheduleFromLocal();
    setState(() => _isLoading = false);
  }

  Future<void> _importCSESFile() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['yaml', 'yml'],
          dialogTitle: '选择CSES课表文件',
          withData: true,
        );
      } on PlatformException catch (e) {
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('unsupported')) {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            dialogTitle: '选择CSES课表文件',
            withData: true,
          );
        } else {
          rethrow;
        }
      }

      if (result != null) {
        final file = result.files.single;
        final name = file.name.toLowerCase();
        if (!name.endsWith('.yaml') && !name.endsWith('.yml')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('请选择 .yaml 或 .yml 文件')),
            );
          }
          return;
        }

        if (file.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法读取文件内容')),
            );
          }
          return;
        }

        setState(() => _isLoading = true);
        final content = utf8.decode(file.bytes!);
        final schedule = await _scheduleService.parseCSESFile(content);

        if (schedule != null) {
          await _scheduleService.importSchedule(schedule);
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('课表导入成功！')),
            );
          }
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('导入失败：文件格式不正确')),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _clearSchedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要清除当前课表吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _scheduleService.clearSchedule();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课表已清除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scheduleService.hasScheduleData()
              ? _buildScheduleView()
              : _buildEmptyView(),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 120.w,
            color: Theme.of(context).colorScheme.outline,
          ),
          SizedBox(height: 24.h),
          Text(
            '暂无课表数据',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '请导入CSES格式的课表文件或连接ClassIsland',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _importCSESFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('导入CSES文件'),
              ),
              SizedBox(width: 16.w),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ClassIsland连接功能敬请期待')),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('连接ClassIsland'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView() {
    final schedule = _scheduleService.currentSchedule!;
    final todayCourses = _scheduleService.getCoursesForDay(DateTime.now());
    final currentCourse = _getCurrentCourse(todayCourses);
    final nextCourse = _getNextCourse(todayCourses);

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 课表标题和操作按钮
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.schedules.isNotEmpty ? schedule.schedules.first.name : '课表',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '版本: ${schedule.version}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '共${schedule.schedules.length}个课表，${schedule.subjects.length}门课程',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'import':
                      _importCSESFile();
                      break;
                    case 'clear':
                      _clearSchedule();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.file_upload),
                      title: Text('重新导入'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('清除课表'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 32.h),
          
          // 两列布局
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：当前状态和今日课程
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 当前状态卡片
                    _buildCurrentStatusCard(currentCourse, nextCourse),
                    
                    SizedBox(height: 24.h),
                    
                    // 今日课程
                    _buildTodaySchedule(todayCourses),
                  ],
                ),
              ),
              
              SizedBox(width: 24.w),
              
              // 右侧：周课表
              Expanded(
                flex: 2,
                child: _buildWeeklySchedule(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 获取当前正在进行的课程
  CourseInfo? _getCurrentCourse(List<CourseInfo> todayCourses) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (final course in todayCourses) {
      final startTime = course.startTime;
      final endTime = course.endTime;
      
      if (currentTime.compareTo(startTime) >= 0 && 
          currentTime.compareTo(endTime) <= 0) {
        return course;
      }
    }
    
    return null;
  }

  // 获取下一节课程
  CourseInfo? _getNextCourse(List<CourseInfo> todayCourses) {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (final course in todayCourses) {
      final startTime = course.startTime;
      
      if (currentTime.compareTo(startTime) < 0) {
        return course;
      }
    }
    
    return null;
  }

  Widget _buildCurrentStatusCard(CourseInfo? currentCourse, CourseInfo? nextCourse) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '当前状态',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (currentCourse != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '正在上课: ${currentCourse.name}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${currentCourse.startTime}-${currentCourse.endTime} | ${currentCourse.teacher} | ${currentCourse.room}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (nextCourse != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '下节课: ${nextCourse.name}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${nextCourse.startTime}-${nextCourse.endTime} | ${nextCourse.teacher} | ${nextCourse.room}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.free_breakfast,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '当前无课程安排',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(List<CourseInfo> todayCourses) {
    final today = DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日课程 ($today)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        if (todayCourses.isEmpty) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: Text(
                  '今日无课程安排',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          ...todayCourses.map((course) => _buildCourseCard(course)),
        ],
      ],
    );
  }

  Widget _buildCourseCard(CourseInfo course) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            course.name.substring(0, 1),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间: ${course.startTime}-${course.endTime}'),
            if (course.teacher.isNotEmpty) Text('教师: ${course.teacher}'),
            if (course.room.isNotEmpty) Text('地点: ${course.room}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '周课表',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: List.generate(7, (index) {
                final dayOfWeek = index + 1; // 1-7 表示周一到周日
                final dayName = weekDays[index];
                final now = DateTime.now();
                final targetDate = now.subtract(Duration(days: now.weekday - dayOfWeek));
                final courses = _scheduleService.getCoursesForDay(targetDate);
                
                return ExpansionTile(
                  title: Text(
                    dayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${courses.length}节课'),
                  children: courses.isEmpty
                      ? [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              '无课程安排',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ]
                      : courses.map((course) => ListTile(
                            dense: true,
                            title: Text(course.name),
                      subtitle: Text('${course.startTime}-${course.endTime}'),
                      trailing: Text(course.room),
                          )).toList(),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}