import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/city_database_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  bool _autoRefresh = true;
  bool _showWeather = true;
  bool _enableNotifications = true;
  bool _darkMode = false;
  double _fontSize = 16.0;
  String _className = '高三(1)班';
  String _teacherName = '张老师';
  String _weatherCityId = '';
  int _weatherRefreshMinutes = 5;
  bool _authEnabled = false;
  bool _lockApps = true;
  bool _lockSettings = true;
  bool _authUsePin = true;
  bool _authUseBio = false;
  bool _authUseNfc = false;
  List<String> _authNfcUids = [];
  int _authUnlockMinutes = 10;
  final TextEditingController _unlockMinutesController = TextEditingController(text: '10');
  bool _authHighSecurity = false;
  final TextEditingController _weatherRefreshController = TextEditingController(text: '5');

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重复加载设置

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
      _weatherCityId = prefs.getString('weather_city_id') ?? '';
      _weatherRefreshMinutes = prefs.getInt('weather_refresh_minutes') ?? 5;
      _weatherRefreshController.text = _weatherRefreshMinutes.toString();
      _authEnabled = prefs.getBool('auth_enabled') ?? false;
      _lockApps = prefs.getBool('lock_apps') ?? true;
      _lockSettings = prefs.getBool('lock_settings') ?? true;
      _authUsePin = prefs.getBool('auth_use_pin') ?? true;
      _authUseBio = prefs.getBool('auth_use_bio') ?? false;
      _authUseNfc = prefs.getBool('auth_use_nfc') ?? false;
      _authNfcUids = prefs.getStringList('auth_nfc_uids') ?? [];
      _authUnlockMinutes = prefs.getInt('auth_unlock_minutes') ?? 10;
      _unlockMinutesController.text = _authUnlockMinutes.toString();
      _authHighSecurity = prefs.getBool('auth_high_security') ?? false;
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
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  void _openCitySearch() async {
    final service = CityDatabaseService();
    final popular = await service.getPopularCities();
    final controller = TextEditingController();
    List<City> results = popular;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('搜索城市'),
              content: SizedBox(
                width: 480.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '输入城市名称，如 北京',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) async {
                        final q = v.trim();
                        final list = q.isEmpty ? await service.getPopularCities() : await service.searchCitiesByName(q);
                        setState(() { results = list; });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 360,
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final c = results[i];
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text('编码: ${c.cityNum}'),
                            onTap: () { Navigator.of(ctx).pop(c.cityNum); },
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消'))
              ],
            );
          },
        );
      },
    ).then((value) {
      if (value is String && value.isNotEmpty) {
        setState(() { _weatherCityId = value; });
        _saveSetting('weather_city_id', value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保持页面状态
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16.w),
        physics: const BouncingScrollPhysics(),
        children: [
          // 班级信息设置
          RepaintBoundary( // 添加重绘边界优化
            child: _buildSectionCard(
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
          ),
          
          SizedBox(height: 16.h),
          RepaintBoundary(
            child: _buildSectionCard(
              title: '身份验证',
              icon: Icons.verified_user,
              children: [
                _buildSwitchTile(
                  title: '启用页面锁定',
                  subtitle: '保护敏感页面',
                  value: _authEnabled,
                  onChanged: (v) {
                    setState(() { _authEnabled = v; });
                    _saveSetting('auth_enabled', v);
                  },
                ),
                _buildSwitchTile(
                  title: '锁定所有应用',
                  subtitle: '访问应用需要验证',
                  value: _lockApps,
                  onChanged: (v) {
                    setState(() { _lockApps = v; });
                    _saveSetting('lock_apps', v);
                  },
                ),
                _buildSwitchTile(
                  title: '锁定设置页',
                  subtitle: '更改设置需要验证',
                  value: _lockSettings,
                  onChanged: (v) {
                    setState(() { _lockSettings = v; });
                    _saveSetting('lock_settings', v);
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: '允许数字密码',
                  subtitle: '使用数字密码解锁',
                  value: _authUsePin,
                  onChanged: (v) {
                    setState(() { _authUsePin = v; });
                    _saveSetting('auth_use_pin', v);
                  },
                ),
                _buildSwitchTile(
                  title: '允许人脸/生物识别',
                  subtitle: '使用系统生物识别',
                  value: _authUseBio,
                  onChanged: (v) {
                    setState(() { _authUseBio = v; });
                    _saveSetting('auth_use_bio', v);
                  },
                ),
              _buildSwitchTile(
                title: '允许 NFC 卡片',
                subtitle: '绑定授权卡片解锁',
                value: _authUseNfc,
                onChanged: (v) {
                  setState(() { _authUseNfc = v; });
                  _saveSetting('auth_use_nfc', v);
                },
              ),
              _buildSwitchTile(
                title: '高安全性',
                subtitle: '离开敏感页面后立即锁定',
                value: _authHighSecurity,
                onChanged: (v) {
                  setState(() { _authHighSecurity = v; });
                  _saveSetting('auth_high_security', v);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('会话时长'),
                // subtitle: Text('当前 $_authUnlockMinutes 分钟'),
                subtitle: Text('每次解锁后的会话时长(分钟)'),
                trailing: SizedBox(
                  width: 120.w,
                  child: TextField(
                    controller: _unlockMinutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (v) {
                      final parsed = int.tryParse(v);
                      final mins = (parsed ?? _authUnlockMinutes).clamp(1, 180);
                      setState(() { _authUnlockMinutes = mins; _unlockMinutesController.text = mins.toString(); });
                      _saveSetting('auth_unlock_minutes', mins);
                    },
                    decoration: const InputDecoration(hintText: '1-180'),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _setPin,
                      icon: const Icon(Icons.password),
                      label: const Text('设置数字密码'),
                    ),
                    SizedBox(width: 8.w),
                    OutlinedButton.icon(
                      onPressed: _addNfcUid,
                      icon: const Icon(Icons.nfc),
                      label: const Text('添加 NFC 卡'),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _authNfcUids.map((uid) => Chip(
                    label: Text(uid),
                    onDeleted: () {
                      setState(() { _authNfcUids.remove(uid); });
                      _saveSetting('auth_nfc_uids', _authNfcUids);
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          
          // 显示设置
          RepaintBoundary( // 添加重绘边界优化
            child: _buildSectionCard(
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openCitySearch,
                      icon: const Icon(Icons.search),
                      label: const Text('搜索城市并填充编码'),
                    ),
                  ),
                ),
                if (_weatherCityId.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('已选择编码: $_weatherCityId',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('天气刷新频率(分钟)'),
                  subtitle: const Text('默认 5，范围 1-60'),
                  trailing: SizedBox(
                    width: 120.w,
                    child: TextField(
                      controller: _weatherRefreshController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (v) {
                        final parsed = int.tryParse(v);
                        final mins = (parsed ?? _weatherRefreshMinutes).clamp(1, 60);
                        setState(() { _weatherRefreshMinutes = mins; _weatherRefreshController.text = mins.toString(); });
                        _saveSetting('weather_refresh_minutes', mins);
                      },
                      decoration: const InputDecoration(hintText: '1-60'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // 功能设置
          RepaintBoundary( // 添加重绘边界优化
            child: _buildSectionCard(
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
          ),
          
          SizedBox(height: 16.h),
          
          // 系统信息
          RepaintBoundary( // 添加重绘边界优化
            child: _buildSectionCard(
              title: '系统信息',
              icon: Icons.info,
              children: [
                _buildInfoTile('应用版本', '1.0.0'),
                _buildInfoTile('系统版本', 'Android 12'),
                _buildInfoTile('设备型号', 'Class Board Pro'),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // 操作按钮
          RepaintBoundary( // 添加重绘边界优化
            child: _buildActionButtons(),
          ),
          
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _unlockMinutesController.dispose();
    AuthService.instance.lockIfHighSecurity();
    super.dispose();
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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
    return RepaintBoundary( // 添加重绘边界优化
      child: ListTile(
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
    return RepaintBoundary( // 添加重绘边界优化
      child: Column(
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
      ),
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return RepaintBoundary( // 添加重绘边界优化
      child: Padding(
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
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return RepaintBoundary( // 添加重绘边界优化
      child: ListTile(
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

  Future<void> _setPin() async {
    final a = TextEditingController();
    final b = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置数字密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, keyboardType: TextInputType.number, controller: a, decoration: const InputDecoration(labelText: '新密码')),
            TextField(obscureText: true, keyboardType: TextInputType.number, controller: b, decoration: const InputDecoration(labelText: '确认密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('保存')),
        ],
      ),
    );
    if (ok == true) {
      final s1 = a.text.trim();
      final s2 = b.text.trim();
      if (s1.isNotEmpty && s1 == s2) {
        final hash = sha256.convert(utf8.encode(s1)).toString();
        await _saveSetting('auth_pin_hash', hash);
        setState(() { _authEnabled = true; });
        await _saveSetting('auth_enabled', true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已更新')));
        }
      }
    }
  }

  Future<void> _addNfcUid() async {
    final uid = await AuthService.instance.readNfcUidOnce();
    if (uid != null && uid.isNotEmpty) {
      setState(() { _authNfcUids = {..._authNfcUids, uid}.toList(); });
      await _saveSetting('auth_nfc_uids', _authNfcUids);
      setState(() { _authEnabled = true; });
      await _saveSetting('auth_enabled', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已添加卡片')));
      }
      return;
    }
    final controller = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入卡 UID'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('添加')),
        ],
      ),
    );
    if (ok == true) {
      final s = controller.text.trim();
      if (s.isNotEmpty) {
        setState(() { _authNfcUids = {..._authNfcUids, s}.toList(); });
        await _saveSetting('auth_nfc_uids', _authNfcUids);
        setState(() { _authEnabled = true; });
        await _saveSetting('auth_enabled', true);
      }
    }
  }

  

  
}