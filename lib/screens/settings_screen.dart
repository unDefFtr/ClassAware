import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoRefresh = true;
  bool _showWeather = true;
  bool _enableNotifications = true;
  bool _darkMode = false;
  double _fontSize = 16.0;
  String _className = '高三(1)班';
  String _teacherName = '张老师';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoRefresh = prefs.getBool('auto_refresh') ?? true;
      _showWeather = prefs.getBool('show_weather') ?? true;
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _fontSize = prefs.getDouble('font_size') ?? 16.0;
      _className = prefs.getString('class_name') ?? '高三(1)班';
      _teacherName = prefs.getString('teacher_name') ?? '张老师';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 班级信息设置
          _buildSectionCard(
            title: '班级信息',
            icon: Icons.school,
            children: [
              _buildTextFieldTile(
                title: '班级名称',
                value: _className,
                onChanged: (value) {
                  setState(() {
                    _className = value;
                  });
                  _saveSetting('class_name', value);
                },
              ),
              _buildTextFieldTile(
                title: '班主任姓名',
                value: _teacherName,
                onChanged: (value) {
                  setState(() {
                    _teacherName = value;
                  });
                  _saveSetting('teacher_name', value);
                },
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // 显示设置
          _buildSectionCard(
            title: '显示设置',
            icon: Icons.display_settings,
            children: [
              _buildSwitchTile(
                title: '深色模式',
                subtitle: '启用深色主题',
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                  _saveSetting('dark_mode', value);
                },
              ),
              _buildSliderTile(
                title: '字体大小',
                subtitle: '调整应用字体大小',
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                  _saveSetting('font_size', value);
                },
              ),
              _buildSwitchTile(
                title: '显示天气',
                subtitle: '在主页显示天气信息',
                value: _showWeather,
                onChanged: (value) {
                  setState(() {
                    _showWeather = value;
                  });
                  _saveSetting('show_weather', value);
                },
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // 功能设置
          _buildSectionCard(
            title: '功能设置',
            icon: Icons.settings,
            children: [
              _buildSwitchTile(
                title: '自动刷新',
                subtitle: '自动更新课程表和时间',
                value: _autoRefresh,
                onChanged: (value) {
                  setState(() {
                    _autoRefresh = value;
                  });
                  _saveSetting('auto_refresh', value);
                },
              ),
              _buildSwitchTile(
                title: '通知提醒',
                subtitle: '课程开始前提醒',
                value: _enableNotifications,
                onChanged: (value) {
                  setState(() {
                    _enableNotifications = value;
                  });
                  _saveSetting('enable_notifications', value);
                },
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // 系统信息
          _buildSectionCard(
            title: '系统信息',
            icon: Icons.info,
            children: [
              _buildInfoTile('应用版本', '1.0.0'),
              _buildInfoTile('系统版本', 'Android 12'),
              _buildInfoTile('设备型号', 'Class Board Pro'),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // 操作按钮
          _buildActionButtons(),
          
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24.w,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14.sp),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextStyle(fontSize: 16.sp),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 14.sp),
          ),
          trailing: Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 16.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _resetSettings,
            icon: const Icon(Icons.refresh),
            label: const Text('重置设置'),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exportSettings,
            icon: const Icon(Icons.download),
            label: const Text('导出配置'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAboutDialog,
            icon: const Icon(Icons.help),
            label: const Text('关于应用'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置到默认值吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已重置')),
        );
      }
    }
  }

  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('配置导出功能开发中...')),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '电子班牌',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.school,
        size: 48.w,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        Text(
          '智能电子班牌应用，为现代化教室提供信息展示和应用管理功能。',
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }
}