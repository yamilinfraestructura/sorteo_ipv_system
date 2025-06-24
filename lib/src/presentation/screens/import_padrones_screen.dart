import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';

class ImportPadronesScreen extends StatefulWidget {
  const ImportPadronesScreen({super.key});

  @override
  State<ImportPadronesScreen> createState() => _ImportPadronesScreenState();
}

class _ImportPadronesScreenState extends State<ImportPadronesScreen> {
  String mensaje = 'Ningún archivo importado aún.';

  List<String> _barrios = [];
  String? _barrioSeleccionado = 'Seleccionar';
  List<String> _grupos = [];
  String? _grupoSeleccionado = 'Seleccionar';
  List<Map<String, dynamic>> _participantesBarrioGrupo = [];

  @override
  void initState() {
    super.initState();
    _verificarYCargar();
  }

  Future<void> _verificarYCargar() async {
    await DatabaseHelper.verificarEstructura();
    await _cargarBarrios();
  }

  Future<void> _cargarBarrios() async {
    final barrios = await DatabaseHelper.obtenerBarrios();
    setState(() {
      _barrios = ['Seleccionar', ...barrios];
      if (_barrios.length > 1 && (_barrioSeleccionado == null || !_barrios.contains(_barrioSeleccionado))) {
        _barrioSeleccionado = 'Seleccionar';
      }
    });
    if (_barrioSeleccionado != null && _barrioSeleccionado != 'Seleccionar') {
      await _cargarGrupos(_barrioSeleccionado!);
    } else {
      setState(() {
        _grupos = ['Seleccionar'];
        _grupoSeleccionado = 'Seleccionar';
        _participantesBarrioGrupo = [];
      });
    }
  }

