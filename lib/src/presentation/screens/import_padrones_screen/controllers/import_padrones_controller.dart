// Controlador para la pantalla de importación de padrones
import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/search_participante_screen/controllers/search_participante_controller.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/list_ganadores_screen/controllers/list_ganadores_controller.dart';

class ImportPadronesController extends GetxController {
  // Lista observable de padrones importados
  var padrones = <Map<String, dynamic>>[].obs;
  // Lista de barrios disponibles
  var barrios = <String>['Seleccionar'].obs;
  // Lista de grupos disponibles
  var grupos = <String>['Seleccionar'].obs;
  // Barrio seleccionado
  var barrioSeleccionado = 'Seleccionar'.obs;
  // Grupo seleccionado
  var grupoSeleccionado = 'Seleccionar'.obs;
  // Participantes filtrados por barrio y grupo
  var participantesFiltrados = <Map<String, dynamic>>[].obs;
  // Mensaje de estado para la UI
  var mensaje = 'Ningún archivo importado aún.'.obs;

  @override
  void onInit() {
    super.onInit();
    verificarYCargar(); // Verifica la estructura de la BD y carga barrios
  }

  /// Verifica la estructura de la base de datos y carga los barrios disponibles.
  Future<void> verificarYCargar() async {
    await DatabaseHelper.verificarEstructura();
    await cargarBarrios();
  }

  /// Carga los barrios disponibles desde la base de datos.
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

  /// Carga los grupos disponibles para un barrio específico.
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
      await cargarParticipantesBarrioGrupo(
        barrioSeleccionado.value,
        grupoSeleccionado.value,
      );
    } else {
      participantesFiltrados.value = <Map<String, dynamic>>[];
    }
  }

  /// Carga los participantes filtrados por barrio y grupo.
  Future<void> cargarParticipantesBarrioGrupo(
    String barrio,
    String grupo,
  ) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'participantes',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrio, grupo],
    );
    participantesFiltrados.value = result;
  }

  /// Maneja el cambio de barrio en el filtro y actualiza los grupos y participantes.
  void onBarrioChanged(String? val, [BuildContext? context]) async {
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

  /// Maneja el cambio de grupo en el filtro y actualiza los participantes.
  void onGrupoChanged(String? val, [BuildContext? context]) async {
    if (val == 'Seleccionar') {
      grupoSeleccionado.value = 'Seleccionar';
      participantesFiltrados.value = <Map<String, dynamic>>[];
      return;
    }
    grupoSeleccionado.value = val ?? 'Seleccionar';
    if (val != null &&
        val != 'Seleccionar' &&
        barrioSeleccionado.value != 'Seleccionar') {
      await cargarParticipantesBarrioGrupo(barrioSeleccionado.value, val);
    } else {
      participantesFiltrados.value = <Map<String, dynamic>>[];
    }
  }

  /// Importa un archivo Excel, procesa los datos y los guarda en la base de datos.
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
        final regex = RegExp(
          r'(\d+)\s*Viviendas?,\s*(\d+)\s*Familias?',
          caseSensitive: false,
        );
        final match = regex.firstMatch(viviendasFamilias);
        if (match != null) {
          viviendas = int.tryParse(match.group(1) ?? '') ?? 0;
          familias = int.tryParse(match.group(2) ?? '') ?? 0;
        }
        if (grupo.isEmpty || barrio.isEmpty) {
          mensaje.value =
              'Error: No se encontró el grupo o barrio en el archivo.';
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
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) {
              final focusNode = FocusNode();
              return StatefulBuilder(
                builder: (context, setState) {
                  return RawKeyboardListener(
                    focusNode: focusNode,
                    autofocus: true,
                    onKey: (RawKeyEvent event) {
                      if (event is RawKeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.numpadEnter)) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: AlertDialog(
                      title: const Text('Padrón ya importado'),
                      content: Text(
                        'Ya existe un padrón para el barrio "$barrio" y grupo "$grupo". ¿Deseas actualizar los datos con el nuevo archivo?',
                      ),
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
                },
              );
            },
          );
          if (actualizar != true) {
            final focusNode = FocusNode();
            await showDialog(
              // ignore: use_build_context_synchronously
              context: context,
              builder:
                  (context) => StatefulBuilder(
                    builder: (context, setState) {
                      return RawKeyboardListener(
                        focusNode: focusNode,
                        autofocus: true,
                        onKey: (RawKeyEvent event) {
                          if (event is RawKeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.numpadEnter)) {
                            Navigator.pop(context);
                          }
                        },
                        child: AlertDialog(
                          title: const Text('Importación cancelada'),
                          content: const Text('El padrón no fue actualizado.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Aceptar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            );
            mensaje.value =
                'Importación cancelada. El padrón no fue actualizado.';
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
          // Validar que la fila tenga al menos los campos requeridos
          if (row.length < 5) continue;
          // Extraer y limpiar los campos
          int position =
              int.tryParse(row[1]?.value?.toString().trim() ?? '') ?? 0;
          int order = int.tryParse(row[2]?.value?.toString().trim() ?? '') ?? 0;
          String? documento = row[3]?.value?.toString().trim();
          String? nombre = row[4]?.value?.toString().trim();
          // Si documento o nombre son nulos o solo espacios, ignorar la fila
          if (documento == null ||
              nombre == null ||
              documento.isEmpty ||
              nombre.isEmpty)
            continue;
          // Si todos los campos relevantes están vacíos, ignorar la fila
          bool todosVacios =
              ((row[1]?.value == null) ||
                  (row[1]?.value != null &&
                      row[1]!.value.toString().trim().isEmpty)) &&
              ((row[2]?.value == null) ||
                  (row[2]?.value != null &&
                      row[2]!.value.toString().trim().isEmpty)) &&
              ((row[3]?.value == null) ||
                  (row[3]?.value != null &&
                      row[3]!.value.toString().trim().isEmpty)) &&
              ((row[4]?.value == null) ||
                  (row[4]?.value != null &&
                      row[4]!.value.toString().trim().isEmpty));
          if (todosVacios) continue;
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
          // Notificar al controlador de búsqueda para que recargue barrios y grupos
          final searchController =
              Get.isRegistered<SearchParticipanteController>()
                  ? Get.find<SearchParticipanteController>()
                  : null;
          if (searchController != null) {
            await searchController.cargarBarrios();
            await searchController.cargarGrupos();
          }
          // Notificar al controlador de ganadores para que recargue barrios y grupos
          final ganadoresController =
              Get.isRegistered<ListGanadoresController>()
                  ? Get.find<ListGanadoresController>()
                  : null;
          if (ganadoresController != null) {
            await ganadoresController.cargarFiltros();
          }
          // ignore: unnecessary_null_comparison
          if (barrioSeleccionado.value != null) {
            await cargarGrupos(barrioSeleccionado.value);
          }
          mensaje.value = 'Participantes importados correctamente.';
        } else {
          mensaje.value =
              'Error: No se encontraron participantes válidos en el archivo.';
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
