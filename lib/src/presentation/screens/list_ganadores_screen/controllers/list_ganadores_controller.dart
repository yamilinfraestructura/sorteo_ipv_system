// Controlador para la pantalla de listado de ganadores
import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/db/database_helper.dart';

class ListGanadoresController extends GetxController {
  // Lista observable de ganadores para mostrar en la UI
  var ganadores = <Map<String, dynamic>>[].obs;
  // Lista de barrios disponibles para filtrar
  var barrios = <String>['Todos'].obs;
  // Lista de grupos disponibles para filtrar
  var grupos = <String>['Todos'].obs;
  // Barrio seleccionado en el filtro
  var barrioSeleccionado = 'Todos'.obs;
  // Grupo seleccionado en el filtro
  var grupoSeleccionado = 'Todos'.obs;
  // Estado de carga para mostrar spinners
  var isLoading = false.obs;
  // Estado de cierre del sorteo para el filtro actual
  var sorteoCerrado = false.obs;
  // Estado de cierre de cada grupo para el barrio seleccionado
  var gruposCerrados = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    cargarFiltros(); // Carga los filtros de barrios y grupos al iniciar
    cargarGanadores(); // Carga la lista de ganadores al iniciar
  }

  /// Carga los barrios y grupos disponibles desde la base de datos para los filtros.
  Future<void> cargarFiltros() async {
    final db = await DatabaseHelper.database;
    final barriosDb = await db.rawQuery(
      'SELECT DISTINCT neighborhood FROM ganadores',
    );
    final gruposDb = await db.rawQuery(
      'SELECT DISTINCT "group" FROM ganadores',
    );
    barrios.value = [
      'Todos',
      ...barriosDb.map((e) => e['neighborhood'] as String),
    ];
    grupos.value = ['Todos', ...gruposDb.map((e) => e['group'] as String)];
    if (!barrios.contains(barrioSeleccionado.value)) {
      barrioSeleccionado.value = 'Todos';
    }
    if (!grupos.contains(grupoSeleccionado.value)) {
      grupoSeleccionado.value = 'Todos';
    }
    // Calcular estado de cierre para cada grupo del barrio seleccionado
    await actualizarGruposCerrados();
  }

  Future<void> actualizarGruposCerrados() async {
    gruposCerrados.clear();
    final db = await DatabaseHelper.database;
    final barrio = barrioSeleccionado.value;
    if (barrio == null || barrio == 'Todos') return;
    final result = await db.rawQuery(
      'SELECT DISTINCT "group" FROM participantes WHERE neighborhood = ?',
      [barrio],
    );
    for (var row in result) {
      final grupo = row['group'] as String;
      // Contar ganadores
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
        [barrio, grupo],
      );
      final totalGanadores =
          countResult.first['count'] is int
              ? countResult.first['count'] as int
              : int.tryParse(countResult.first['count']?.toString() ?? '0') ??
                  0;
      // Obtener viviendas
      final infoResult = await db.query(
        'participantes',
        columns: ['viviendas'],
        where: 'neighborhood = ? AND "group" = ?',
        whereArgs: [barrio, grupo],
        limit: 1,
      );
      int viviendas = 0;
      if (infoResult.isNotEmpty) {
        final v = infoResult.first['viviendas'];
        viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      }
      gruposCerrados[grupo] = viviendas > 0 && totalGanadores == viviendas;
    }
    gruposCerrados.refresh();
  }

  /// Carga la lista de ganadores según los filtros seleccionados (barrio y grupo).
  Future<void> cargarGanadores() async {
    isLoading.value = true;
    final db = await DatabaseHelper.database;
    String where = '';
    List<dynamic> args = [];
    if (barrioSeleccionado.value != 'Todos') {
      where += 'neighborhood = ?';
      args.add(barrioSeleccionado.value);
    }
    if (grupoSeleccionado.value != 'Todos') {
      if (where.isNotEmpty) where += ' AND ';
      where += '"group" = ?';
      args.add(grupoSeleccionado.value);
    }
    final resultado = await db.query(
      'ganadores',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'fecha ASC',
    );
    final List<Map<String, dynamic>> lista = [];
    for (var item in resultado) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [item['participanteId']],
      );
      if (participante.isNotEmpty) {
        lista.add({
          ...item,
          'full_name': participante.first['full_name'],
          'document': participante.first['document'],
        });
      }
    }
    ganadores.value = lista;

    // Lógica para saber si el sorteo está cerrado
    if (barrioSeleccionado.value != 'Todos' &&
        grupoSeleccionado.value != 'Todos') {
      // Contar participantes para el barrio y grupo
      final participantes = await db.query(
        'participantes',
        where: 'neighborhood = ? AND "group" = ?',
        whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
      );
      final totalGanadores = lista.length;
      sorteoCerrado.value =
          participantes.isNotEmpty && totalGanadores == participantes.length;
    } else {
      sorteoCerrado.value = false;
    }
    isLoading.value = false;
  }

  /// Actualiza el filtro de barrio y recarga la lista de ganadores.
  void onBarrioChanged(String? val) async {
    barrioSeleccionado.value = val ?? 'Todos';
    await cargarFiltros();
    await cargarGanadores();
  }

  /// Actualiza el filtro de grupo y recarga la lista de ganadores.
  void onGrupoChanged(String? val) async {
    grupoSeleccionado.value = val ?? 'Todos';
    await cargarGanadores();
  }

  /// Refresca tanto los filtros como la lista de ganadores.
  void actualizarLista() async {
    await cargarFiltros();
    await cargarGanadores();
  }
}
