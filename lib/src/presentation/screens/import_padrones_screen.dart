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
    _verificarYCargar();
  }

  Future<void> _verificarYCargar() async {
    // Verificar estructura de la tabla
    await DatabaseHelper.verificarEstructura();
    // Cargar barrios
    await _cargarBarrios();
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
    final result = await db.query(
      'participantes', 
      where: 'neighborhood = ?', 
      whereArgs: [barrio]
    );
    setState(() {
      _participantesBarrio = result;
    });
  }

  Future<void> importarExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        setState(() => mensaje = 'Procesando archivo...');
        
        File file = File(result.files.single.path!);
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);

        final table = excel.tables.values.first; // Tomamos la primera hoja
        final rows = table.rows;

        // Extraemos info general
        String grupo = rows[3][1]?.value.toString().trim() ?? '';      // Fila 4, Col B
        String barrio = rows[5][1]?.value.toString().trim() ?? '';     // Fila 6, Col B

        if (grupo.isEmpty || barrio.isEmpty) {
          setState(() => mensaje = 'Error: No se encontró el grupo o barrio en el archivo.');
          return;
        }

        // Verificar si ya existe un padrón para ese barrio y grupo
        final db = await DatabaseHelper.database;
        final existePadron = await db.query(
          'participantes',
          where: 'neighborhood = ? AND "group" = ?',
          whereArgs: [barrio, grupo],
          limit: 1,
        );
        if (existePadron.isNotEmpty) {
          setState(() => mensaje = 'Ya existe un padrón cargado para el barrio "$barrio" y grupo "$grupo".');
          return;
        }

        List<Map<String, dynamic>> participantes = [];

        for (int i = 8; i < rows.length; i++) {
          final row = rows[i];

          if (row.length < 5 || row[1] == null) continue; // Evitar filas vacías o mal formateadas

          int position = int.tryParse(row[1]?.value.toString() ?? '') ?? 0;
          int order = int.tryParse(row[2]?.value.toString() ?? '') ?? 0;
          String documento = row[3]?.value.toString().trim() ?? '';
          String nombre = row[4]?.value.toString().trim() ?? '';

          if (documento.isEmpty || nombre.isEmpty) continue; // Filtrar vacíos

          participantes.add({
            'position': position,
            'order_number': order,
            'document': documento,
            'full_name': nombre,
            'group': grupo,
            'neighborhood': barrio,
          });
        }

        if (participantes.isNotEmpty) {
          setState(() => mensaje = 'Guardando participantes en la base de datos...');
          await DatabaseHelper.insertarParticipantesLote(participantes);
          // Recargar la vista
          await _cargarBarrios();
          if (_barrioSeleccionado != null) {
            await _cargarParticipantesBarrio(_barrioSeleccionado!);
          }
          setState(() => mensaje = 'Importación exitosa: ${participantes.length} participantes agregados para "$barrio" - "$grupo".');
        } else {
          setState(() => mensaje = 'Error: No se encontraron participantes válidos en el archivo.');
        }
      } else {
        setState(() => mensaje = 'Importación cancelada por el usuario.');
      }
    } catch (e) {
      setState(() => mensaje = 'Error durante la importación: ${e.toString()}');
      print('Error en importarExcel: $e');
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
                          title: Text(p['full_name'] ?? ''),
                          subtitle: Text('Documento: ${p['document']} | Grupo: ${p['group']} | Barrio: ${p['neighborhood']}'),
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
