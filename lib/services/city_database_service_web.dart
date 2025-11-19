import 'dart:convert';
import 'package:flutter/services.dart';

class CityDatabaseService {
  List<Province>? _provinces;
  List<City>? _cities;
  CityDatabaseService();

  Future<void> _ensureLoaded() async {
    if (_provinces != null && _cities != null) return;
    try {
      final s = await rootBundle.loadString('assets/xiaomi_weather.json');
      final data = json.decode(s) as Map<String, dynamic>;
      final ps = (data['provinces'] as List?) ?? const [];
      final cs = (data['cities'] as List?) ?? const [];
      _provinces = ps.map((e) => Province(id: e['_id'] as int, name: e['name'] as String)).toList();
      _cities = cs.map((e) => City(id: e['_id'] as int, provinceId: e['province_id'] as int, name: e['name'] as String, cityNum: e['city_num'] as String)).toList();
    } catch (_) {
      _provinces = const [];
      _cities = const [];
    }
  }

  Future<List<Province>> getAllProvinces() async {
    await _ensureLoaded();
    return _provinces ?? const [];
  }

  Future<Province?> getProvinceByName(String provinceName) async {
    await _ensureLoaded();
    for (final p in _provinces ?? const []) {
      if (p.name == provinceName) return p;
    }
    return null;
  }

  Future<List<City>> getCitiesByProvinceId(int provinceId) async {
    await _ensureLoaded();
    return (_cities ?? const []).where((c) => c.provinceId == provinceId).toList();
  }

  Future<List<City>> getAllCities() async {
    await _ensureLoaded();
    final list = [...?_cities];
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<City>> getPopularCities() async {
    await _ensureLoaded();
    return (_cities ?? const []).take(20).toList();
  }

  Future<List<City>> searchCitiesByName(String cityName) async {
    await _ensureLoaded();
    final q = cityName.trim();
    if (q.isEmpty) return await getPopularCities();
    final lower = q.toLowerCase();
    return (_cities ?? const []).where((c) => c.name.toLowerCase().contains(lower)).take(20).toList();
  }

  Future<City?> getCityById(String cityId) async {
    await _ensureLoaded();
    for (final c in _cities ?? const []) {
      if (c.cityNum == cityId) return c;
    }
    return null;
  }

  Future<void> close() async {}

  Future<Map<String, int>> getDatabaseStats() async {
    await _ensureLoaded();
    return { 'provinces': _provinces?.length ?? 0, 'cities': _cities?.length ?? 0 };
  }
}

class Province {
  final int id;
  final String name;
  Province({required this.id, required this.name});
}

class City {
  final int id;
  final int provinceId;
  final String name;
  final String cityNum;
  City({required this.id, required this.provinceId, required this.name, required this.cityNum});
}