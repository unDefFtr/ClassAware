import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'package:yaml/yaml.dart';
import '../models/schedule_models.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static const String _scheduleKey = 'schedule_data';
  ScheduleData? _currentSchedule;

  // 获取当前课表
  ScheduleData? get currentSchedule => _currentSchedule;

  // 从本地存储加载课表
  Future<void> loadScheduleFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduleJson = prefs.getString(_scheduleKey);
      
      if (scheduleJson != null) {
        final Map<String, dynamic> data = jsonDecode(scheduleJson);
        _currentSchedule = ScheduleData.fromJson(data);
      }
    } catch (e, st) {
      Log.e('加载本地课表失败', tag: 'Schedule', error: e, stack: st);
    }
  }

  // 保存课表到本地存储
  Future<void> _saveScheduleToLocal() async {
    try {
      if (_currentSchedule != null) {
        final prefs = await SharedPreferences.getInstance();
        final scheduleJson = jsonEncode(_currentSchedule!.toJson());
        await prefs.setString(_scheduleKey, scheduleJson);
      }
    } catch (e, st) {
      Log.e('保存课表失败', tag: 'Schedule', error: e, stack: st);
    }
  }

  // 解析CSES文件
  Future<ScheduleData?> parseCSESFile(String content) async {
    try {
      return parseCSESContent(content);
    } catch (e, st) {
      Log.e('解析CSES文件失败', tag: 'Schedule', error: e, stack: st);
      return null;
    }
  }

  // 解析CSES内容
  ScheduleData parseCSESContent(String content) {
    final yamlData = loadYaml(content);
    final jsonData = _yamlToJson(yamlData);
    return ScheduleData.fromJson(jsonData as Map<String, dynamic>);
  }

  // 将YAML数据转换为JSON格式
  dynamic _yamlToJson(dynamic yamlData) {
    if (yamlData is YamlMap) {
      final Map<String, dynamic> result = {};
      for (final key in yamlData.keys) {
        final keyStr = key.toString();
        final value = _yamlToJson(yamlData[key]);
        result[keyStr] = value;
      }
      return result;
    } else if (yamlData is YamlList) {
      return yamlData.map((item) => _yamlToJson(item)).toList();
    } else {
      return yamlData;
    }
  }

  // 导入课表数据
  Future<void> importSchedule(ScheduleData schedule) async {
    _currentSchedule = schedule;
    await _saveScheduleToLocal();
  }

  // 获取指定日期的课程 - 新的CSES方式
  List<CourseInfo> getCoursesForDay(DateTime date) {
    if (_currentSchedule == null) return [];
    
    final dayOfWeek = date.weekday; // 1-7 表示周一到周日
    final weekType = _getWeekType(date); // 获取单双周
    final courses = <CourseInfo>[];
    
    // 获取当天的课程安排
    final classes = _currentSchedule!.getClassesForDay(dayOfWeek, weekType);
    
    // 构建课程信息
    for (final classItem in classes) {
      final subject = _currentSchedule!.subjects.firstWhere(
        (s) => s.name == classItem.subject,
        orElse: () => Subject(name: classItem.subject),
      );
      
      courses.add(CourseInfo.fromCSES(
        classItem: classItem,
        subject: subject,
      ));
    }
    
    return courses;
  }

  // 获取周类型（单周/双周）
  String _getWeekType(DateTime date) {
    // 简单实现：根据年份的第几周来判断单双周
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekOfYear = (dayOfYear / 7).ceil();
    return weekOfYear % 2 == 1 ? 'odd' : 'even';
  }

  // 获取所有课表名称
  List<String> getScheduleNames() {
    if (_currentSchedule == null) return [];
    return _currentSchedule!.schedules.map((s) => s.name).toList();
  }

  // 获取指定课表的详细信息
  Schedule? getScheduleByName(String name) {
    if (_currentSchedule == null) return null;
    try {
      return _currentSchedule!.schedules.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  // 获取所有科目
  List<Subject> getAllSubjects() {
    if (_currentSchedule == null) return [];
    return _currentSchedule!.subjects;
  }

  // 获取指定科目的详细信息
  Subject? getSubjectByName(String name) {
    if (_currentSchedule == null) return null;
    try {
      return _currentSchedule!.subjects.firstWhere((s) => s.name == name);
    } catch (e) {
      return null;
    }
  }

  // 清除当前课表
  Future<void> clearSchedule() async {
    _currentSchedule = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scheduleKey);
  }

  // 检查是否有课表数据
  bool hasScheduleData() {
    return _currentSchedule != null && 
           _currentSchedule!.schedules.isNotEmpty &&
           _currentSchedule!.subjects.isNotEmpty;
  }

  // 获取课表统计信息
  Map<String, int> getScheduleStats() {
    if (_currentSchedule == null) {
      return {
        'subjects': 0,
        'schedules': 0,
        'totalClasses': 0,
      };
    }

    int totalClasses = 0;
    for (final schedule in _currentSchedule!.schedules) {
      totalClasses += schedule.classes.length as int;
    }

    return {
      'subjects': _currentSchedule!.subjects.length,
      'schedules': _currentSchedule!.schedules.length,
      'totalClasses': totalClasses,
    };
  }
}