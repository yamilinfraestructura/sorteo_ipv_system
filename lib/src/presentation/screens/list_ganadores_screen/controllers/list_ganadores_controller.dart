import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';

class ListGanadoresController extends GetxController {
  var ganadores = <Map<String, dynamic>>[].obs;
  var barrios = <String>['Todos'].obs;
  var grupos = <String>['Todos'].obs;
  var barrioSeleccionado = 'Todos'.obs;
  var grupoSeleccionado = 'Todos'.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    cargarFiltros();
    cargarGanadores();
  }

  Future<void> cargarFiltros() async {
    final db = await DatabaseHelper.database;
    final barriosDb = await db.rawQuery('SELECT DISTINCT neighborhood FROM ganadores');
    final gruposDb = await db.rawQuery('SELECT DISTINCT "group" FROM ganadores');
    barrios.value = ['Todos', ...barriosDb.map((e) => e['neighborhood'] as String)];
    grupos.value = ['Todos', ...gruposDb.map((e) => e['group'] as String)];
    if (!barrios.contains(barrioSeleccionado.value)) {
      barrioSeleccionado.value = 'Todos';
    }
    if (!grupos.contains(grupoSeleccionado.value)) {
      grupoSeleccionado.value = 'Todos';
    }
  }

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
    isLoading.value = false;
  }

  void onBarrioChanged(String? val) async {
    barrioSeleccionado.value = val ?? 'Todos';
    await cargarGanadores();
  }

  void onGrupoChanged(String? val) async {
    grupoSeleccionado.value = val ?? 'Todos';
    await cargarGanadores();
  }

  void actualizarLista() async {
    await cargarFiltros();
    await cargarGanadores();
  }
}
