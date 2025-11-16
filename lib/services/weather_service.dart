import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

class WeatherService {
  static final WeatherService instance = WeatherService._();
  WeatherService._();

  Future<WeatherData?> fetchByCityId(String cityId, {int days = 7}) async {
    final key = cityId.startsWith('weathercn:') ? cityId : 'weathercn:$cityId';
    final uri = Uri.parse('https://weatherapi.market.xiaomi.com/wtr-v3/weather/all').replace(queryParameters: {
      'latitude': '0',
      'longitude': '0',
      'locationKey': key,
      'days': days.toString(),
      'appKey': 'weather20151024',
      'sign': 'zUFJoAR2ZVrDy1vF3D07',
      'isGlobal': 'false',
      'locale': 'zh_cn',
    });
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'ClassAware');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final jsonData = json.decode(body) as Map<String, dynamic>;
      return WeatherData.fromJson(jsonData);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

class WeatherData {
  final String? temperature;
  final String? description;
  final int? currentCode;
  final List<DailyWeather> daily;
  final DateTime? sunrise;
  final DateTime? sunset;
  WeatherData({this.temperature, this.description, this.currentCode, required this.daily, this.sunrise, this.sunset});
  factory WeatherData.fromJson(Map<String, dynamic> j) {
    String? temp;
    String? desc;
    int? code;
    final cur = j['current'] as Map<String, dynamic>?;
    if (cur != null) {
      final t = cur['temperature'] as Map<String, dynamic>?;
      temp = t?['value']?.toString();
      final w = cur['weather'];
      desc = w?.toString();
      code = int.tryParse(w?.toString() ?? '');
    }
    final dailyList = <DailyWeather>[];
    final fd = j['forecastDaily'] as Map<String, dynamic>?;
    final temps = fd?['temperature'] as Map<String, dynamic>?;
    final vals = temps?['value'] as List<dynamic>?;
    final weathers = fd?['weather'] as Map<String, dynamic>?;
    final wvals = weathers?['value'] as List<dynamic>?;
    DateTime? sr;
    DateTime? ss;
    final srs = fd?['sunRiseSet'] as Map<String, dynamic>?;
    final srVals = srs?['value'] as List<dynamic>?;
    if (srVals != null && srVals.isNotEmpty) {
      final today = srVals.first as Map<String, dynamic>;
      final from = today['from']?.toString();
      final to = today['to']?.toString();
      if (from != null) {
        try { sr = DateTime.parse(from); } catch (_) {}
      }
      if (to != null) {
        try { ss = DateTime.parse(to); } catch (_) {}
      }
    }
    final now = DateTime.now();
    if (vals != null) {
      for (int i = 0; i < vals.length; i++) {
        final v = vals[i] as Map<String, dynamic>;
        final from = int.tryParse(v['from']?.toString() ?? '');
        final to = int.tryParse(v['to']?.toString() ?? '');
        int? wcode;
        if (wvals != null && i < wvals.length) {
          final wv = wvals[i] as Map<String, dynamic>;
          wcode = int.tryParse(wv['from']?.toString() ?? '');
        }
        final day = now.add(Duration(days: i));
        final name = i == 0 ? '今天' : i == 1 ? '明天' : DateFormat.E('zh_CN').format(day);
        dailyList.add(DailyWeather(day: name, high: from, low: to, code: wcode));
        if (dailyList.length >= 7) break;
      }
    }
    return WeatherData(temperature: temp, description: desc, currentCode: code, daily: dailyList, sunrise: sr, sunset: ss);
  }
}

class DailyWeather {
  final String day;
  final int? high;
  final int? low;
  final int? code;
  DailyWeather({required this.day, this.high, this.low, this.code});
}