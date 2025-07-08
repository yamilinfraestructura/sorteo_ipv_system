import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:sorteo_ipv_system/src/data/helper/synology_nas_helper.dart';
import 'package:sorteo_ipv_system/src/data/helper/ftp_helper.dart';

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
  var sorteoCerrado = false.obs;

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
    await verificarSorteoCerrado();
  }

  /// Maneja el cambio de grupo en el filtro.
  void onGrupoChanged(String? val) async {
    grupoSeleccionado.value = val ?? '';
    await verificarSorteoCerrado();
  }

  Future<void> verificarSorteoCerrado() async {
    sorteoCerrado.value = false;
    if (barrioSeleccionado.value.isEmpty || grupoSeleccionado.value.isEmpty)
      return;
    final db = await DatabaseHelper.database;
    // Contar ganadores
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [barrioSeleccionado.value, grupoSeleccionado.value],
    );
    final totalGanadores =
        countResult.first['count'] is int
            ? countResult.first['count'] as int
            : int.tryParse(countResult.first['count']?.toString() ?? '0') ?? 0;
    // Obtener viviendas
    final infoResult = await db.query(
      'participantes',
      columns: ['viviendas'],
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
      limit: 1,
    );
    int viviendas = 0;
    if (infoResult.isNotEmpty) {
      final v = infoResult.first['viviendas'];
      viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    }
    sorteoCerrado.value = viviendas > 0 && totalGanadores == viviendas;
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
      mostrarMensaje(
        context,
        'No hay ganadores registrados para este barrio y grupo.',
      );
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
    final viviendas =
        p['viviendas'] is int
            ? p['viviendas']
            : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
    final familias =
        p['familias'] is int
            ? p['familias']
            : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;

    // Crear el Excel y renombrar la hoja por defecto a 'Ganadores' si existe
    final excelFile = excel.Excel.createExcel();
    String defaultSheet = excelFile.getDefaultSheet() ?? '';
    if (defaultSheet.isNotEmpty && defaultSheet != 'Ganadores') {
      excelFile.rename(defaultSheet, 'Ganadores');
    }
    // Eliminar cualquier otra hoja que no sea 'Ganadores'
    for (final sheetName in List<String>.from(excelFile.sheets.keys)) {
      if (sheetName != 'Ganadores') {
        excelFile.delete(sheetName);
      }
    }
    final sheet = excelFile['Ganadores'];
    // Fila 1 vacía
    sheet.appendRow([null, null, null, null, null, null]);
    // Fila 2: Título
    sheet.appendRow([
      null,
      excel.TextCellValue(
        'Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025',
      ),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B2"),
      excel.CellIndex.indexByString("F2"),
    );
    // Fila 3 vacía
    sheet.appendRow([null, null, null, null, null, null]);
    // Fila 4: Grupo
    sheet.appendRow([
      null,
      excel.TextCellValue('Grupo: $grupo'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B4"),
      excel.CellIndex.indexByString("F4"),
    );
    // Fila 5: Viviendas y Familias
    sheet.appendRow([
      null,
      excel.TextCellValue('$viviendas Viviendas, $familias Familias'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B5"),
      excel.CellIndex.indexByString("F5"),
    );
    // Fila 6: Barrio
    sheet.appendRow([
      null,
      excel.TextCellValue('Barrio: $barrio'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B6"),
      excel.CellIndex.indexByString("F6"),
    );
    // Fila 7 vacía
    sheet.appendRow([null, null, null, null, null, null]);
    // Fila 8 vacía (nueva para ajustar encabezado en fila 9)
    sheet.appendRow([null, null, null, null, null, null]);
    // Fila 9: Encabezados
    sheet.appendRow([
      null,
      excel.TextCellValue('Posición'),
      excel.TextCellValue('Nro Orden'),
      excel.TextCellValue('Documento'),
      excel.TextCellValue('Apellido Nombre'),
    ]);
    for (var col = 1; col <= 4; col++) {
      final headerCell = sheet.cell(
        excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 9),
      );
      headerCell.cellStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
      );
    }
    // Los datos deben empezar en la fila 10
    int rowIndex = 9;
    for (var ganador in ganadores) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [ganador['participanteId']],
      );
      if (participante.isNotEmpty) {
        final p = participante.first;
        final pos = ganador['position'];
        final order = p['order_number'];
        final doc = p['document']?.toString().trim() ?? '';
        final nombre = p['full_name']?.toString().trim() ?? '';
        // Solo agregar si position es válido y la fila no está vacía
        if (pos != null &&
            pos != 0 &&
            order != null &&
            order != 0 &&
            doc.isNotEmpty &&
            nombre.isNotEmpty) {
          final fila = [
            null,
            excel.IntCellValue(pos as int),
            excel.IntCellValue(order as int),
            excel.TextCellValue(doc),
            excel.TextCellValue(nombre),
          ];
          final tieneDatos = fila
              .skip(1)
              .any(
                (cell) =>
                    (cell is excel.IntCellValue &&
                        cell.value != null &&
                        cell.value != 0) ||
                    (cell is excel.TextCellValue &&
                        (cell.value?.toString().trim().isNotEmpty ?? false)),
              );
          if (tieneDatos) {
            // Escribir la fila de datos en la fila correspondiente (rowIndex)
            for (var col = 0; col < fila.length; col++) {
              sheet.updateCell(
                excel.CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: rowIndex,
                ),
                fila[col],
              );
            }
            rowIndex++;
          }
        }
      }
    }
    // Eliminar la fila 10 (índice 9) si está vacía
    if (sheet.rows.length > 9 &&
        (sheet.rows[9].every((cell) => cell == null))) {
      sheet.removeRow(9);
    }
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }
    String cleanFileName(String input) {
      return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    }

    final safeBarrio = cleanFileName(barrio);
    final safeGrupo = cleanFileName(grupo);
    final fileName =
        'Barrio $safeBarrio - Grupo $safeGrupo - Definitivo para importar Ganadores.xlsx';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (savePath == null) return;
    final fileBytes = excelFile.encode();
    if (fileBytes == null) {
      // ignore: use_build_context_synchronously
      mostrarMensaje(context, 'Error al generar archivo Excel.');
      return;
    }
    // --- DATOS DEL NAS desde configuración ---
    final nasHost = await DatabaseHelper.getSetting('nas_host') ?? '';
    final user = await DatabaseHelper.getSetting('nas_user') ?? '';
    final password = await DatabaseHelper.getSetting('nas_password') ?? '';
    // Usar '/IPV' como path de destino para la validación
    final pathDestinoConfig = await DatabaseHelper.getSetting('nas_path') ?? '';
    if (nasHost.isEmpty ||
        user.isEmpty ||
        password.isEmpty ||
        pathDestinoConfig.isEmpty) {
      mostrarMensaje(
        context,
        'Configurá los datos del NAS en la pantalla de configuración.',
      );
      return;
    }
    final nasHelper = SynologyNasHelper(
      nasHost: nasHost,
      user: user,
      password: password,
    );
    final sid = await nasHelper.login();
    if (sid == null) {
      mostrarMensaje(context, 'Error de autenticación con el NAS.');
      return;
    }
    // --- DEBUG: Tamaño de fileBytes antes de escribir archivo ---
    print('[NAS DEBUG] fileBytes: \\${fileBytes.length} bytes');
    final file = File(savePath);
    // --- DEBUG: Antes de escribir archivo ---
    print('[NAS DEBUG] Archivo a crear: \\${file.path}');
    await file.writeAsBytes(fileBytes);
    // --- DEBUG: Después de escribir archivo ---
    print('[NAS DEBUG] Archivo local generado:');
    print('Ruta: \\${file.path}');
    print('Existe: \\${await file.exists()}');
    print('Tamaño: \\${await file.length()} bytes');
    print('Nombre para la API: \\${fileName}');
    print('Path destino para la API (validación): $pathDestinoConfig');

    // Intentar subir a diferentes paths
    final pathsAProbar = ['/ganadores', '/IPV', '/', 'IPV'];
    bool ok = false;
    for (final path in pathsAProbar) {
      print('[NAS DEBUG] Intentando subir a $path ...');
      ok = await nasHelper.uploadFile(
        sid: sid,
        pathDestino: path,
        file: file,
        fileName: fileName,
      );
      if (ok) {
        print('[NAS DEBUG] Subida exitosa a $path');
        break;
      } else {
        print('[NAS DEBUG] Falló subida a $path');
      }
    }
    await nasHelper.logout(sid);
    if (ok) {
      mostrarMensaje(context, '¡Archivo subido correctamente al NAS!');
    } else {
      mostrarMensaje(
        context,
        'Falló la subida al NAS en todos los paths probados.',
      );
    }
  }

  /// Limpia el nombre del archivo para evitar caracteres no permitidos en Windows
  String cleanFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\/:*?"<>|–]'), '_');
  }

  /// Exporta los ganadores filtrados a un archivo PDF con el formato requerido.
  Future<void> exportarPdf(BuildContext context) async {
    final db = await DatabaseHelper.database;
    final ganadores = await db.query(
      'ganadores',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
      orderBy: 'position ASC',
    );
    final participantes = await db.query(
      'participantes',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
    );
    int viviendas = 0;
    int familias = 0;
    String barrio = '';
    String grupo = '';
    if (participantes.isNotEmpty) {
      final p = participantes.first;
      viviendas =
          p['viviendas'] is int
              ? p['viviendas'] as int
              : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
      familias =
          p['familias'] is int
              ? p['familias'] as int
              : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;
      barrio = p['neighborhood']?.toString() ?? '';
      grupo = p['group']?.toString() ?? '';
    }
    // Construir la lista de filas para la tabla PDF
    List<List<dynamic>> filasTabla = [];
    for (var ganador in ganadores) {
      final participante = participantes.firstWhere(
        (p) => p['id'] == ganador['participanteId'],
        orElse: () => {},
      );
      if (participante.isEmpty) continue;
      final pos = ganador['position'];
      final order = participante['order_number'];
      final doc = participante['document']?.toString().trim() ?? '';
      final nombre = participante['full_name']?.toString().trim() ?? '';
      if (pos == null ||
          pos == 0 ||
          order == null ||
          order == 0 ||
          doc.isEmpty ||
          nombre.isEmpty) {
        continue;
      }
      filasTabla.add([pos, order, doc, nombre]);
    }
    final pdf = pw.Document();
    // Cargar la fuente Roboto para el PDF
    final robotoFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-VariableFont_wdth,wght.ttf'),
    );
    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Grupo: $grupo',
                style: pw.TextStyle(fontSize: 12, font: robotoFont),
              ),
              pw.Text(
                '$viviendas Viviendas, $familias Familias',
                style: pw.TextStyle(fontSize: 12, font: robotoFont),
              ),
              pw.Text(
                'Barrio: $barrio',
                style: pw.TextStyle(fontSize: 12, font: robotoFont),
              ),
              pw.SizedBox(height: 18),
              pw.Table.fromTextArray(
                headers: [
                  'Posición',
                  'Nro Orden',
                  'Documento',
                  'Apellido Nombre',
                ],
                data: filasTabla,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: robotoFont,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: pw.TextStyle(fontSize: 10, font: robotoFont),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                border: pw.TableBorder.all(
                  width: 0.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
      ),
    );
    // Limpiar el nombre del archivo antes de sugerirlo
    final suggestedFileName = cleanFileName(
      'Ganadores - Barrio $barrio - Grupo $grupo.pdf',
    );
    final output = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo PDF',
      fileName: suggestedFileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (output == null) return;
    final file = File(output);
    await file.writeAsBytes(await pdf.save());
    mostrarMensaje(context, 'Archivo PDF exportado correctamente.');
  }

  /// Muestra un mensaje emergente (diálogo) en la pantalla.
  void mostrarMensaje(BuildContext context, String msg) {
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return RawKeyboardListener(
                focusNode: focusNode,
                autofocus: true,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
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
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  /// Método público para recargar barrios y grupos desde la UI si es necesario
  Future<void> recargarBarriosYGrupos() async {
    await cargarBarrios();
    if (barrioSeleccionado.value.isNotEmpty) {
      await cargarGrupos(barrioSeleccionado.value);
    }
  }

  Future<bool> solicitarPinYValidar(BuildContext context) async {
    final loginCtrl = Get.find<LoginController>();
    final user = loginCtrl.usuarioLogueado.value;
    final TextEditingController pinController = TextEditingController();
    bool autorizado = false;
    String errorPin = '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final focusNode = FocusNode();
        return StatefulBuilder(
          builder: (context, setState) {
            return RawKeyboardListener(
              focusNode: focusNode,
              autofocus: true,
              onKey: (RawKeyEvent event) async {
                if (event is RawKeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                  final pinIngresado = pinController.text;
                  final perfil = user?['perfil_user']?.toString() ?? '';
                  final pinHashGuardado = user?['password']?.toString() ?? '';
                  final pinHashIngresado =
                      sha256.convert(utf8.encode(pinIngresado)).toString();
                  if (pinIngresado.length == 6 &&
                      perfil.isNotEmpty &&
                      (perfil == 'Desarrollador' ||
                          perfil == 'Administrador') &&
                      pinHashIngresado == pinHashGuardado) {
                    autorizado = true;
                    Navigator.pop(context);
                  } else {
                    setState(() => errorPin = 'Pin o perfil incorrecto');
                  }
                }
              },
              child: AlertDialog(
                title: const Text('Confirmar exportación'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ingresá tu PIN para confirmar la exportación:'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 220,
                      child: Pinput(
                        length: 6,
                        controller: pinController,
                        obscureText: true,
                        autofocus: true,
                        defaultPinTheme: PinTheme(
                          width: 36,
                          height: 48,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            border: Border.all(color: Colors.orange, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 36,
                          height: 48,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[200],
                            border: Border.all(
                              color: Colors.deepOrange,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        submittedPinTheme: PinTheme(
                          width: 36,
                          height: 48,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[300],
                            border: Border.all(
                              color: Colors.deepOrange,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onCompleted: (_) {},
                      ),
                    ),
                    if (errorPin.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorPin,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      final pinIngresado = pinController.text;
                      final perfil = user?['perfil_user']?.toString() ?? '';
                      final pinHashGuardado =
                          user?['password']?.toString() ?? '';
                      final pinHashIngresado =
                          sha256.convert(utf8.encode(pinIngresado)).toString();
                      if (pinIngresado.length == 6 &&
                          perfil.isNotEmpty &&
                          (perfil == 'Desarrollador' ||
                              perfil == 'Administrador') &&
                          pinHashIngresado == pinHashGuardado) {
                        autorizado = true;
                        Navigator.pop(context);
                      } else {
                        setState(() => errorPin = 'Pin o perfil incorrecto');
                      }
                    },
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return autorizado;
  }

  /// Exporta los ganadores filtrados a un archivo Excel usando la ruta de configuración si existe.
  Future<void> exportarExcelConRutaConfig(BuildContext context) async {
    final autorizado = await solicitarPinYValidar(context);
    if (!autorizado) return;
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
      mostrarMensaje(
        context,
        'No hay ganadores registrados para este barrio y grupo.',
      );
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
    final viviendas =
        p['viviendas'] is int
            ? p['viviendas']
            : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
    final familias =
        p['familias'] is int
            ? p['familias']
            : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;

    final excelFile = excel.Excel.createExcel();
    String defaultSheet = excelFile.getDefaultSheet() ?? '';
    if (defaultSheet.isNotEmpty && defaultSheet != 'Ganadores') {
      excelFile.rename(defaultSheet, 'Ganadores');
    }
    for (final sheetName in List<String>.from(excelFile.sheets.keys)) {
      if (sheetName != 'Ganadores') {
        excelFile.delete(sheetName);
      }
    }
    final sheet = excelFile['Ganadores'];
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue(
        'Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025',
      ),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B2"),
      excel.CellIndex.indexByString("F2"),
    );
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue('Grupo: $grupo'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B4"),
      excel.CellIndex.indexByString("F4"),
    );
    sheet.appendRow([
      null,
      excel.TextCellValue('$viviendas Viviendas, $familias Familias'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B5"),
      excel.CellIndex.indexByString("F5"),
    );
    sheet.appendRow([
      null,
      excel.TextCellValue('Barrio: $barrio'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B6"),
      excel.CellIndex.indexByString("F6"),
    );
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue('Posición'),
      excel.TextCellValue('Nro Orden'),
      excel.TextCellValue('Documento'),
      excel.TextCellValue('Apellido Nombre'),
    ]);
    for (var col = 1; col <= 4; col++) {
      final headerCell = sheet.cell(
        excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 9),
      );
      headerCell.cellStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
      );
    }
    int rowIndex = 9;
    for (var ganador in ganadores) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [ganador['participanteId']],
      );
      if (participante.isNotEmpty) {
        final p = participante.first;
        final pos = ganador['position'];
        final order = p['order_number'];
        final doc = p['document']?.toString().trim() ?? '';
        final nombre = p['full_name']?.toString().trim() ?? '';
        if (pos != null &&
            pos != 0 &&
            order != null &&
            order != 0 &&
            doc.isNotEmpty &&
            nombre.isNotEmpty) {
          final fila = [
            null,
            excel.IntCellValue(pos as int),
            excel.IntCellValue(order as int),
            excel.TextCellValue(doc),
            excel.TextCellValue(nombre),
          ];
          final tieneDatos = fila
              .skip(1)
              .any(
                (cell) =>
                    (cell is excel.IntCellValue &&
                        cell.value != null &&
                        cell.value != 0) ||
                    (cell is excel.TextCellValue &&
                        (cell.value?.toString().trim().isNotEmpty ?? false)),
              );
          if (tieneDatos) {
            for (var col = 0; col < fila.length; col++) {
              sheet.updateCell(
                excel.CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: rowIndex,
                ),
                fila[col],
              );
            }
            rowIndex++;
          }
        }
      }
    }
    if (sheet.rows.length > 9 &&
        (sheet.rows[9].every((cell) => cell == null))) {
      sheet.removeRow(9);
    }
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }
    String cleanFileName(String input) {
      return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    }

    final safeBarrio = cleanFileName(barrio);
    final safeGrupo = cleanFileName(grupo);
    // Obtener la ruta guardada
    final rutaGuardada = await DatabaseHelper.getSetting('save_path');
    String? savePath;
    if (rutaGuardada != null && rutaGuardada.trim().isNotEmpty) {
      // Crear el directorio si no existe
      final dir = Directory(rutaGuardada);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      savePath =
          '${dir.path}/Barrio $safeBarrio - Grupo $safeGrupo - Definitivo para importar Ganadores.xlsx';
    } else {
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo Excel',
        fileName:
            'Barrio $safeBarrio - Grupo $safeGrupo - Definitivo para importar Ganadores.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
    }
    if (savePath == null) return;
    final fileBytes = excelFile.encode();
    if (fileBytes == null) {
      mostrarMensaje(context, 'Error al generar archivo Excel.');
      return;
    }
    // --- DATOS DEL NAS desde configuración ---
    final nasHost = await DatabaseHelper.getSetting('nas_host') ?? '';
    final user = await DatabaseHelper.getSetting('nas_user') ?? '';
    final password = await DatabaseHelper.getSetting('nas_password') ?? '';
    // Usar '/IPV' como path de destino para la validación
    final pathDestinoConfig = await DatabaseHelper.getSetting('nas_path') ?? '';
    if (nasHost.isEmpty ||
        user.isEmpty ||
        password.isEmpty ||
        pathDestinoConfig.isEmpty) {
      mostrarMensaje(
        context,
        'Configurá los datos del NAS en la pantalla de configuración.',
      );
      return;
    }
    final nasHelper = SynologyNasHelper(
      nasHost: nasHost,
      user: user,
      password: password,
    );
    final sid = await nasHelper.login();
    if (sid == null) {
      mostrarMensaje(context, 'Error de autenticación con el NAS.');
      return;
    }
    // --- DEBUG: Tamaño de fileBytes antes de escribir archivo ---
    print('[NAS DEBUG] fileBytes: \\${fileBytes.length} bytes');
    final file = File(savePath);
    // --- DEBUG: Antes de escribir archivo ---
    print('[NAS DEBUG] Archivo a crear: \\${file.path}');
    await file.writeAsBytes(fileBytes);
    // --- DEBUG: Después de escribir archivo ---
    print('[NAS DEBUG] Archivo local generado:');
    print('Ruta: \\${file.path}');
    print('Existe: \\${await file.exists()}');
    print('Tamaño: \\${await file.length()} bytes');
    print('Nombre para la API: \\${savePath}');
    print('Path destino para la API (validación): $pathDestinoConfig');

    // Intentar subir a diferentes paths
    final pathsAProbar = ['/ganadores', '/IPV', '/', 'IPV'];
    bool ok = false;
    for (final path in pathsAProbar) {
      print('[NAS DEBUG] Intentando subir a $path ...');
      ok = await nasHelper.uploadFile(
        sid: sid,
        pathDestino: path,
        file: file,
        fileName: savePath,
      );
      if (ok) {
        print('[NAS DEBUG] Subida exitosa a $path');
        break;
      } else {
        print('[NAS DEBUG] Falló subida a $path');
      }
    }
    await nasHelper.logout(sid);
    if (ok) {
      mostrarMensaje(context, '¡Archivo subido correctamente al NAS!');
    } else {
      mostrarMensaje(
        context,
        'Falló la subida al NAS en todos los paths probados.',
      );
    }
  }

  /// Exporta los ganadores filtrados a un archivo PDF usando la ruta de configuración si existe.
  Future<void> exportarPdfConRutaConfig(BuildContext context) async {
    final autorizado = await solicitarPinYValidar(context);
    if (!autorizado) return;
    final db = await DatabaseHelper.database;
    final ganadores = await db.query(
      'ganadores',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
      orderBy: 'position ASC',
    );
    final participantes = await db.query(
      'participantes',
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
    );
    int viviendas = 0;
    int familias = 0;
    String barrio = '';
    String grupo = '';
    if (participantes.isNotEmpty) {
      final p = participantes.first;
      viviendas =
          p['viviendas'] is int
              ? p['viviendas'] as int
              : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
      familias =
          p['familias'] is int
              ? p['familias'] as int
              : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;
      barrio = p['neighborhood']?.toString() ?? '';
      grupo = p['group']?.toString() ?? '';
    }
    List<List<dynamic>> filasTabla = [];
    for (var ganador in ganadores) {
      final participante = participantes.firstWhere(
        (p) => p['id'] == ganador['participanteId'],
        orElse: () => {},
      );
      if (participante.isEmpty) continue;
      final pos = ganador['position'];
      final order = participante['order_number'];
      final doc = participante['document']?.toString().trim() ?? '';
      final nombre = participante['full_name']?.toString().trim() ?? '';
      if (pos == null ||
          pos == 0 ||
          order == null ||
          order == 0 ||
          doc.isEmpty ||
          nombre.isEmpty) {
        continue;
      }
      filasTabla.add([pos, order, doc, nombre]);
    }
    final pdf = pw.Document();
    final robotoFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-VariableFont_wdth,wght.ttf'),
    );
    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: robotoFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Grupo: $grupo',
                style: pw.TextStyle(fontSize: 12, font: robotoFont),
              ),
              pw.Text(
                '$viviendas Viviendas, $familias Familias',
                style: pw.TextStyle(fontSize: 12, font: robotoFont),
              ),
              pw.Text(
                'Barrio: $barrio',
                style: pw.TextStyle(fontSize: 12, font: robotoFont),
              ),
              pw.SizedBox(height: 18),
              pw.Table.fromTextArray(
                headers: [
                  'Posición',
                  'Nro Orden',
                  'Documento',
                  'Apellido Nombre',
                ],
                data: filasTabla,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  font: robotoFont,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: pw.TextStyle(fontSize: 10, font: robotoFont),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                border: pw.TableBorder.all(
                  width: 0.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
      ),
    );
    String cleanFileName(String input) {
      return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    }

    final safeBarrio = cleanFileName(barrio);
    final safeGrupo = cleanFileName(grupo);
    final suggestedFileName =
        'Ganadores - Barrio $safeBarrio - Grupo $safeGrupo.pdf';
    final rutaGuardada = await DatabaseHelper.getSetting('save_path');
    String? output;
    if (rutaGuardada != null && rutaGuardada.trim().isNotEmpty) {
      final dir = Directory(rutaGuardada);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      output = '${dir.path}/$suggestedFileName';
    } else {
      output = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo PDF',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    }
    if (output == null) return;
    final file = File(output);
    await file.writeAsBytes(await pdf.save());
    mostrarMensaje(context, 'Archivo PDF exportado correctamente.');
  }

  Future<void> exportarConPin(BuildContext context) async {
    final autorizado = await solicitarPinYValidar(context);
    if (autorizado) {
      await exportarExcel(context);
    } else {
      Get.snackbar(
        'Error',
        'No se pudo exportar: PIN o perfil incorrecto.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  // Agregar función para mostrar mensaje con botón para abrir carpeta
  void mostrarMensajeConAccion(
    BuildContext context,
    String mensaje,
    String filePath,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exportación completada'),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () async {
                  // Abrir la carpeta del archivo (Windows)
                  try {
                    final directory = File(filePath).parent.path;
                    if (Platform.isWindows) {
                      await Process.run('explorer', [directory]);
                    } else {
                      await launchUrl(Uri.file(directory));
                    }
                  } catch (_) {}
                },
                child: const Text('Abrir carpeta'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  /// Sube el archivo Excel generado al NAS Synology usando la API de File Station
  Future<void> subirExcelAlNas(BuildContext context) async {
    if (barrioSeleccionado.value.isEmpty || grupoSeleccionado.value.isEmpty) {
      mostrarMensaje(context, 'Seleccioná un barrio y grupo para exportar.');
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
      mostrarMensaje(
        context,
        'No hay ganadores registrados para este barrio y grupo.',
      );
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
    final viviendas =
        p['viviendas'] is int
            ? p['viviendas']
            : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
    final familias =
        p['familias'] is int
            ? p['familias']
            : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;

    // Crear el Excel (igual que en exportarExcel)
    final excelFile = excel.Excel.createExcel();
    String defaultSheet = excelFile.getDefaultSheet() ?? '';
    if (defaultSheet.isNotEmpty && defaultSheet != 'Ganadores') {
      excelFile.rename(defaultSheet, 'Ganadores');
    }
    for (final sheetName in List<String>.from(excelFile.sheets.keys)) {
      if (sheetName != 'Ganadores') {
        excelFile.delete(sheetName);
      }
    }
    final sheet = excelFile['Ganadores'];
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue(
        'Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025',
      ),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B2"),
      excel.CellIndex.indexByString("F2"),
    );
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue('Grupo: $grupo'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B4"),
      excel.CellIndex.indexByString("F4"),
    );
    sheet.appendRow([
      null,
      excel.TextCellValue('$viviendas Viviendas, $familias Familias'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B5"),
      excel.CellIndex.indexByString("F5"),
    );
    sheet.appendRow([
      null,
      excel.TextCellValue('Barrio: $barrio'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B6"),
      excel.CellIndex.indexByString("F6"),
    );
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue('Posición'),
      excel.TextCellValue('Nro Orden'),
      excel.TextCellValue('Documento'),
      excel.TextCellValue('Apellido Nombre'),
    ]);
    for (var col = 1; col <= 4; col++) {
      final headerCell = sheet.cell(
        excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 9),
      );
      headerCell.cellStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
      );
    }
    int rowIndex = 9;
    for (var ganador in ganadores) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [ganador['participanteId']],
      );
      if (participante.isNotEmpty) {
        final p = participante.first;
        final pos = ganador['position'];
        final order = p['order_number'];
        final doc = p['document']?.toString().trim() ?? '';
        final nombre = p['full_name']?.toString().trim() ?? '';
        if (pos != null &&
            pos != 0 &&
            order != null &&
            order != 0 &&
            doc.isNotEmpty &&
            nombre.isNotEmpty) {
          final fila = [
            null,
            excel.IntCellValue(pos as int),
            excel.IntCellValue(order as int),
            excel.TextCellValue(doc),
            excel.TextCellValue(nombre),
          ];
          final tieneDatos = fila
              .skip(1)
              .any(
                (cell) =>
                    (cell is excel.IntCellValue &&
                        cell.value != null &&
                        cell.value != 0) ||
                    (cell is excel.TextCellValue &&
                        (cell.value?.toString().trim().isNotEmpty ?? false)),
              );
          if (tieneDatos) {
            for (var col = 0; col < fila.length; col++) {
              sheet.updateCell(
                excel.CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: rowIndex,
                ),
                fila[col],
              );
            }
            rowIndex++;
          }
        }
      }
    }
    if (sheet.rows.length > 9 &&
        (sheet.rows[9].every((cell) => cell == null))) {
      sheet.removeRow(9);
    }
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }
    String cleanFileName(String input) {
      return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    }

    final safeBarrio = cleanFileName(barrio);
    final safeGrupo = cleanFileName(grupo);
    final fileName =
        'Barrio $safeBarrio - Grupo $safeGrupo - Definitivo para importar Ganadores.xlsx';
    final tempDir = Directory.systemTemp;
    final fileBytes = excelFile.encode();
    if (fileBytes == null) {
      mostrarMensaje(context, 'Error al generar archivo Excel.');
      return;
    }
    // --- DATOS DEL NAS desde configuración ---
    final nasHost = await DatabaseHelper.getSetting('nas_host') ?? '';
    final user = await DatabaseHelper.getSetting('nas_user') ?? '';
    final password = await DatabaseHelper.getSetting('nas_password') ?? '';
    // Usar '/IPV' como path de destino para la validación
    final pathDestinoConfig = await DatabaseHelper.getSetting('nas_path') ?? '';
    if (nasHost.isEmpty ||
        user.isEmpty ||
        password.isEmpty ||
        pathDestinoConfig.isEmpty) {
      mostrarMensaje(
        context,
        'Configurá los datos del NAS en la pantalla de configuración.',
      );
      return;
    }
    // --- DEBUG: Tamaño de fileBytes antes de escribir archivo ---
    print('[NAS DEBUG] fileBytes: \\${fileBytes.length} bytes');
    final file = File('${tempDir.path}/$fileName');
    // --- DEBUG: Antes de escribir archivo ---
    print('[NAS DEBUG] Archivo a crear: \\${file.path}');
    await file.writeAsBytes(fileBytes);
    // --- DEBUG: Después de escribir archivo ---
    print('[NAS DEBUG] Archivo local generado:');
    print('Ruta: \\${file.path}');
    print('Existe: \\${await file.exists()}');
    print('Tamaño: \\${await file.length()} bytes');
    print('Nombre para la API: \\${fileName}');
    print('Path destino para la API (validación): $pathDestinoConfig');

    final nasHelper = SynologyNasHelper(
      nasHost: nasHost,
      user: user,
      password: password,
    );
    final sid = await nasHelper.login();
    if (sid == null) {
      mostrarMensaje(context, 'Error de autenticación con el NAS.');
      return;
    }
    // Intentar subir a diferentes paths
    final pathsAProbar = ['/ganadores', '/IPV', '/', 'IPV'];
    bool ok = false;
    for (final path in pathsAProbar) {
      print('[NAS DEBUG] Intentando subir a $path ...');
      ok = await nasHelper.uploadFile(
        sid: sid,
        pathDestino: path,
        file: file,
        fileName: fileName,
      );
      if (ok) {
        print('[NAS DEBUG] Subida exitosa a $path');
        break;
      } else {
        print('[NAS DEBUG] Falló subida a $path');
      }
    }
    await nasHelper.logout(sid);
    if (ok) {
      mostrarMensaje(context, '¡Archivo subido correctamente al NAS!');
    } else {
      mostrarMensaje(
        context,
        'Falló la subida al NAS en todos los paths probados.',
      );
    }
  }

  /// Sube el archivo Excel generado al servidor FTP usando FtpHelper
  Future<void> subirExcelPorFtp(BuildContext context) async {
    if (barrioSeleccionado.value.isEmpty || grupoSeleccionado.value.isEmpty) {
      mostrarMensaje(context, 'Seleccioná un barrio y grupo para exportar.');
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
      mostrarMensaje(
        context,
        'No hay ganadores registrados para este barrio y grupo.',
      );
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
    final viviendas =
        p['viviendas'] is int
            ? p['viviendas']
            : int.tryParse(p['viviendas']?.toString() ?? '0') ?? 0;
    final familias =
        p['familias'] is int
            ? p['familias']
            : int.tryParse(p['familias']?.toString() ?? '0') ?? 0;

    // Crear el Excel (igual que en exportarExcel)
    final excelFile = excel.Excel.createExcel();
    String defaultSheet = excelFile.getDefaultSheet() ?? '';
    if (defaultSheet.isNotEmpty && defaultSheet != 'Ganadores') {
      excelFile.rename(defaultSheet, 'Ganadores');
    }
    for (final sheetName in List<String>.from(excelFile.sheets.keys)) {
      if (sheetName != 'Ganadores') {
        excelFile.delete(sheetName);
      }
    }
    final sheet = excelFile['Ganadores'];
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue(
        'Padrones definitivos - SORTEO PROV. DE VIVIENDAS–SAN JUAN 2025',
      ),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B2"),
      excel.CellIndex.indexByString("F2"),
    );
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue('Grupo: $grupo'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B4"),
      excel.CellIndex.indexByString("F4"),
    );
    sheet.appendRow([
      null,
      excel.TextCellValue('$viviendas Viviendas, $familias Familias'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B5"),
      excel.CellIndex.indexByString("F5"),
    );
    sheet.appendRow([
      null,
      excel.TextCellValue('Barrio: $barrio'),
      null,
      null,
      null,
      null,
    ]);
    sheet.merge(
      excel.CellIndex.indexByString("B6"),
      excel.CellIndex.indexByString("F6"),
    );
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([null, null, null, null, null, null]);
    sheet.appendRow([
      null,
      excel.TextCellValue('Posición'),
      excel.TextCellValue('Nro Orden'),
      excel.TextCellValue('Documento'),
      excel.TextCellValue('Apellido Nombre'),
    ]);
    for (var col = 1; col <= 4; col++) {
      final headerCell = sheet.cell(
        excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 9),
      );
      headerCell.cellStyle = excel.CellStyle(
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
      );
    }
    int rowIndex = 9;
    for (var ganador in ganadores) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [ganador['participanteId']],
      );
      if (participante.isNotEmpty) {
        final p = participante.first;
        final pos = ganador['position'];
        final order = p['order_number'];
        final doc = p['document']?.toString().trim() ?? '';
        final nombre = p['full_name']?.toString().trim() ?? '';
        if (pos != null &&
            pos != 0 &&
            order != null &&
            order != 0 &&
            doc.isNotEmpty &&
            nombre.isNotEmpty) {
          final fila = [
            null,
            excel.IntCellValue(pos as int),
            excel.IntCellValue(order as int),
            excel.TextCellValue(doc),
            excel.TextCellValue(nombre),
          ];
          final tieneDatos = fila
              .skip(1)
              .any(
                (cell) =>
                    (cell is excel.IntCellValue &&
                        cell.value != null &&
                        cell.value != 0) ||
                    (cell is excel.TextCellValue &&
                        (cell.value?.toString().trim().isNotEmpty ?? false)),
              );
          if (tieneDatos) {
            for (var col = 0; col < fila.length; col++) {
              sheet.updateCell(
                excel.CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: rowIndex,
                ),
                fila[col],
              );
            }
            rowIndex++;
          }
        }
      }
    }
    if (sheet.rows.length > 9 &&
        (sheet.rows[9].every((cell) => cell == null))) {
      sheet.removeRow(9);
    }
    for (var col = 1; col <= 4; col++) {
      sheet.setColumnWidth(col, col == 4 ? 30.0 : 15.0);
    }
    String cleanFileName(String input) {
      return input.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    }

    final safeBarrio = cleanFileName(barrio);
    final safeGrupo = cleanFileName(grupo);
    final fileName =
        'Barrio $safeBarrio - Grupo $safeGrupo - Definitivo para importar Ganadores.xlsx';
    final tempDir = Directory.systemTemp;
    final fileBytes = excelFile.encode();
    if (fileBytes == null) {
      mostrarMensaje(context, 'Error al generar archivo Excel.');
      return;
    }
    final file = File('${tempDir.path}/$fileName');
    print('[FTP DEBUG] fileBytes: ${fileBytes.length} bytes');
    print('[FTP DEBUG] Archivo a crear: ${file.path}');
    await file.writeAsBytes(fileBytes);
    print('[FTP DEBUG] Archivo local generado:');
    print('Ruta: ${file.path}');
    print('Existe: ${await file.exists()}');
    print('Tamaño: ${await file.length()} bytes');
    print('Nombre para la API: $fileName');

    // Leer configuración FTP
    final host = await DatabaseHelper.getSetting('ftp_host') ?? '';
    final user = await DatabaseHelper.getSetting('ftp_user') ?? '';
    final password = await DatabaseHelper.getSetting('ftp_password') ?? '';
    final portStr = await DatabaseHelper.getSetting('ftp_port') ?? '21';
    final remoteDir = await DatabaseHelper.getSetting('ftp_dir') ?? '/';
    final useSftp =
        (await DatabaseHelper.getSetting('ftp_sftp') ?? 'false') == 'true';
    final port = int.tryParse(portStr) ?? 21;
    if (host.isEmpty || user.isEmpty || password.isEmpty || remoteDir.isEmpty) {
      mostrarMensaje(
        context,
        'Configurá los datos del FTP en la pantalla de configuración.',
      );
      return;
    }
    final ftpHelper = FtpHelper(
      host: host,
      user: user,
      password: password,
      port: port,
      useSftp: useSftp,
    );
    final ok = await ftpHelper.subirArchivo(
      file: file,
      remoteDir: remoteDir,
      remoteFileName: fileName,
    );
    if (ok) {
      mostrarMensaje(context, '¡Archivo subido correctamente por FTP!');
    } else {
      mostrarMensaje(context, 'Falló la subida por FTP.');
    }
  }
}
