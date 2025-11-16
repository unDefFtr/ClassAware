import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_models.dart';

class WeatherService {
  static WeatherService? _instance;
  static const String _baseUrl = 'http://wthrcdn.etouch.cn';
  static const String _selectedCityKey = 'selected_city';
  static const String _weatherCacheKey = 'weather_cache';
  static const String _lastUpdateKey = 'weather_last_update';
  static const int _cacheValidityMinutes = 30; // 缓存有效期30分钟

  WeatherService._internal();

  factory WeatherService() {
    _instance ??= WeatherService._internal();
    return _instance!;
  }

  // 获取5天天气预报
  Future<WeatherForecast?> getWeatherForecast(String cityId) async {
    try {
      // 检查缓存
      final cachedData = await _getCachedWeatherData(cityId);
      if (cachedData != null) {
        return cachedData;
      }

      final url = '$_baseUrl/weather_mini?citykey=$cityId';
      print('正在获取天气预报: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 处理编码问题
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }

        final jsonData = json.decode(responseBody);
        
        if (jsonData['desc'] == 'OK') {
          final forecast = WeatherForecast.fromJson(jsonData);
          
          // 缓存数据
          await _cacheWeatherData(cityId, forecast);
          
          return forecast;
        } else {
          print('天气API返回错误: ${jsonData['desc']}');
          return null;
        }
      } else {
        print('HTTP请求失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取天气预报失败: $e');
      return null;
    }
  }

  // 获取实时天气信息
  Future<RealtimeWeather?> getRealtimeWeather(String cityId) async {
    try {
      final url = '$_baseUrl/weather_mini?citykey=$cityId';
      print('正在获取实时天气: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 处理编码问题
        String responseBody;
        try {
          responseBody = utf8.decode(response.bodyBytes);
        } catch (e) {
          responseBody = response.body;
        }

        final jsonData = json.decode(responseBody);
        
        if (jsonData['desc'] == 'OK') {
          // 从预报数据中提取实时天气信息
          final data = jsonData['data'];
          if (data != null) {
            return RealtimeWeather(
              sd: '${data['ganmao'] ?? ''}', // 感冒指数作为湿度替代
              wd: '', // 风向信息在这个API中不可用
              ws: '', // 风速信息在这个API中不可用
              city: data['city'] ?? '',
              cityId: cityId,
              temp: '${data['wendu'] ?? ''}',
              time: DateTime.now().toString(),
              weather: data['forecast']?[0]?['type'] ?? '',
            );
          }
        } else {
          print('天气API返回错误: ${jsonData['desc']}');
        }
      } else {
        print('HTTP请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取实时天气失败: $e');
    }
    return null;
  }

  // 缓存天气数据
  Future<void> _cacheWeatherData(String cityId, WeatherForecast forecast) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_weatherCacheKey}_$cityId';
      final timeKey = '${_lastUpdateKey}_$cityId';
      
      await prefs.setString(cacheKey, json.encode(forecast.toJson()));
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('缓存天气数据失败: $e');
    }
  }

  // 获取缓存的天气数据
  Future<WeatherForecast?> _getCachedWeatherData(String cityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_weatherCacheKey}_$cityId';
      final timeKey = '${_lastUpdateKey}_$cityId';
      
      final cachedData = prefs.getString(cacheKey);
      final lastUpdate = prefs.getInt(timeKey);
      
      if (cachedData != null && lastUpdate != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final cacheAge = (now - lastUpdate) / (1000 * 60); // 分钟
        
        if (cacheAge < _cacheValidityMinutes) {
          final jsonData = json.decode(cachedData);
          return WeatherForecast.fromJson(jsonData);
        }
      }
    } catch (e) {
      print('读取缓存天气数据失败: $e');
    }
    return null;
  }

  // 保存选中的城市
  Future<void> saveSelectedCity(City city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCityKey, json.encode(city.toMap()));
    } catch (e) {
      print('保存选中城市失败: $e');
    }
  }

  // 获取选中的城市
  Future<City?> getSelectedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityData = prefs.getString(_selectedCityKey);
      
      if (cityData != null) {
        final jsonData = json.decode(cityData);
        return City.fromMap(jsonData);
      }
    } catch (e) {
      print('获取选中城市失败: $e');
    }
    return null;
  }

  // 清除天气缓存
  Future<void> clearWeatherCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_weatherCacheKey) || key.startsWith(_lastUpdateKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('清除天气缓存失败: $e');
    }
  }

  // 检查网络连接并获取天气
  Future<WeatherInfo?> getWeatherInfo(String cityId) async {
    try {
      final forecast = await getWeatherForecast(cityId);
      final realtime = await getRealtimeWeather(cityId);
      
      if (forecast != null) {
        return WeatherInfo(
          forecast: forecast,
          realtime: realtime,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      print('获取天气信息失败: $e');
    }
    return null;
  }

  // 获取天气图标
  String getWeatherIcon(String weatherType) {
    switch (weatherType) {
      case '晴':
        return '☀️';
      case '多云':
        return '⛅';
      case '阴':
        return '☁️';
      case '小雨':
      case '中雨':
      case '大雨':
      case '暴雨':
        return '🌧️';
      case '雷阵雨':
        return '⛈️';
      case '小雪':
      case '中雪':
      case '大雪':
        return '❄️';
      case '雾':
        return '🌫️';
      case '霾':
        return '😷';
      default:
        return '🌤️';
    }
  }

  // 获取温度颜色
  String getTemperatureColor(int temperature) {
    if (temperature >= 35) {
      return '#FF4444'; // 红色 - 高温
    } else if (temperature >= 25) {
      return '#FF8800'; // 橙色 - 温暖
    } else if (temperature >= 15) {
      return '#44AA44'; // 绿色 - 舒适
    } else if (temperature >= 5) {
      return '#4488FF'; // 蓝色 - 凉爽
    } else {
      return '#8844FF'; // 紫色 - 寒冷
    }
  }
}