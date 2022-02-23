import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  Database? db;
  String? databasesPath;
  Future<void> _loadDB() async {
    databasesPath ??= await getDatabasesPath();
    String path = join(databasesPath!, 'demo.db');
    db ??= await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE sensor_data (id INTEGER PRIMARY KEY autoincrement, data TEXT,ts INTEGER)');
    });
  }

  Future<bool> insertIntoDatabase(String data, int ts) async {
    await _loadDB();
    int res = await db!.insert('sensor_data', {'data': data, 'ts': ts});
    print('~~~~~~~~~~~~~~~~~~~~~~~~~~SENSOR DATA INSESRTED~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    print(res);
    print('~~~~~~~~~~~~~~~~~~~~~~~~~~SENSOR DATA INSESRTED~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

    return res != 0;
  }

  Future<List<Map>> getAllEntries(String query) async {
    await _loadDB();
    return await db!.rawQuery('SELECT * FROM sensor_data $query');
  }

  Future<int> deleteEntries(String query) async {
    await _loadDB();
    return await db!.rawDelete("DELETE FROM sensor_data $query");
  }
}
