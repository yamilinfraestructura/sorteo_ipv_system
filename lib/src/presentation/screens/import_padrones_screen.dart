import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

//Importacion de archivos
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';


class ImportPadronesScreen extends StatefulWidget {
  const ImportPadronesScreen({super.key});

  @override
  State<ImportPadronesScreen> createState() => _ImportPadronesScreenState();
}

class _ImportPadronesScreenState extends State<ImportPadronesScreen> {
  String mensaje = 'Ningún archivo importado aún.';

  Future<void> importarExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      List<Map<String, dynamic>> listaParticipantes = [];

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows.skip(1)) {
          if (row.length >= 5) {
            listaParticipantes.add({
              'dni': row[0]?.value.toString(),
              'nombre': row[1]?.value.toString(),
              'barrio': row[2]?.value.toString(),
              'grupo': row[3]?.value.toString(),
              'numero_bolilla': int.tryParse(row[4]?.value.toString() ?? '0'),
            });
          }
        }
      }

      await DatabaseHelper.insertarParticipantesLote(listaParticipantes);

      setState(() {
        mensaje = 'Importados ${listaParticipantes.length} participantes correctamente.';
      });
    } else {
      setState(() {
        mensaje = 'Importación cancelada.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Importar archivo Excel"),
              onPressed: importarExcel,
            ),
            const SizedBox(height: 20),
            Text(
              mensaje,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
