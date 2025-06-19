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

  List<String> _barrios = [];
  String? _barrioSeleccionado;
  List<Map<String, dynamic>> _participantesBarrio = [];

  @override
  void initState() {
    super.initState();
    _cargarBarrios();
  }

  Future<void> _cargarBarrios() async {
    final barrios = await DatabaseHelper.obtenerBarrios();
    setState(() {
      _barrios = barrios;
      if (_barrios.isNotEmpty && _barrioSeleccionado == null) {
        _barrioSeleccionado = _barrios.first;
        _cargarParticipantesBarrio(_barrioSeleccionado!);
      }
    });
  }

  Future<void> _cargarParticipantesBarrio(String barrio) async {
    final db = await DatabaseHelper.database;
    final result = await db.query('participantes', where: 'barrio = ?', whereArgs: [barrio]);
    setState(() {
      _participantesBarrio = result;
    });
  }

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
      await _cargarBarrios();
      if (_barrioSeleccionado != null) {
        await _cargarParticipantesBarrio(_barrioSeleccionado!);
      }

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
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Importar archivo Excel"),
                onPressed: importarExcel,
              ),
              const SizedBox(width: 20),
              Text(
                mensaje,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Barrios cargados',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _barrioSeleccionado,
                      isExpanded: true,
                      items: _barrios
                          .map((barrio) => DropdownMenuItem(
                                value: barrio,
                                child: Text(barrio),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _barrioSeleccionado = val;
                        });
                        if (val != null) _cargarParticipantesBarrio(val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _participantesBarrio.isEmpty
                ? const Center(child: Text('No hay participantes para este barrio.'))
                : Card(
                    elevation: 2,
                    child: ListView.builder(
                      itemCount: _participantesBarrio.length,
                      itemBuilder: (context, index) {
                        final p = _participantesBarrio[index];
                        return ListTile(
                          title: Text(p['nombre'] ?? ''),
                          subtitle: Text('DNI: ${p['dni']} | Grupo: ${p['grupo']} | Bolilla: ${p['numero_bolilla']}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
