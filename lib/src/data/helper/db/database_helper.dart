import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart'; // Agregar path_provider

class DatabaseHelper {
  static Database? _db;

  // Obtiene una ruta segura para la base de datos en la carpeta de usuario
  static Future<String> getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'sorteo.db');
    print('Ruta de la base de datos SQLite: ' + path);
    return path;
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    String path = await getDatabasePath();

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

          // NUEVAS TABLAS PARA CREAR SORTEO
          await db.execute('''
            CREATE TABLE ganadores_por_sortear (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nro_para_sorteo TEXT,
              orden_sorteado TEXT,
              nro_inscripcion TEXT,
              dni TEXT,
              apellido TEXT,
              nombre TEXT,
              sexo TEXT,
              f_nac TEXT,
              ingreso_mensual TEXT,
              estudios TEXT,
              f_fall TEXT,
              f_baja TEXT,
              departamento TEXT,
              localidad TEXT,
              barrio TEXT,
              domicilio TEXT,
              tel TEXT,
              cant_ocupantes TEXT,
              descripcion1 TEXT,
              descripcion2 TEXT,
              grupreferencial TEXT,
              preferencial_ficha TEXT,
              ficha TEXT,
              f_alta TEXT,
              fmodif TEXT,
              f_baja2 TEXT,
              expediente TEXT,
              reemp TEXT,
              estado_txt TEXT,
              circuitoipv_txt TEXT,
              circuitoipv_nota TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE ganadores_posicionados (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nro_para_sorteo TEXT,
              orden_sorteado TEXT,
              nro_inscripcion TEXT,
              dni TEXT,
              apellido TEXT,
              nombre TEXT,
              sexo TEXT,
              f_nac TEXT,
              ingreso_mensual TEXT,
              estudios TEXT,
              f_fall TEXT,
              f_baja TEXT,
              departamento TEXT,
              localidad TEXT,
              barrio TEXT,
              domicilio TEXT,
              tel TEXT,
              cant_ocupantes TEXT,
              descripcion1 TEXT,
              descripcion2 TEXT,
              grupreferencial TEXT,
              preferencial_ficha TEXT,
              ficha TEXT,
              f_alta TEXT,
              fmodif TEXT,
              f_baja2 TEXT,
              expediente TEXT,
              reemp TEXT,
              estado_txt TEXT,
              circuitoipv_txt TEXT,
              circuitoipv_nota TEXT
            )
          ''');

          // NUEVA TABLA: sorteos_creados
          await db.execute('''
            CREATE TABLE sorteos_creados (
              id_sorteo INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre_sorteo TEXT NOT NULL,
              tipo_sorteo TEXT NOT NULL,
              cantidad_manzanas INTEGER,
              cantidad_viviendas_por_manzana INTEGER,
              tipo_manzana TEXT,
              tipo_identificador_casa TEXT,
              fecha_creacion TEXT,
              fecha_cierre TEXT,
              fecha_eliminacion TEXT,
              id_usuario INTEGER,
              FOREIGN KEY (id_usuario) REFERENCES usuarios(id_user)
            )
          ''');

          // Modificar ganadores_por_sortear para agregar id_sorteo
          await db.execute('''
            CREATE TABLE ganadores_por_sortear_tmp AS SELECT *, NULL as id_sorteo FROM ganadores_por_sortear;
          ''');
          await db.execute('DROP TABLE ganadores_por_sortear;');
          await db.execute(
            'ALTER TABLE ganadores_por_sortear_tmp RENAME TO ganadores_por_sortear;',
          );

          // Modificar ganadores_posicionados para agregar id_sorteo
          await db.execute('''
            CREATE TABLE ganadores_posicionados_tmp AS SELECT *, NULL as id_sorteo FROM ganadores_posicionados;
          ''');
          await db.execute('DROP TABLE ganadores_posicionados;');
          await db.execute(
            'ALTER TABLE ganadores_posicionados_tmp RENAME TO ganadores_posicionados;',
          );

          // Insertar usuario por defecto si no existe
          final usuarios = await db.query(
            'usuarios',
            where: 'email_user = ?',
            whereArgs: ['yamilsaad00@gmail.com'],
          );
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

  // Tabla para participantes importados para sorteo
  static Future<void> insertarGanadoresPorSortear(
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert('ganadores_por_sortear', data);
  }

  // Tabla para ganadores posicionados en el sorteo
  static Future<void> insertarGanadoresPosicionados(
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert('ganadores_posicionados', data);
  }

  // Métodos para sorteos_creados
  static Future<int> insertarSorteoCreado(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('sorteos_creados', data);
  }

  static Future<List<Map<String, dynamic>>> obtenerSorteosCreados() async {
    final db = await database;
    return await db.query('sorteos_creados');
  }

  // Validación de duplicados en ganadores_por_sortear
  static Future<bool> existeGanadorPorSortear({
    required String dni,
    required int idSorteo,
  }) async {
    final db = await database;
    final result = await db.query(
      'ganadores_por_sortear',
      where: 'dni = ? AND id_sorteo = ?',
      whereArgs: [dni, idSorteo],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Insertar ganador por sortear con id_sorteo
  static Future<void> insertarGanadorPorSortearConSorteo(
    Map<String, dynamic> data,
    int idSorteo,
  ) async {
    final db = await database;
    data['id_sorteo'] = idSorteo;
    await db.insert('ganadores_por_sortear', data);
  }

  // Insertar ganador posicionado con id_sorteo
  static Future<void> insertarGanadorPosicionadoConSorteo(
    Map<String, dynamic> data,
    int idSorteo,
  ) async {
    final db = await database;
    data['id_sorteo'] = idSorteo;
    await db.insert('ganadores_posicionados', data);
  }

  // Verifica si algún DNI ya fue importado en otro sorteo y devuelve el nombre del sorteo
  static Future<String?> existePadronEnOtroSorteo(
    List<String> dnis,
    int idSorteoActual,
  ) async {
    final db = await database;
    final placeholders = List.filled(dnis.length, '?').join(',');
    final result = await db.rawQuery(
      '''
      SELECT gps.dni, sc.nombre_sorteo
      FROM ganadores_por_sortear gps
      JOIN sorteos_creados sc ON gps.id_sorteo = sc.id_sorteo
      WHERE gps.dni IN ($placeholders) AND gps.id_sorteo != ?
      LIMIT 1
    ''',
      [...dnis, idSorteoActual],
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return 'El padrón con DNI ${row['dni']} ya fue importado en el sorteo "${row['nombre_sorteo']}"';
    }
    return null;
  }

  static Future<String?> getPinEscribano() async {
    return await getSetting('pin_escribano');
  }
}