  Future<void> _cargarGrupos(String barrio) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT "group" FROM participantes WHERE neighborhood = ?',
      [barrio],
    );
    setState(() {
      final grupos = result.map((e) => e['group'] as String).toList();
      _grupos = ['Seleccionar', ...grupos];
      if (_grupos.length > 1 && (_grupoSeleccionado == null || !_grupos.contains(_grupoSeleccionado))) {
        _grupoSeleccionado = 'Seleccionar';
      }
    });
    if (_grupoSeleccionado != null && _grupoSeleccionado != 'Seleccionar') {
      await _cargarParticipantesBarrioGrupo(_barrioSeleccionado!, _grupoSeleccionado!);
    } else {
      setState(() {
        _participantesBarrioGrupo = [];
      });
    }
  }

  Future<void> _cargarParticipantesBarrioGrupo(String barrio, String grupo) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'participantes',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrio, grupo],
    );
    setState(() {
      _participantesBarrioGrupo = result;
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
        String viviendasFamilias = rows[4][1]?.value.toString().trim() ?? ''; // Fila 5, Col B
        // Extraer números de viviendas y familias
        int viviendas = 0;
        int familias = 0;
        final regex = RegExp(r'(\d+)\s*Viviendas?,\s*(\d+)\s*Familias?', caseSensitive: false);
        final match = regex.firstMatch(viviendasFamilias);
        if (match != null) {
          viviendas = int.tryParse(match.group(1) ?? '') ?? 0;
          familias = int.tryParse(match.group(2) ?? '') ?? 0;
        }
        if (grupo.isEmpty || barrio.isEmpty) {
          setState(() => mensaje = 'Error: No se encontró el grupo o barrio en el archivo.');
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
          // Mostrar diálogo para preguntar si desea actualizar
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
            setState(() => mensaje = 'Importación cancelada. El padrón no fue actualizado.');
            return;
          }
          // Borrar participantes anteriores de ese barrio y grupo
          await db.delete(
            'participantes',
            where: 'neighborhood = ? AND "group" = ?',
            whereArgs: [barrio, grupo],
          );
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
            'viviendas': viviendas,
            'familias': familias,
          });
        }
        if (participantes.isNotEmpty) {
          setState(() => mensaje = 'Guardando participantes en la base de datos...');
          await DatabaseHelper.insertarParticipantesLote(participantes);
          // Recargar la vista
          await _cargarBarrios();
          if (_barrioSeleccionado != null) {
            await _cargarGrupos(_barrioSeleccionado!);
          }
          setState(() => mensaje = 'Importación exitosa: ${participantes.length} participantes agregados para "$barrio" - "$grupo".');
        } else {
          setState(() => mensaje = 'Error: No se encontraron participantes válidos en el archivo.');
        }
      } else {
        setState(() => mensaje = 'Importación cancelada por el usuario.');
      }
    } catch (e) {
      setState(() => mensaje = 'Error durante la importación: \\${e.toString()}');
      print('Error en importarExcel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveConfig.paddingLarge),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.upload_file, size: ResponsiveConfig.iconSizeMedium),
                label: Text(
                  "Importar archivo Excel",
                  style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveConfig.paddingMedium,
                    vertical: ResponsiveConfig.paddingSmall,
                  ),
                  minimumSize: Size(
                    ResponsiveConfig.minButtonWidth,
                    ResponsiveConfig.buttonHeight,
                  ),
                ),
                onPressed: importarExcel,
              ),
              SizedBox(width: ResponsiveConfig.spacingMedium),
              Expanded(
                child: Text(
                  mensaje,
                  style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConfig.spacingLarge),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Barrios cargados',
                    labelStyle: TextStyle(fontSize: ResponsiveConfig.bodySize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveConfig.borderRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConfig.paddingMedium,
                      vertical: ResponsiveConfig.paddingSmall,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _barrioSeleccionado,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: ResponsiveConfig.bodySize,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      items: _barrios
                          .map((barrio) => DropdownMenuItem(
                                value: barrio,
                                child: Text(barrio),
                              ))
                          .toList(),
                      onChanged: (val) async {
                        setState(() {
                          _barrioSeleccionado = val;
                          _grupoSeleccionado = 'Seleccionar';
                        });
                        if (val != null && val != 'Seleccionar') {
                          await _cargarGrupos(val);
                        } else {
                          setState(() {
                            _grupos = ['Seleccionar'];
                            _grupoSeleccionado = 'Seleccionar';
                            _participantesBarrioGrupo = [];
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveConfig.spacingMedium),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Grupos cargados',
                    labelStyle: TextStyle(fontSize: ResponsiveConfig.bodySize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveConfig.borderRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConfig.paddingMedium,
                      vertical: ResponsiveConfig.paddingSmall,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _grupoSeleccionado,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: ResponsiveConfig.bodySize,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      items: _grupos
                          .map((grupo) => DropdownMenuItem(
                                value: grupo,
                                child: Text(grupo),
                              ))
                          .toList(),
                      onChanged: (val) async {
                        setState(() {
                          _grupoSeleccionado = val;
                        });
                        if (val != null && val != 'Seleccionar' && _barrioSeleccionado != null && _barrioSeleccionado != 'Seleccionar') {
                          await _cargarParticipantesBarrioGrupo(_barrioSeleccionado!, val);
                        } else {
                          setState(() {
                            _participantesBarrioGrupo = [];
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConfig.spacingMedium),
          Expanded(
            child: (_barrioSeleccionado == null || _barrioSeleccionado == 'Seleccionar' || _grupoSeleccionado == null || _grupoSeleccionado == 'Seleccionar')
                ? Center(
                    child: Text(
                      'Selecciona un barrio y grupo para ver los participantes.',
                      style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                    ),
                  )
                : _participantesBarrioGrupo.isEmpty
                    ? Center(
                        child: Text(
                          'No hay participantes para este barrio y grupo.',
                          style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                        ),
                      )
                    : Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveConfig.borderRadius),
                        ),
                        child: ListView.builder(
                          itemCount: _participantesBarrioGrupo.length,
                          itemBuilder: (context, index) {
                            final p = _participantesBarrioGrupo[index];
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ResponsiveConfig.paddingMedium,
                                vertical: ResponsiveConfig.paddingSmall,
                              ),
                              title: Text(
                                p['full_name'] ?? '',
                                style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                              ),
                              subtitle: Text(
                                'Documento: \\${p['document']} | Grupo: \\${p['group']} | Barrio: \\${p['neighborhood']} | Viviendas: \\${p['viviendas'] ?? '-'} | Familias: \\${p['familias'] ?? '-'}',
                                style: TextStyle(fontSize: ResponsiveConfig.smallSize),
                              ),
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
