import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/weather_models.dart';

class CityDatabaseService {
  static CityDatabaseService? _instance;
  static Database? _database;

  CityDatabaseService._internal();

  factory CityDatabaseService() {
    _instance ??= CityDatabaseService._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 获取数据库路径
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'xiaomi_weather.db');

    // 检查数据库是否存在
    final exists = await databaseExists(path);

    if (!exists) {
      // 如果数据库不存在，从assets复制
      print('正在复制数据库到 $path');

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // 从assets复制数据库文件
      final data = await rootBundle.load('xiaomi_weather(1).db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    // 打开数据库
    return await openDatabase(
      path,
      version: 1,
      readOnly: true, // 只读模式
    );
  }

  // 获取所有省份
  Future<List<Province>> getAllProvinces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'provinces',
      orderBy: '_id ASC',
    );

    return List.generate(maps.length, (i) {
      return Province.fromMap(maps[i]);
    });
  }

  // 根据省份ID获取城市列表
  Future<List<City>> getCitiesByProvinceId(int provinceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'citys',
      where: 'province_id = ?',
      whereArgs: [provinceId],
      orderBy: '_id ASC',
    );

    return List.generate(maps.length, (i) {
      return City.fromMap(maps[i]);
    });
  }

  // 根据城市名称搜索城市
  Future<List<City>> searchCitiesByName(String cityName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'citys',
      where: 'name LIKE ?',
      whereArgs: ['%$cityName%'],
      orderBy: '_id ASC',
      limit: 20, // 限制结果数量
    );

    return List.generate(maps.length, (i) {
      return City.fromMap(maps[i]);
    });
  }

  // 根据城市ID获取城市信息
  Future<City?> getCityById(String cityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'citys',
      where: 'city_num = ?',
      whereArgs: [cityId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return City.fromMap(maps.first);
    }
    return null;
  }

  // 获取热门城市（前20个城市）
  Future<List<City>> getPopularCities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'citys',
      orderBy: '_id ASC',
      limit: 20,
    );

    return List.generate(maps.length, (i) {
      return City.fromMap(maps[i]);
    });
  }

  // 根据省份名称获取省份信息
  Future<Province?> getProvinceByName(String provinceName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'provinces',
      where: 'name = ?',
      whereArgs: [provinceName],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Province.fromMap(maps.first);
    }
    return null;
  }

  // 获取所有城市（用于全局搜索）
  Future<List<City>> getAllCities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'citys',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return City.fromMap(maps[i]);
    });
  }

  // 关闭数据库连接
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // 获取数据库统计信息
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final provinceCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM provinces')
    ) ?? 0;
    
    final cityCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM citys')
    ) ?? 0;

    return {
      'provinces': provinceCount,
      'cities': cityCount,
    };
  }
}