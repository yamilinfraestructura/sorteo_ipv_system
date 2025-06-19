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

    final excel = Excel.createExcel();
    final sheet = excel['Ganadores'];

    // Encabezados
    sheet.appendRow([
      TextCellValue('Nombre'),
      TextCellValue('DNI'),
      TextCellValue('Barrio'),
      TextCellValue('Grupo'),
      TextCellValue('Número de bolilla'),
      TextCellValue('Fecha'),
    ]);


    for (var ganador in ganadores) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [ganador['participanteId']],
      );

      if (participante.isNotEmpty) {
        final p = participante.first;
        sheet.appendRow([
          TextCellValue(p['nombre'].toString()),
          TextCellValue(p['dni'].toString()),
          TextCellValue(ganador['barrio'].toString()),
          TextCellValue(ganador['grupo'].toString()),
          DoubleCellValue((ganador['numero_bolilla'] as int).toDouble()),
          TextCellValue(ganador['fecha'].toString()),
        ]);
      }
    }

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo Excel',
      fileName: 'ganadores.xlsx',
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
