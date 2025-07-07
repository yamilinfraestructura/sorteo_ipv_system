import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
              familias INTEGER,
              id_user INTEGER
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
              full_name TEXT,
              id_user INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE usuarios (
              id_user INTEGER PRIMARY KEY AUTOINCREMENT,
              user_name TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL,
              perfil_user TEXT,
              email_user TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE eliminados (
              id_eliminado INTEGER PRIMARY KEY AUTOINCREMENT,
              ganador_id INTEGER,
              neighborhood TEXT,
              "group" TEXT,
              position INTEGER,
              order_number INTEGER,
              document TEXT,
              full_name TEXT,
              fecha_baja TEXT DEFAULT '1900-01-01 00:00:00',
              id_user INTEGER,
              FOREIGN KEY (id_user) REFERENCES usuarios(id_user)
            )
          ''');

          await db.execute('''
            CREATE TABLE setting (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clave TEXT NOT NULL UNIQUE,
              valor TEXT
            )
          ''');

          // Insertar usuario por defecto con password encriptado
          final password = '654321';
          final passwordHash = sha256.convert(utf8.encode(password)).toString();
          await db.insert('usuarios', {
            'user_name': 'Yamil Saad',
            'password': passwordHash,
            'perfil_user': 'Desarrollador',
            'email_user': 'yamilsaad00@gmail.com',
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Agregar columnas id_user si no existen
          final participantesCols = await db.rawQuery(
            'PRAGMA table_info(participantes)',
          );
          final ganadoresCols = await db.rawQuery(
            'PRAGMA table_info(ganadores)',
          );
          final participantesColNames =
              participantesCols.map((c) => c['name']).toSet();
          final ganadoresColNames = ganadoresCols.map((c) => c['name']).toSet();
          if (!participantesColNames.contains('viviendas')) {
            await db.execute(
              'ALTER TABLE participantes ADD COLUMN viviendas INTEGER;',
            );
          }
          if (!participantesColNames.contains('familias')) {
            await db.execute(
              'ALTER TABLE participantes ADD COLUMN familias INTEGER;',
            );
          }
          if (!participantesColNames.contains('id_user')) {
            await db.execute(
              'ALTER TABLE participantes ADD COLUMN id_user INTEGER;',
            );
          }
          if (!ganadoresColNames.contains('id_user')) {
            await db.execute(
              'ALTER TABLE ganadores ADD COLUMN id_user INTEGER;',
            );
          }

          // Crear tabla usuarios si no existe
          await db.execute('''
            CREATE TABLE IF NOT EXISTS usuarios (
              id_user INTEGER PRIMARY KEY AUTOINCREMENT,
              user_name TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL,
              perfil_user TEXT,
              email_user TEXT
            )
          ''');

          // Crear tabla eliminados si no existe
          await db.execute('''
            CREATE TABLE IF NOT EXISTS eliminados (
              id_eliminado INTEGER PRIMARY KEY AUTOINCREMENT,
              ganador_id INTEGER,
              neighborhood TEXT,
              "group" TEXT,
              position INTEGER,
              order_number INTEGER,
              document TEXT,
              full_name TEXT,
              fecha_baja TEXT DEFAULT '1900-01-01 00:00:00',
              id_user INTEGER,
              FOREIGN KEY (id_user) REFERENCES usuarios(id_user)
            )
          ''');

          // Crear tabla setting si no existe
          await db.execute('''
            CREATE TABLE IF NOT EXISTS setting (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clave TEXT NOT NULL UNIQUE,
              valor TEXT
            )
          ''');

          // Insertar usuario por defecto si la tabla está vacía
          final usuarios = await db.query('usuarios');
          if (usuarios.isEmpty) {
            final password = '654321';
            final passwordHash =
                sha256.convert(utf8.encode(password)).toString();
            await db.insert('usuarios', {
              'user_name': 'Yamil Saad',
              'password': passwordHash,
              'perfil_user': 'Desarrollador',
              'email_user': 'yamilsaad00@gmail.com',
            });
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

  static Future<void> insertarParticipantesLote(
    List<Map<String, dynamic>> lista,
  ) async {
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
      final result = await db.rawQuery(
        'SELECT DISTINCT neighborhood FROM participantes',
      );
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

  static Future<void> eliminarGanadorPorId(int id, int idUser) async {
    final db = await database;
    // Obtener el registro del ganador
    final ganadores = await db.query(
      'ganadores',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (ganadores.isNotEmpty) {
      final g = ganadores.first;
      await db.insert('eliminados', {
        'ganador_id': g['id'],
        'neighborhood': g['neighborhood'],
        'group': g['group'],
        'position': g['position'],
        'order_number': g['order_number'],
        'document': g['document'],
        'full_name': g['full_name'],
        'fecha_baja': DateTime.now().toIso8601String(),
        'id_user': idUser,
      });
    }
    await db.delete('ganadores', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para la tabla setting
  static Future<void> upsertSetting(String clave, String valor) async {
    final db = await database;
    // Intenta actualizar, si no existe inserta
    int count = await db.update(
      'setting',
      {'valor': valor},
      where: 'clave = ?',
      whereArgs: [clave],
    );
    if (count == 0) {
      await db.insert('setting', {'clave': clave, 'valor': valor});
    }
  }

  static Future<String?> getSetting(String clave) async {
    final db = await database;
    final result = await db.query(
      'setting',
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['valor'] as String?;
    }
    return null;
  }

  static Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final result = await db.query('setting');
    return {
      for (var row in result)
        row['clave'] as String: row['valor'] as String? ?? '',
    };
  }

  static Future<void> limpiarDatosPrincipales() async {
    final db = await database;
    await db.delete('participantes');
    await db.delete('ganadores');
    await db.delete('eliminados');
  }

  // Métodos para gestión de usuarios
  static Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  static Future<bool> eliminarUsuarioPorId(int id) async {
    final db = await database;
    // No permitir eliminar el usuario por defecto
    final usuario = await db.query(
      'usuarios',
      where: 'id_user = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (usuario.isNotEmpty &&
        usuario.first['email_user'] == 'yamilsaad00@gmail.com') {
      return false;
    }
    final count = await db.delete(
      'usuarios',
      where: 'id_user = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  static Future<bool> actualizarPerfilUsuario(
    int id,
    String nuevoPerfil,
  ) async {
    final db = await database;
    final count = await db.update(
      'usuarios',
      {'perfil_user': nuevoPerfil},
      where: 'id_user = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
}
