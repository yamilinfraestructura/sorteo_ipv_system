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
        version: 4, // Incrementamos la versión para forzar onUpgrade
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE participantes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              position INTEGER,
              order_number INTEGER,
              document TEXT,
              full_name TEXT,
              "group" TEXT,
              neighborhood TEXT,
              viviendas INTEGER,
              familias INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE ganadores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              participanteId INTEGER,
              fecha TEXT,
              neighborhood TEXT,
              "group" TEXT,
              position INTEGER,
              order_number INTEGER,
              document TEXT,
              full_name TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Si la tabla participantes no tiene viviendas/familias, las agregamos
          final columns = await db.rawQuery('PRAGMA table_info(participantes)');
          final colNames = columns.map((c) => c['name']).toSet();
          if (!colNames.contains('viviendas')) {
            await db.execute('ALTER TABLE participantes ADD COLUMN viviendas INTEGER;');
          }
          if (!colNames.contains('familias')) {
            await db.execute('ALTER TABLE participantes ADD COLUMN familias INTEGER;');
          }
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

  static Future<List<String>> obtenerBarrios() async {
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT DISTINCT neighborhood FROM participantes');
      return result.map((e) => e['neighborhood'] as String).toList();
    } catch (e) {
      print('Error al obtener barrios: $e');
      return [];
    }
  }

  static Future<void> limpiarParticipantes() async {
    final db = await database;
    await db.delete('participantes');
  }

  // Método para verificar la estructura de la tabla
  static Future<void> verificarEstructura() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA table_info(participantes)');
    print('Estructura de la tabla participantes:');
    for (var column in result) {
      print('Columna: ${column['name']}, Tipo: ${column['type']}');
    }
  }

  static Future<void> eliminarGanadorPorId(int id) async {
    final db = await database;
    await db.delete('ganadores', where: 'id = ?', whereArgs: [id]);
  }
}
