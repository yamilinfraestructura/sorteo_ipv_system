import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';

class ExportGanadoresScreen extends StatefulWidget {
  const ExportGanadoresScreen({super.key});

  @override
  State<ExportGanadoresScreen> createState() => _ExportGanadoresScreenState();
}

class _ExportGanadoresScreenState extends State<ExportGanadoresScreen> {
  List<String> _barrios = [];
  String? _barrioSeleccionado;
  List<String> _grupos = [];
  String? _grupoSeleccionado;
  String _mensaje = '';

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
      }
    });
    if (_barrioSeleccionado != null) {
      await _cargarGrupos(_barrioSeleccionado!);
    }
  }

  Future<void> _cargarGrupos(String barrio) async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT "group" FROM participantes WHERE neighborhood = ?',
      [barrio],
    );
    setState(() {
      _grupos = result.map((e) => e['group'] as String).toList();
      if (_grupos.isNotEmpty && _grupoSeleccionado == null) {
        _grupoSeleccionado = _grupos.first;
      }
    });
  }

  Future<void> exportarExcel(BuildContext context) async {
    if (_barrioSeleccionado == null || _grupoSeleccionado == null) {
      setState(() => _mensaje = 'Seleccioná un barrio y grupo para exportar.');
      return;
    }
    final db = await DatabaseHelper.database;
    final ganadores = await db.query(
      'ganadores',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [_barrioSeleccionado, _grupoSeleccionado],
      orderBy: 'position ASC',
    );
    if (ganadores.isEmpty) {
      _mostrarMensaje(context, 'No hay ganadores registrados para este barrio y grupo.');
      return;
    }
    // Obtener datos generales del primer ganador
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
    // Fila 2: Título (B-F combinadas)
    sheet.appendRow([null, TextCellValue('Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B2"), CellIndex.indexByString("F2"));
    // Fila 3: vacía
    sheet.appendRow([]);
    // Fila 4: Grupo (B-F combinadas)
    sheet.appendRow([null, TextCellValue('Grupo: $grupo'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B4"), CellIndex.indexByString("F4"));
    // Fila 5: Número de viviendas y familias (B-F combinadas)
    sheet.appendRow([null, TextCellValue('$viviendas Viviendas, $familias Familias'), null, null, null, null]);
    sheet.merge(CellIndex.indexByString("B5"), CellIndex.indexByString("F5"));
    // Fila 6: Barrio (B-F combinadas)
    sheet.appendRow([null, TextCellValue('Barrio: $barrio'), null, null, null, null]);
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
          IntCellValue(ganador['position'] as int),
          IntCellValue(p['order_number'] as int),
          TextCellValue(p['document'].toString()),
          TextCellValue(p['full_name'].toString()),
        ]);
        rowIndex++;
      }
    }
    // Ajustar el ancho de las columnas B-E
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }
    String cleanFileName(String input) {
      // Reemplaza caracteres no permitidos por guion bajo
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
        title: Text(
          "Exportación",
          style: TextStyle(fontSize: ResponsiveConfig.subtitleSize),
        ),
        content: Text(
          msg,
          style: TextStyle(fontSize: ResponsiveConfig.bodySize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Aceptar",
              style: TextStyle(fontSize: ResponsiveConfig.bodySize),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveConfig.paddingLarge),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Seleccioná un barrio',
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
                          _grupoSeleccionado = null;
                        });
                        if (val != null) await _cargarGrupos(val);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveConfig.spacingMedium),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Seleccioná un grupo',
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
                      onChanged: (val) {
                        setState(() {
                          _grupoSeleccionado = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConfig.spacingLarge),
          ElevatedButton.icon(
            icon: Icon(Icons.download, size: ResponsiveConfig.iconSizeMedium),
            label: Text(
              "Exportar ganadores a Excel",
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
            onPressed: () => exportarExcel(context),
          ),
          SizedBox(height: ResponsiveConfig.spacingMedium),
          if (_mensaje.isNotEmpty)
            Text(
              _mensaje,
              style: TextStyle(
                fontSize: ResponsiveConfig.bodySize,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
