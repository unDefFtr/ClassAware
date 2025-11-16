import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' as s3;

class CityDatabaseService {
  static CityDatabaseService? _instance;
  static s3.Database? _database;

  CityDatabaseService._internal();
  factory CityDatabaseService() { _instance ??= CityDatabaseService._internal(); return _instance!; }

  Future<s3.Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<s3.Database> _initDatabase() async {
    final tmp = File('${Directory.systemTemp.path}/xiaomi_weather.db');
    if (!tmp.existsSync()) {
      final data = await rootBundle.load('assets/xiaomi_weather.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await tmp.writeAsBytes(bytes, flush: true);
    }
    final db = s3.sqlite3.open(tmp.path, mode: s3.OpenMode.readOnly);
    return db;
  }

  Future<List<Province>> getAllProvinces() async {
    final db = await database;
    final result = db.select('SELECT _id, name FROM provinces ORDER BY _id ASC');
    return result.map((row) => Province(id: row['_id'] as int, name: row['name'] as String)).toList();
  }

  Future<List<City>> getCitiesByProvinceId(int provinceId) async {
    final db = await database;
    final stmt = db.prepare('SELECT _id, province_id, name, city_num FROM citys WHERE province_id = ? ORDER BY _id ASC');
    final result = stmt.select([provinceId]);
    stmt.dispose();
    return result.map((row) => City(id: row['_id'] as int, provinceId: row['province_id'] as int, name: row['name'] as String, cityNum: row['city_num'] as String)).toList();
  }

  Future<List<City>> searchCitiesByName(String cityName) async {
    final db = await database;
    final stmt = db.prepare('SELECT _id, province_id, name, city_num FROM citys WHERE name LIKE ? ORDER BY _id ASC LIMIT 20');
    final result = stmt.select(['%$cityName%']);
    stmt.dispose();
    return result.map((row) => City(id: row['_id'] as int, provinceId: row['province_id'] as int, name: row['name'] as String, cityNum: row['city_num'] as String)).toList();
  }

  Future<City?> getCityById(String cityId) async {
    final db = await database;
    final stmt = db.prepare('SELECT _id, province_id, name, city_num FROM citys WHERE city_num = ? LIMIT 1');
    final result = stmt.select([cityId]);
    stmt.dispose();
    if (result.isNotEmpty) {
      final row = result.first;
      return City(id: row['_id'] as int, provinceId: row['province_id'] as int, name: row['name'] as String, cityNum: row['city_num'] as String);
    }
    return null;
  }

  Future<List<City>> getPopularCities() async {
    final db = await database;
    final result = db.select('SELECT _id, province_id, name, city_num FROM citys ORDER BY _id ASC LIMIT 20');
    return result.map((row) => City(id: row['_id'] as int, provinceId: row['province_id'] as int, name: row['name'] as String, cityNum: row['city_num'] as String)).toList();
  }

  Future<Province?> getProvinceByName(String provinceName) async {
    final db = await database;
    final stmt = db.prepare('SELECT _id, name FROM provinces WHERE name = ? LIMIT 1');
    final result = stmt.select([provinceName]);
    stmt.dispose();
    if (result.isNotEmpty) {
      final row = result.first;
      return Province(id: row['_id'] as int, name: row['name'] as String);
    }
    return null;
  }

  Future<List<City>> getAllCities() async {
    final db = await database;
    final result = db.select('SELECT _id, province_id, name, city_num FROM citys ORDER BY name ASC');
    return result.map((row) => City(id: row['_id'] as int, provinceId: row['province_id'] as int, name: row['name'] as String, cityNum: row['city_num'] as String)).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      db.dispose();
      _database = null;
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final p = db.select('SELECT COUNT(*) AS c FROM provinces').first['c'] as int;
    final c = db.select('SELECT COUNT(*) AS c FROM citys').first['c'] as int;
    return { 'provinces': p, 'cities': c };
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