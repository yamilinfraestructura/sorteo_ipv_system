import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

//Archivos importados
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';


class ExportGanadoresScreen extends StatelessWidget {
  const ExportGanadoresScreen({super.key});

  Future<void> exportarExcel(BuildContext context) async {
    final db = await DatabaseHelper.database;
    final ganadores = await db.query('ganadores', orderBy: 'fecha ASC');
    if (ganadores.isEmpty) {
      _mostrarMensaje(context, 'No hay ganadores registrados.');
      return;
    }

    // Obtener datos generales del primer ganador (asumiendo que todos son del mismo grupo/barrio)
    final participante = await db.query(
      'participantes',
      where: 'id = ?',
      whereArgs: [ganadores.first['participanteId']],
    );
    final p = participante.isNotEmpty ? participante.first : {};
    final grupo = p['group']?.toString() ?? '';
    final barrio = p['neighborhood']?.toString() ?? '';
    // Aquí podrías obtener el número de viviendas/familias si lo guardás en la base
    final numViviendasFamilias = '';

    final excel = Excel.createExcel();
    final sheet = excel['Ganadores'];

    // Fila 2: Título (B-F combinadas)
    sheet.appendRow([null, TextCellValue('Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025')]);
    sheet.merge(CellIndex.indexByString("B2"), CellIndex.indexByString("F2"));

    // Fila 3: vacía
    sheet.appendRow([]);

    // Fila 4: Grupo (B-F combinadas)
    sheet.appendRow([null, TextCellValue('Grupo: $grupo')]);
    sheet.merge(CellIndex.indexByString("B4"), CellIndex.indexByString("F4"));

    // Fila 5: Número de viviendas y familias (B-F combinadas)
    sheet.appendRow([null, TextCellValue('3 Viviendas, 40 Familias')]); // Modificar si tenés el dato real
    sheet.merge(CellIndex.indexByString("B5"), CellIndex.indexByString("F5"));

    // Fila 6: Barrio (B-F combinadas)
    sheet.appendRow([null, TextCellValue('Barrio: $barrio')]);
    sheet.merge(CellIndex.indexByString("B6"), CellIndex.indexByString("F6"));

    // Fila 7 y 8: vacías
    sheet.appendRow([]);
    sheet.appendRow([]);

    // Fila 9: Encabezados (B-E)
    sheet.appendRow([
      null,
      TextCellValue('Posición'),
      TextCellValue('Nro Orden'),
      TextCellValue('Documento'),
      TextCellValue('Apellido Nombre'),
    ]);

    // Estilos de encabezado
    for (var col = 1; col <= 4; col++) {
      final headerCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 8));
      headerCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Fila 10 en adelante: datos (B-E)
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
          IntCellValue(p['position'] as int),
          IntCellValue(p['order_number'] as int),
          DoubleCellValue(double.tryParse(p['document'].toString().replaceAll('.', '')) ?? 0),
          TextCellValue(p['full_name'].toString()),
        ]);
        rowIndex++;
      }
    }

    // Ajustar el ancho de las columnas B-E
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo Excel',
      fileName: 'listado_ganadores.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (savePath == null) return;
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      _mostrarMensaje(context, 'Error al generar archivo Excel.');
      return;
    }
    final file = File(savePath);
    await file.writeAsBytes(fileBytes);
    _mostrarMensaje(context, 'Archivo exportado correctamente.');
  }

  void _mostrarMensaje(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text("Exportar ganadores a Excel"),
        onPressed: () => exportarExcel(context),
      ),
    );
  }
}
