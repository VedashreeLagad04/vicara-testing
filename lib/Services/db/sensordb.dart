import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SensorDb {
  Database? database;
  load(String creationQuery) async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'sensor_db.db');

    try {
      await Directory(databasesPath).create(recursive: true);
    } catch (_) {}
    database = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      // TODO:edit query
      await db.execute(
          'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
    });
  }

  Future<int> insertSensorData() async {
    // TODO:edit query
    return await database!.rawInsert('INSERT INTO table VALUES()');
  }

  Future<List<Map<String, dynamic>>> extractSensorData() async {
    // TODO:edit query
    List<Map<String, dynamic>> tableData =
        await database?.rawQuery('SELECT * FROM table') as List<Map<String, dynamic>>;
    await database?.rawQuery('TRUNCATE table');
    return tableData;
  }
}
