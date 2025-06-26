import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:excel/excel.dart';

class ImportPadronesController extends GetxController {
  var padrones = <Map<String, dynamic>>[].obs;
  var barrios = <String>['Seleccionar'].obs;
  var grupos = <String>['Seleccionar'].obs;
  var barrioSeleccionado = 'Seleccionar'.obs;
  var grupoSeleccionado = 'Seleccionar'.obs;
  var participantesFiltrados = <Map<String, dynamic>>[].obs;
  var mensaje = 'Ningún archivo importado aún.'.obs;

  @override
  void onInit() {
    super.onInit();
    verificarYCargar();
  }

  Future<void> verificarYCargar() async {
    await DatabaseHelper.verificarEstructura();
    await cargarBarrios();
  }

  Future<void> cargarBarrios() async {
    final barriosDb = await DatabaseHelper.obtenerBarrios();
    barrios.value = ['Seleccionar', ...barriosDb];
    if (!barrios.contains(barrioSeleccionado.value)) {
      barrioSeleccionado.value = 'Seleccionar';
    }
    if (barrioSeleccionado.value != 'Seleccionar') {
      await cargarGrupos(barrioSeleccionado.value);
    } else {
      grupos.value = ['Seleccionar'];
      grupoSeleccionado.value = 'Seleccionar';
      participantesFiltrados.clear();
    }
  }

  Future<void> cargarGrupos(String barrio) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT "group" FROM participantes WHERE neighborhood = ?',
      [barrio],
    );
    final gruposDb = result.map((e) => e['group'] as String).toList();
    grupos.value = ['Seleccionar', ...gruposDb];
    if (!grupos.contains(grupoSeleccionado.value)) {
      grupoSeleccionado.value = 'Seleccionar';
    }
    if (grupoSeleccionado.value != 'Seleccionar') {
      await cargarParticipantesBarrioGrupo(barrioSeleccionado.value, grupoSeleccionado.value);
    } else {
      participantesFiltrados.clear();
    }
  }

  Future<void> cargarParticipantesBarrioGrupo(String barrio, String grupo) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'participantes',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrio, grupo],
    );
    participantesFiltrados.value = result;
  }

  void onBarrioChanged(String? val, [BuildContext? context]) async {
    if (val == 'Seleccionar') {
      if (grupoSeleccionado.value != 'Seleccionar') {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Primero deselecciona el grupo antes de cambiar el barrio.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      barrioSeleccionado.value = 'Seleccionar';
      grupos.value = ['Seleccionar'];
      grupoSeleccionado.value = 'Seleccionar';
      participantesFiltrados.value = <Map<String, dynamic>>[];
      return;
    }
    barrioSeleccionado.value = val ?? 'Seleccionar';
    grupoSeleccionado.value = 'Seleccionar';
    if (val != null && val != 'Seleccionar') {
      await cargarGrupos(val);
    } else {
      grupos.value = ['Seleccionar'];
      grupoSeleccionado.value = 'Seleccionar';
      participantesFiltrados.value = <Map<String, dynamic>>[];
    }
  }

  void onGrupoChanged(String? val, [BuildContext? context]) async {
    if (val == 'Seleccionar') {
      grupoSeleccionado.value = 'Seleccionar';
      participantesFiltrados.value = <Map<String, dynamic>>[];
      return;
    }
    grupoSeleccionado.value = val ?? 'Seleccionar';
    if (val != null && val != 'Seleccionar' && barrioSeleccionado.value != 'Seleccionar') {
      await cargarParticipantesBarrioGrupo(barrioSeleccionado.value, val);
    } else {
      participantesFiltrados.value = <Map<String, dynamic>>[];
    }
  }

  Future<void> importarExcel(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        mensaje.value = 'Procesando archivo...';
        File file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final table = excel.tables.values.first;
        final rows = table.rows;
        String grupo = rows[3][1]?.value.toString().trim() ?? '';
        String barrio = rows[5][1]?.value.toString().trim() ?? '';
        String viviendasFamilias = rows[4][1]?.value.toString().trim() ?? '';
        int viviendas = 0;
        int familias = 0;
        final regex = RegExp(r'(\d+)\s*Viviendas?,\s*(\d+)\s*Familias?', caseSensitive: false);
        final match = regex.firstMatch(viviendasFamilias);
        if (match != null) {
          viviendas = int.tryParse(match.group(1) ?? '') ?? 0;
          familias = int.tryParse(match.group(2) ?? '') ?? 0;
        }
        if (grupo.isEmpty || barrio.isEmpty) {
          mensaje.value = 'Error: No se encontró el grupo o barrio en el archivo.';
          return;
        }
        final db = await DatabaseHelper.database;
        final existePadron = await db.query(
          'participantes',
          where: 'neighborhood = ? AND "group" = ?',
          whereArgs: [barrio, grupo],
          limit: 1,
        );
        if (existePadron.isNotEmpty) {
          final actualizar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Padrón ya importado'),
              content: Text('Ya existe un padrón para el barrio "$barrio" y grupo "$grupo". ¿Deseas actualizar los datos con el nuevo archivo?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          );
          if (actualizar != true) {
            mensaje.value = 'Importación cancelada. El padrón no fue actualizado.';
            return;
          }
          await db.delete(
            'participantes',
            where: 'neighborhood = ? AND "group" = ?',
            whereArgs: [barrio, grupo],
          );
        }
        List<Map<String, dynamic>> participantes = [];
        for (int i = 8; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 5 || row[1] == null) continue;
          int position = int.tryParse(row[1]?.value.toString() ?? '') ?? 0;
          int order = int.tryParse(row[2]?.value.toString() ?? '') ?? 0;
          String documento = row[3]?.value.toString().trim() ?? '';
          String nombre = row[4]?.value.toString().trim() ?? '';
          if (documento.isEmpty || nombre.isEmpty) continue;
          participantes.add({
            'position': position,
            'order_number': order,
            'document': documento,
            'full_name': nombre,
            'group': grupo,
            'neighborhood': barrio,
            'viviendas': viviendas,
            'familias': familias,
          });
        }
        if (participantes.isNotEmpty) {
          mensaje.value = 'Guardando participantes en la base de datos...';
          await DatabaseHelper.insertarParticipantesLote(participantes);
          await cargarBarrios();
          if (barrioSeleccionado.value != null) {
            await cargarGrupos(barrioSeleccionado.value);
          }
          mensaje.value = 'Importación exitosa: \\${participantes.length} participantes agregados para "$barrio" - "$grupo".';
        } else {
          mensaje.value = 'Error: No se encontraron participantes válidos en el archivo.';
        }
      } else {
        mensaje.value = 'Importación cancelada por el usuario.';
      }
    } catch (e) {
      mensaje.value = 'Error durante la importación: \\${e.toString()}';
      print('Error en importarExcel: $e');
    }
  }
}
