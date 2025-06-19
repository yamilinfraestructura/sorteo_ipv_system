import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    String dbPath = await databaseFactoryFfi.getDatabasesPath();
    String path = join(dbPath, 'sorteo.db');

    _db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE participantes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              dni TEXT,
              nombre TEXT,
              barrio TEXT,
              grupo TEXT,
              numero_bolilla INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE ganadores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              participanteId INTEGER,
              fecha TEXT,
              barrio TEXT,
              grupo TEXT,
              numero_bolilla INTEGER
            )
          ''');
        },
      ),
    );

    return _db!;
  }

  static Future<void> insertarParticipante(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('participantes', data);
  }

  static Future<void> insertarParticipantesLote(List<Map<String, dynamic>> lista) async {
    final db = await database;
    final batch = db.batch();
    for (var item in lista) {
      batch.insert('participantes', item);
    }
    await batch.commit(noResult: true);
  }
}
