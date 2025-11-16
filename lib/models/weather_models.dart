// 城市信息模型
class City {
  final int id;
  final int provinceId;
  final String name;
  final String cityNum;

  City({
    required this.id,
    required this.provinceId,
    required this.name,
    required this.cityNum,
  });

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['_id'] ?? 0,
      provinceId: map['province_id'] ?? 0,
      name: map['name'] ?? '',
      cityNum: map['city_num'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'province_id': provinceId,
      'name': name,
      'city_num': cityNum,
    };
  }
}

// 省份信息模型
class Province {
  final int id;
  final String name;

  Province({
    required this.id,
    required this.name,
  });

  factory Province.fromMap(Map<String, dynamic> map) {
    return Province(
      id: map['_id'] ?? 0,
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

// 实时天气信息模型
class RealtimeWeather {
  final String sd; // 湿度
  final String wd; // 风向
  final String ws; // 风速
  final String city; // 城市名称
  final String cityId; // 城市ID
  final String temp; // 温度
  final String time; // 时间
  final String weather; // 天气状况

  RealtimeWeather({
    required this.sd,
    required this.wd,
    required this.ws,
    required this.city,
    required this.cityId,
    required this.temp,
    required this.time,
    required this.weather,
  });

  factory RealtimeWeather.fromJson(Map<String, dynamic> json) {
    final weatherInfo = json['weatherinfo'] ?? {};
    return RealtimeWeather(
      sd: weatherInfo['SD'] ?? '',
      wd: weatherInfo['WD'] ?? '',
      ws: weatherInfo['WS'] ?? '',
      city: weatherInfo['city'] ?? '',
      cityId: weatherInfo['cityid'] ?? '',
      temp: weatherInfo['temp'] ?? '',
      time: weatherInfo['time'] ?? '',
      weather: weatherInfo['weather'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weatherinfo': {
        'SD': sd,
        'WD': wd,
        'WS': ws,
        'city': city,
        'cityid': cityId,
        'temp': temp,
        'time': time,
        'weather': weather,
      },
    };
  }
}

// 天气预报信息模型
class WeatherForecast {
  final String city; // 城市名称
  final String cityId; // 城市ID
  final String dateY; // 日期
  final String week; // 星期
  final String temp1; // 今天温度
  final String temp2; // 明天温度
  final String temp3; // 后天温度
  final String temp4; // 第四天温度
  final String temp5; // 第五天温度
  final String weather1; // 今天天气
  final String weather2; // 明天天气
  final String weather3; // 后天天气
  final String weather4; // 第四天天气
  final String weather5; // 第五天天气
  final String wind1; // 今天风向
  final String wind2; // 明天风向
  final String wind3; // 后天风向
  final String wind4; // 第四天风向
  final String wind5; // 第五天风向
  final String fl1; // 今天风力
  final String fl2; // 明天风力
  final String fl3; // 后天风力
  final String fl4; // 第四天风力
  final String fl5; // 第五天风力

  WeatherForecast({
    required this.city,
    required this.cityId,
    required this.dateY,
    required this.week,
    required this.temp1,
    required this.temp2,
    required this.temp3,
    required this.temp4,
    required this.temp5,
    required this.weather1,
    required this.weather2,
    required this.weather3,
    required this.weather4,
    required this.weather5,
    required this.wind1,
    required this.wind2,
    required this.wind3,
    required this.wind4,
    required this.wind5,
    required this.fl1,
    required this.fl2,
    required this.fl3,
    required this.fl4,
    required this.fl5,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final weatherInfo = json['weatherinfo'] ?? {};
    return WeatherForecast(
      city: weatherInfo['city'] ?? '',
      cityId: weatherInfo['cityid'] ?? '',
      dateY: weatherInfo['date_y'] ?? '',
      week: weatherInfo['week'] ?? '',
      temp1: weatherInfo['temp1'] ?? '',
      temp2: weatherInfo['temp2'] ?? '',
      temp3: weatherInfo['temp3'] ?? '',
      temp4: weatherInfo['temp4'] ?? '',
      temp5: weatherInfo['temp5'] ?? '',
      weather1: weatherInfo['weather1'] ?? '',
      weather2: weatherInfo['weather2'] ?? '',
      weather3: weatherInfo['weather3'] ?? '',
      weather4: weatherInfo['weather4'] ?? '',
      weather5: weatherInfo['weather5'] ?? '',
      wind1: weatherInfo['wind1'] ?? '',
      wind2: weatherInfo['wind2'] ?? '',
      wind3: weatherInfo['wind3'] ?? '',
      wind4: weatherInfo['wind4'] ?? '',
      wind5: weatherInfo['wind5'] ?? '',
      fl1: weatherInfo['fl1'] ?? '',
      fl2: weatherInfo['fl2'] ?? '',
      fl3: weatherInfo['fl3'] ?? '',
      fl4: weatherInfo['fl4'] ?? '',
      fl5: weatherInfo['fl5'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weatherinfo': {
        'city': city,
        'cityid': cityId,
        'date_y': dateY,
        'week': week,
        'temp1': temp1,
        'temp2': temp2,
        'temp3': temp3,
        'temp4': temp4,
        'temp5': temp5,
        'weather1': weather1,
        'weather2': weather2,
        'weather3': weather3,
        'weather4': weather4,
        'weather5': weather5,
        'wind1': wind1,
        'wind2': wind2,
        'wind3': wind3,
        'wind4': wind4,
        'wind5': wind5,
        'fl1': fl1,
        'fl2': fl2,
        'fl3': fl3,
        'fl4': fl4,
        'fl5': fl5,
      },
    };
  }

  // 获取指定天数的天气信息
  DailyWeather getDayWeather(int day) {
    switch (day) {
      case 1:
        return DailyWeather(
          temp: temp1,
          weather: weather1,
          wind: wind1,
          windLevel: fl1,
        );
      case 2:
        return DailyWeather(
          temp: temp2,
          weather: weather2,
          wind: wind2,
          windLevel: fl2,
        );
      case 3:
        return DailyWeather(
          temp: temp3,
          weather: weather3,
          wind: wind3,
          windLevel: fl3,
        );
      case 4:
        return DailyWeather(
          temp: temp4,
          weather: weather4,
          wind: wind4,
          windLevel: fl4,
        );
      case 5:
        return DailyWeather(
          temp: temp5,
          weather: weather5,
          wind: wind5,
          windLevel: fl5,
        );
      default:
        return DailyWeather(
          temp: temp1,
          weather: weather1,
          wind: wind1,
          windLevel: fl1,
        );
    }
  }
}

// 单日天气信息模型
class DailyWeather {
  final String temp;
  final String weather;
  final String wind;
  final String windLevel;

  DailyWeather({
    required this.temp,
    required this.weather,
    required this.wind,
    required this.windLevel,
  });
}

// 综合天气信息模型
class WeatherInfo {
  final RealtimeWeather? realtime;
  final WeatherForecast? forecast;
  final DateTime lastUpdated;

  WeatherInfo({
    this.realtime,
    this.forecast,
    required this.lastUpdated,
  });

  // 检查数据是否需要更新（超过30分钟）
  bool get needsUpdate {
    return DateTime.now().difference(lastUpdated).inMinutes > 30;
  }

  // 获取当前温度
  String get currentTemp {
    return realtime?.temp ?? forecast?.temp1.split('~').first.replaceAll('℃', '') ?? '--';
  }

  // 获取当前天气状况
  String get currentWeather {
    return realtime?.weather ?? forecast?.weather1.split('转').first ?? '--';
  }

  // 获取当前城市
  String get cityName {
    return realtime?.city ?? forecast?.city ?? '';
  }
}