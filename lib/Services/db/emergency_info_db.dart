import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class EmergencyInfoDB {
  late Database database;

  load(String creationQuery) async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, 'emergency_info_db.db');

    try {
      await Directory(databasesPath).create(recursive: true);
    } catch (_) {}
    database = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE emergency_message (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
      await db.execute(
          'CREATE TABLE emergency_contacts (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
    });
  }

  Future<bool> get isConfigured async =>
      5 ==
      Sqflite.firstIntValue(await database.rawQuery('SEKECT count(*) FROM emergency_contacts'));

  Future<String> get getEmergencyMessage async =>
      (await database.rawQuery('SELECT message FROM emergency_info WHERE active=true'))
          .first['message']
          .toString();

  Future<List<Map<String, String>>> get getEmergencyContacts async =>
      await database.rawQuery('SELECT name,number FROM emergency_contacts')
          as List<Map<String, String>>;

  Future<void> updateEmergencyMessage(String message) async {
    await database.rawUpdate('UPDATE emergency_contacts $message WHERE active = true');
  }

  Future<void> updateEmergecyContacts(List<Map<String, String>> contacts) async {
    await database.rawUpdate('TRUNCATE emergency_contacts');
    for (var contact in contacts) {
      await database.rawUpdate(
          'INSERT INTO emergency_contacts values(${contact["name"]}, ${contact["number"]})');
    }
  }
}
