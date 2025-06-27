import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:flutter/services.dart';

// Controlador para la pantalla de exportación de ganadores
class ExportGanadoresController extends GetxController {
  // Lista de barrios disponibles
  var barrios = <String>[].obs;
  // Lista de grupos disponibles
  var grupos = <String>[].obs;
  // Barrio seleccionado
  var barrioSeleccionado = ''.obs;
  // Grupo seleccionado
  var grupoSeleccionado = ''.obs;
  // Mensaje de estado para la UI
  var mensaje = ''.obs;
  // Estado de carga para mostrar spinners
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    cargarBarrios(); // Carga los barrios disponibles al iniciar
  }

  /// Carga los barrios disponibles desde la base de datos.
  Future<void> cargarBarrios() async {
    final barriosDb = await DatabaseHelper.obtenerBarrios();
    barrios.value = barriosDb;
    if (barrios.isNotEmpty && !barrios.contains(barrioSeleccionado.value)) {
      barrioSeleccionado.value = barrios.first;
    }
    if (barrioSeleccionado.value.isNotEmpty) {
      await cargarGrupos(barrioSeleccionado.value);
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
    grupos.value = gruposDb;
    if (grupos.isNotEmpty && !grupos.contains(grupoSeleccionado.value)) {
      grupoSeleccionado.value = grupos.first;
    }
  }

  /// Maneja el cambio de barrio en el filtro y actualiza los grupos.
  void onBarrioChanged(String? val) async {
    barrioSeleccionado.value = val ?? '';
    grupoSeleccionado.value = '';
    if (val != null && val.isNotEmpty) {
      await cargarGrupos(val);
    } else {
      grupos.value = [];
      grupoSeleccionado.value = '';
    }
  }

  /// Maneja el cambio de grupo en el filtro.
  void onGrupoChanged(String? val) {
    grupoSeleccionado.value = val ?? '';
  }

  /// Exporta los ganadores filtrados a un archivo Excel con el formato requerido.
  Future<void> exportarExcel(BuildContext context) async {
    if (barrioSeleccionado.value.isEmpty || grupoSeleccionado.value.isEmpty) {
      mensaje.value = 'Seleccioná un barrio y grupo para exportar.';
      mostrarMensaje(context, mensaje.value);
      return;
    }
    final db = await DatabaseHelper.database;
    final ganadores = await db.query(
      'ganadores',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
      orderBy: 'position ASC',
    );
    if (ganadores.isEmpty) {
      // ignore: use_build_context_synchronously
      mostrarMensaje(context, 'No hay ganadores registrados para este barrio y grupo.');
      return;
    }
    final participante = await db.query(
      'participantes',
      where: 'id = ?',
      whereArgs: [ganadores.first['participanteId']],
    );
    final p = participante.isNotEmpty ? participante.first : {};
    final grupo = p['group']?.toString() ?? '';
    final barrio = p['neighborhood']?.toString() ?? '';
    final viviendas = p['viviendas'] is int ? p['viviendas'] : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
    final familias = p['familias'] is int ? p['familias'] : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;

    final excel = Excel.createExcel();
    final sheet = excel['Ganadores'];
    sheet.appendRow([null, TextCellValue('Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B2"), CellIndex.indexByString("F2"));
    sheet.appendRow([]);
    sheet.appendRow([null, TextCellValue('Grupo: $grupo'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B4"), CellIndex.indexByString("F4"));
    sheet.appendRow([null, TextCellValue('$viviendas Viviendas, $familias Familias'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B5"), CellIndex.indexByString("F5"));
    sheet.appendRow([null, TextCellValue('Barrio: $barrio'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B6"), CellIndex.indexByString("F6"));
    sheet.appendRow([]);
    sheet.appendRow([]);
    sheet.appendRow([
      null,
      TextCellValue('Posición'),
      TextCellValue('Nro Orden'),
      TextCellValue('Documento'),
      TextCellValue('Apellido Nombre'),
    ]);
    for (var col = 1; col <= 4; col++) {
      final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 8));
      headerCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }
    // ignore: unused_local_variable
    int rowIndex = 9;
    for (var ganador in ganadores) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [ganador['participanteId']],
      );
      if (participante.isNotEmpty) {
        final p = participante.first;
        sheet.appendRow([
          null,
          IntCellValue(ganador['position'] as int),
          IntCellValue(p['order_number'] as int),
          TextCellValue(p['document'].toString()),
          TextCellValue(p['full_name'].toString()),
        ]);
        rowIndex++;
      }
    }
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }
    String cleanFileName(String input) {
      return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    }
    final safeBarrio = cleanFileName(barrio);
    final safeGrupo = cleanFileName(grupo);
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo Excel',
      fileName: 'Barrio $safeBarrio - Grupo $safeGrupo - Definitivo para importar Ganadores.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (savePath == null) return;
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      // ignore: use_build_context_synchronously
      mostrarMensaje(context, 'Error al generar archivo Excel.');
      return;
    }
    final file = File(savePath);
    await file.writeAsBytes(fileBytes);
    // ignore: use_build_context_synchronously
    mostrarMensaje(context, 'Archivo exportado correctamente.');
  }

  /// Muestra un mensaje emergente (diálogo) en la pantalla.
  void mostrarMensaje(BuildContext context, String msg) {
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return RawKeyboardListener(
            focusNode: focusNode,
            autofocus: true,
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                Navigator.pop(context);
              }
            },
            child: AlertDialog(
              title: const Text("Exportación"),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
