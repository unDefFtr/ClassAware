import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart' as s3;

void main(List<String> args) {
  final dbPath = args.isNotEmpty ? args.first : 'assets/xiaomi_weather.db';
  final outPath = args.length > 1 ? args[1] : 'assets/xiaomi_weather.json';
  final db = s3.sqlite3.open(dbPath, mode: s3.OpenMode.readOnly);
  final provinces = db.select('SELECT _id, name FROM provinces ORDER BY _id ASC').map((r) => {'_id': r['_id'], 'name': r['name']}).toList();
  final cities = db.select('SELECT _id, province_id, name, city_num FROM citys ORDER BY _id ASC').map((r) => {'_id': r['_id'], 'province_id': r['province_id'], 'name': r['name'], 'city_num': r['city_num']}).toList();
  final data = {'provinces': provinces, 'cities': cities};
  final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
  File(outPath).writeAsStringSync(jsonStr);
  db.dispose();
}