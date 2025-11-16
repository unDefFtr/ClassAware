// CSES 标准数据模型
class ScheduleData {
  final int version;
  final List<Subject> subjects;
  final List<Schedule> schedules;

  ScheduleData({
    required this.version,
    required this.subjects,
    required this.schedules,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      version: json['version'] ?? 1,
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map((item) => Subject.fromJson(item as Map<String, dynamic>))
          .toList(),
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map((item) => Schedule.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'schedules': schedules.map((s) => s.toJson()).toList(),
    };
  }

  // 为了向后兼容，提供旧的接口
  List<TimeSlot> get timeSlots {
    final slots = <TimeSlot>[];
    final timeSet = <String>{};
    
    for (final schedule in schedules) {
      for (final classItem in schedule.classes) {
        final timeKey = '${classItem.startTime}-${classItem.endTime}';
        if (!timeSet.contains(timeKey)) {
          timeSet.add(timeKey);
          slots.add(TimeSlot(
            id: 'slot_${slots.length + 1}',
            name: '${classItem.startTime}-${classItem.endTime}',
            startTime: classItem.startTime,
            endTime: classItem.endTime,
          ));
        }
      }
    }
    
    // 按开始时间排序
    slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  List<ScheduleEntry> get schedule {
    final entries = <ScheduleEntry>[];
    
    for (final scheduleItem in schedules) {
      for (final classItem in scheduleItem.classes) {
        // 找到对应的时间段ID
        final timeSlot = timeSlots.firstWhere(
          (slot) => slot.startTime == classItem.startTime && 
                   slot.endTime == classItem.endTime,
        );
        
        // 找到对应的科目
        final subject = subjects.firstWhere(
          (s) => s.name == classItem.subject,
          orElse: () => Subject(name: classItem.subject),
        );
        
        entries.add(ScheduleEntry(
          dayOfWeek: scheduleItem.enableDay.toString(),
          timeSlotId: timeSlot.id,
          subjectId: subject.name,
          room: subject.room,
          teacher: subject.teacher,
          weeks: scheduleItem.weeks,
        ));
      }
    }
    
    return entries;
  }

  // 获取指定日期和周数的课程安排
  List<ClassItem> getClassesForDay(int dayOfWeek, String weekType) {
    final classes = <ClassItem>[];
    
    for (final schedule in schedules) {
      if (schedule.enableDay == dayOfWeek && 
          (schedule.weeks == 'all' || schedule.weeks == weekType)) {
        classes.addAll(schedule.classes);
      }
    }
    
    // 按开始时间排序
    classes.sort((a, b) => a.startTime.compareTo(b.startTime));
    return classes;
  }
}

// CSES 科目模型
class Subject {
  final String name;
  final String? simplifiedName;
  final String? teacher;
  final String? room;
  final String? color; // UI用，不在CSES标准中

  Subject({
    required this.name,
    this.simplifiedName,
    this.teacher,
    this.room,
    this.color,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      name: json['name'] as String,
      simplifiedName: json['simplified_name'] as String?,
      teacher: json['teacher'] as String?,
      room: json['room'] as String?,
      color: json['color'] as String?, // UI扩展字段
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (simplifiedName != null) json['simplified_name'] = simplifiedName;
    if (teacher != null) json['teacher'] = teacher;
    if (room != null) json['room'] = room;
    if (color != null) json['color'] = color; // UI扩展字段
    return json;
  }
}

// CSES 课表模型
class Schedule {
  final String name;
  final int enableDay; // 1-7 表示周一到周日
  final String weeks; // all, odd, even
  final List<ClassItem> classes;

  Schedule({
    required this.name,
    required this.enableDay,
    required this.weeks,
    required this.classes,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      name: json['name'] as String,
      enableDay: json['enable_day'] as int,
      weeks: json['weeks'] as String,
      classes: (json['classes'] as List<dynamic>? ?? [])
          .map((item) => ClassItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'enable_day': enableDay,
      'weeks': weeks,
      'classes': classes.map((c) => c.toJson()).toList(),
    };
  }
}

// CSES 课程安排模型
class ClassItem {
  final String subject;
  final String startTime;
  final String endTime;

  ClassItem({
    required this.subject,
    required this.startTime,
    required this.endTime,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      subject: json['subject'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

// 为了向后兼容保留的模型
class TimeSlot {
  final String id;
  final String name;
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get timeRange => '$startTime - $endTime';
}

class ScheduleEntry {
  final String dayOfWeek;
  final String timeSlotId;
  final String subjectId;
  final String? room;
  final String? teacher;
  final String? note;
  final String? weeks; // 新增：周数信息

  ScheduleEntry({
    required this.dayOfWeek,
    required this.timeSlotId,
    required this.subjectId,
    this.room,
    this.teacher,
    this.note,
    this.weeks,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      dayOfWeek: json['day_of_week'] as String,
      timeSlotId: json['time_slot_id'] as String,
      subjectId: json['subject_id'] as String,
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
      note: json['note'] as String?,
      weeks: json['weeks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'time_slot_id': timeSlotId,
      'subject_id': subjectId,
      if (room != null) 'room': room,
      if (teacher != null) 'teacher': teacher,
      if (note != null) 'note': note,
      if (weeks != null) 'weeks': weeks,
    };
  }
}

class CourseInfo {
  final String name;
  final String shortName;
  final String teacher;
  final String room;
  final String startTime;
  final String endTime;
  final String color;

  CourseInfo({
    required this.name,
    required this.shortName,
    required this.teacher,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  factory CourseInfo.fromScheduleData({
    required ScheduleEntry entry,
    required Subject subject,
    required TimeSlot timeSlot,
  }) {
    return CourseInfo(
      name: subject.name,
      shortName: subject.simplifiedName ?? subject.name,
      teacher: subject.teacher ?? entry.teacher ?? '',
      room: subject.room ?? entry.room ?? '',
      startTime: timeSlot.startTime,
      endTime: timeSlot.endTime,
      color: subject.color ?? '#2196F3',
    );
  }

  // 从CSES数据直接创建
  factory CourseInfo.fromCSES({
    required ClassItem classItem,
    required Subject subject,
  }) {
    return CourseInfo(
      name: subject.name,
      shortName: subject.simplifiedName ?? subject.name,
      teacher: subject.teacher ?? '',
      room: subject.room ?? '',
      startTime: classItem.startTime,
      endTime: classItem.endTime,
      color: subject.color ?? '#2196F3',
    );
  }
}