import 'dart:convert';
import 'dart:io';
import '../utils/logger.dart';
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
      Log.d('请求天气数据 key=$key days=$days', tag: 'Weather');
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'ClassAware');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        Log.w('天气接口返回非200: ${res.statusCode}', tag: 'Weather');
        return null;
      }
      final body = await res.transform(utf8.decoder).join();
      Log.t('天气响应长度=${body.length}', tag: 'Weather');
      final jsonData = json.decode(body) as Map<String, dynamic>;
      return WeatherData.fromJson(jsonData);
    } catch (e, st) {
      Log.e('天气请求失败', tag: 'Weather', error: e, stack: st);
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
  final List<DaySun> sunList;
  WeatherData({this.temperature, this.description, this.currentCode, required this.daily, this.sunrise, this.sunset, required this.sunList});
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
    final suns = <DaySun>[];
    final srs = fd?['sunRiseSet'] as Map<String, dynamic>?;
    final srVals = srs?['value'] as List<dynamic>?;
    if (srVals != null && srVals.isNotEmpty) {
      for (final v in srVals) {
        if (v is Map) {
          final f = v['from']?.toString();
          final t = v['to']?.toString();
          if (f != null && t != null) {
            try {
              final df = DateTime.parse(f).toLocal();
              final dt = DateTime.parse(t).toLocal();
              suns.add(DaySun(from: df, to: dt));
            } catch (_) {}
          }
        }
      }
      // 找到与今天匹配的时间段作为当前sunrise/sunset
      final today = DateTime.now();
      final match = suns.firstWhere(
        (e) => e.from.year == today.year && e.from.month == today.month && e.from.day == today.day,
        orElse: () => suns.isNotEmpty ? suns.first : DaySun(from: DateTime(today.year, today.month, today.day, 6), to: DateTime(today.year, today.month, today.day, 18)),
      );
      sr = match.from;
      ss = match.to;
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
    return WeatherData(temperature: temp, description: desc, currentCode: code, daily: dailyList, sunrise: sr, sunset: ss, sunList: suns);
  }
}

class DaySun {
  final DateTime from;
  final DateTime to;
  DaySun({required this.from, required this.to});
}

class DailyWeather {
  final String day;
  final int? high;
  final int? low;
  final int? code;
  DailyWeather({required this.day, this.high, this.low, this.code});
}