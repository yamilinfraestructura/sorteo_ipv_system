import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/db/database_helper.dart';
import 'package:sorteo_ipv_system/src/data/helper/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SearchParticipanteController extends GetxController {
  var barrios = <String>['Seleccionar'].obs;
  var grupos = <String>['Seleccionar'].obs;
  var barrioSeleccionado = 'Seleccionar'.obs;
  var grupoSeleccionado = 'Seleccionar'.obs;
  var viviendasGrupo = 0.obs;
  var familiasGrupo = 0.obs;
  var ultimaPosicion = 0.obs;
  var mensaje = ''.obs;
  var participante = Rxn<Map<String, dynamic>>();
  var ganadoresRecientes = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  final TextEditingController numeroController = TextEditingController();
  var ultimoGanadorId = Rxn<int>();
  var sorteoCerrado = false.obs;
  var gruposCerrados = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    isLoading.value = true;
    try {
      await Future.wait([
        cargarBarrios(),
        cargarGrupos(),
        cargarGanadoresRecientes(),
        cargarInfoGrupo(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cargarBarrios() async {
    final barriosDb = await DatabaseHelper.obtenerBarrios();
    barrios.value = ['Seleccionar', ...barriosDb];
    if (barrios.length > 1 && !barrios.contains(barrioSeleccionado.value)) {
      barrioSeleccionado.value = 'Seleccionar';
    }
  }

  Future<void> cargarGrupos() async {
    final db = await DatabaseHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT "group" FROM participantes',
    );
    final gruposDb = result.map((e) => e['group'] as String).toList();
    grupos.value = ['Seleccionar', ...gruposDb];
    // Calcular estado de cierre para cada grupo del barrio seleccionado
    await actualizarGruposCerrados();
    if (grupos.length > 1 && !grupos.contains(grupoSeleccionado.value)) {
      grupoSeleccionado.value = 'Seleccionar';
    }
  }

  Future<void> actualizarGruposCerrados() async {
    gruposCerrados.clear();
    final db = await DatabaseHelper.database;
    final barrio = barrioSeleccionado.value;
    if (barrio == null || barrio == 'Seleccionar') return;
    final result = await db.rawQuery(
      'SELECT DISTINCT "group" FROM participantes WHERE neighborhood = ?',
      [barrio],
    );
    for (var row in result) {
      final grupo = row['group'] as String;
      // Contar ganadores
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
        [barrio, grupo],
      );
      final totalGanadores =
          countResult.first['count'] is int
              ? countResult.first['count'] as int
              : int.tryParse(countResult.first['count']?.toString() ?? '0') ??
                  0;
      // Obtener viviendas
      final infoResult = await db.query(
        'participantes',
        columns: ['viviendas'],
        where: 'neighborhood = ? AND "group" = ?',
        whereArgs: [barrio, grupo],
        limit: 1,
      );
      int viviendas = 0;
      if (infoResult.isNotEmpty) {
        final v = infoResult.first['viviendas'];
        viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      }
      gruposCerrados[grupo] = viviendas > 0 && totalGanadores == viviendas;
    }
    gruposCerrados.refresh();
  }

  Future<void> cargarGanadoresRecientes() async {
    final db = await DatabaseHelper.database;
    String? barrio = barrioSeleccionado.value;
    String? grupo = grupoSeleccionado.value;
    // Ganadores activos
    List<Map<String, dynamic>> resultado;
    if (barrio != null &&
        barrio != 'Seleccionar' &&
        grupo != null &&
        grupo != 'Seleccionar') {
      resultado = await db.query(
        'ganadores',
        where: 'neighborhood = ? AND "group" = ?',
        whereArgs: [barrio, grupo],
        orderBy: 'fecha DESC',
        limit: 10,
      );
    } else if (barrio != null && barrio != 'Seleccionar') {
      resultado = await db.query(
        'ganadores',
        where: 'neighborhood = ?',
        whereArgs: [barrio],
        orderBy: 'fecha DESC',
        limit: 10,
      );
    } else if (grupo != null && grupo != 'Seleccionar') {
      resultado = await db.query(
        'ganadores',
        where: '"group" = ?',
        whereArgs: [grupo],
        orderBy: 'fecha DESC',
        limit: 10,
      );
    } else {
      resultado = await db.query('ganadores', orderBy: 'fecha DESC', limit: 10);
    }
    List<Map<String, dynamic>> activos = [];
    for (var item in resultado) {
      final participanteDb = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [item['participanteId']],
      );
      if (participanteDb.isNotEmpty) {
        activos.add({
          ...item,
          'full_name': participanteDb.first['full_name'],
          'document': participanteDb.first['document'],
          'eliminado': false,
        });
      }
    }
    // Ganadores eliminados
    List<Map<String, dynamic>> eliminados;
    if (barrio != null &&
        barrio != 'Seleccionar' &&
        grupo != null &&
        grupo != 'Seleccionar') {
      eliminados = await db.rawQuery(
        '''
        SELECT e.*, u.user_name as eliminado_por FROM eliminados e
        LEFT JOIN usuarios u ON e.id_user = u.id_user
        WHERE e.neighborhood = ? AND e."group" = ?
        ORDER BY fecha_baja DESC
        LIMIT 10
      ''',
        [barrio, grupo],
      );
    } else if (barrio != null && barrio != 'Seleccionar') {
      eliminados = await db.rawQuery(
        '''
        SELECT e.*, u.user_name as eliminado_por FROM eliminados e
        LEFT JOIN usuarios u ON e.id_user = u.id_user
        WHERE e.neighborhood = ?
        ORDER BY fecha_baja DESC
        LIMIT 10
      ''',
        [barrio],
      );
    } else if (grupo != null && grupo != 'Seleccionar') {
      eliminados = await db.rawQuery(
        '''
        SELECT e.*, u.user_name as eliminado_por FROM eliminados e
        LEFT JOIN usuarios u ON e.id_user = u.id_user
        WHERE e."group" = ?
        ORDER BY fecha_baja DESC
        LIMIT 10
      ''',
        [grupo],
      );
    } else {
      eliminados = await db.rawQuery('''
        SELECT e.*, u.user_name as eliminado_por FROM eliminados e
        LEFT JOIN usuarios u ON e.id_user = u.id_user
        ORDER BY fecha_baja DESC
        LIMIT 10
      ''');
    }
    List<Map<String, dynamic>> eliminadosList = [];
    for (var e in eliminados) {
      eliminadosList.add({...e, 'eliminado': true});
    }
    // Ordenar activos por fecha (descendente)
    activos.sort((a, b) {
      final fa = a['fecha'] ?? '';
      final fb = b['fecha'] ?? '';
      return (fb as String).compareTo(fa as String);
    });
    // Ordenar eliminados por fecha_baja (descendente)
    eliminadosList.sort((a, b) {
      final fa = a['fecha_baja'] ?? '';
      final fb = b['fecha_baja'] ?? '';
      return (fb as String).compareTo(fa as String);
    });
    // Unir: activos primero, eliminados al final
    ganadoresRecientes.value = [...activos, ...eliminadosList];

    // Lógica para saber si el sorteo está cerrado (usando viviendas)
    if (barrio != null &&
        barrio != 'Seleccionar' &&
        grupo != null &&
        grupo != 'Seleccionar') {
      // Contar todos los ganadores
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
        [barrio, grupo],
      );
      final totalGanadores =
          countResult.first['count'] is int
              ? countResult.first['count'] as int
              : int.tryParse(countResult.first['count']?.toString() ?? '0') ??
                  0;
      // Obtener cantidad de viviendas
      final infoResult = await db.query(
        'participantes',
        columns: ['viviendas'],
        where: 'neighborhood = ? AND "group" = ?',
        whereArgs: [barrio, grupo],
        limit: 1,
      );
      int viviendas = 0;
      if (infoResult.isNotEmpty) {
        final v = infoResult.first['viviendas'];
        viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      }
      sorteoCerrado.value = viviendas > 0 && totalGanadores == viviendas;
    } else {
      sorteoCerrado.value = false;
    }
  }

  Future<void> cargarInfoGrupo() async {
    if (barrioSeleccionado.value == 'Seleccionar' ||
        grupoSeleccionado.value == 'Seleccionar') {
      viviendasGrupo.value = 0;
      familiasGrupo.value = 0;
      ultimaPosicion.value = 0;
      return;
    }
    final db = await DatabaseHelper.database;
    final infoResult = await db.query(
      'participantes',
      columns: ['viviendas', 'familias'],
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [barrioSeleccionado.value, grupoSeleccionado.value],
      limit: 1,
    );
    int viviendas = 0;
    int familias = 0;
    if (infoResult.isNotEmpty) {
      final v = infoResult.first['viviendas'];
      final f = infoResult.first['familias'];
      viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      familias = f is int ? f : int.tryParse(f?.toString() ?? '0') ?? 0;
    }
    final posResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [barrioSeleccionado.value, grupoSeleccionado.value],
    );
    int ultimaPos = 0;
    if (posResult.isNotEmpty) {
      ultimaPos =
          posResult.first['count'] is int
              ? posResult.first['count'] as int
              : int.tryParse(posResult.first['count']?.toString() ?? '0') ?? 0;
    }
    viviendasGrupo.value = viviendas;
    familiasGrupo.value = familias;
    ultimaPosicion.value = ultimaPos;
  }

  void onBarrioChanged(String? val) async {
    barrioSeleccionado.value = val ?? 'Seleccionar';
    grupoSeleccionado.value = 'Seleccionar';
    participante.value = null;
    mensaje.value = '';
    numeroController.clear();
    if (barrioSeleccionado.value != 'Seleccionar') {
      final db = await DatabaseHelper.database;
      final result = await db.rawQuery(
        'SELECT DISTINCT "group" FROM participantes WHERE neighborhood = ?',
        [barrioSeleccionado.value],
      );
      final gruposDb = result.map((e) => e['group'] as String).toList();
      grupos.value = ['Seleccionar', ...gruposDb];
      await actualizarGruposCerrados();
    } else {
      grupos.value = ['Seleccionar'];
      gruposCerrados.clear();
    }
    await cargarGanadoresRecientes();
    await cargarInfoGrupo();
  }

  void onGrupoChanged(String? val) async {
    grupoSeleccionado.value = val ?? 'Seleccionar';
    participante.value = null;
    mensaje.value = '';
    numeroController.clear();
    await cargarGanadoresRecientes();
    await cargarInfoGrupo();
  }

  Future<void> buscarParticipante(
    BuildContext context, {
    VoidCallback? onDialogClosed,
  }) async {
    if (barrioSeleccionado.value == 'Seleccionar' ||
        grupoSeleccionado.value == 'Seleccionar') {
      mensaje.value = "Seleccioná un barrio y grupo primero.";
      return;
    }
    final numero = int.tryParse(numeroController.text);
    if (numero == null || numero == 0) {
      mensaje.value =
          "Número inválido. Debe ingresar un número de orden válido mayor a cero.";
      mostrarAlerta(
        context,
        "Número inválido",
        "Por favor, ingresa un número de orden válido (mayor a cero).",
        onDialogClosed: onDialogClosed,
      );
      return;
    }
    final db = await DatabaseHelper.database;
    final resultados = await db.query(
      'participantes',
      where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
      whereArgs: [numero, barrioSeleccionado.value, grupoSeleccionado.value],
    );
    if (resultados.isNotEmpty) {
      final part = resultados.first;
      final yaGanador = await db.query(
        'ganadores',
        where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
        whereArgs: [part['order_number'], part['neighborhood'], part['group']],
      );
      if (yaGanador.isNotEmpty) {
        final pos = yaGanador.first['position'] ?? '-';
        mostrarAlerta(
          context,
          "Ya registrado",
          "Fue registrado en la <b>Posición Número $pos</b>",
          onDialogClosed: onDialogClosed,
        );
        participante.value = null;
        mensaje.value = '';
        return;
      }
      mostrarAlertaParticipante(context, part);
      participante.value = part;
      mensaje.value = '';
    } else {
      participante.value = null;
      mensaje.value =
          "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.";
      mostrarAlerta(
        context,
        "Fuera de Padrón",
        "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.",
        onDialogClosed: onDialogClosed,
      );
    }
  }

  void mostrarAlerta(
    BuildContext context,
    String titulo,
    String mensajeAlerta, {
    VoidCallback? onDialogClosed,
  }) {
    if (!context.mounted) return;
    final focusNode = FocusNode();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: 'Cerrar alerta',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomRight,
          child: RawKeyboardListener(
            focusNode: focusNode,
            autofocus: true,
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                Navigator.pop(context);
                if (onDialogClosed != null) {
                  onDialogClosed();
                }
              }
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.47,
              height: MediaQuery.of(context).size.height * 0.28,
              margin: const EdgeInsets.all(10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveConfig.titleSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      mensajeAlerta.contains('<b>')
                          ? RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                              children: _parseBoldText(mensajeAlerta),
                            ),
                          )
                          : Text(
                            mensajeAlerta,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      const SizedBox(height: 5),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (onDialogClosed != null) {
                            onDialogClosed();
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Aceptar"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  void mostrarAlertaParticipante(
    BuildContext context,
    Map<String, dynamic> part,
  ) {
    final focusNode = FocusNode();
    bool intentToClose = false;
    void showConfirmExitDialog() {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        barrierLabel: 'Cerrar alerta',
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.45,
              height: MediaQuery.of(context).size.height * 0.28,
              margin: const EdgeInsets.all(24),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Salir sin registrar?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveConfig.titleSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '¿Está seguro que desea salir? Si sale, no se registrará el beneficiario.',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(); // Cierra el dialogo de confirmación
                              Navigator.of(
                                context,
                              ).pop(); // Cierra el alert principal
                            },
                            child: const Text(
                              'Salir sin registrar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar con clic fuera
      barrierColor: Colors.transparent,
      barrierLabel: 'Cerrar alerta',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomRight,
          child: StatefulBuilder(
            builder: (context, setState) {
              return RawKeyboardListener(
                focusNode: focusNode,
                autofocus: true,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    Navigator.pop(context);
                    registrarGanador(context);
                  } else if (event is RawKeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    showConfirmExitDialog();
                  }
                },
                child: WillPopScope(
                  onWillPop: () async {
                    showConfirmExitDialog();
                    return false;
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.47,
                    height: MediaQuery.of(context).size.height * 0.28,
                    margin: const EdgeInsets.all(24),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 12,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              part['full_name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveConfig.titleSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "DNI: \\${part['document']}",
                              style: TextStyle(
                                fontSize: ResponsiveConfig.bodySize,
                              ),
                            ),
                            Text(
                              "Nro de Sorteo: \\${formatearNumeroSorteo(part['order_number'])}",
                              style: TextStyle(
                                fontSize: ResponsiveConfig.bodySize,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(
                                  fontSize: ResponsiveConfig.bodySize,
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                registrarGanador(context);
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Aceptar"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Future<void> registrarGanador(BuildContext context) async {
    if (participante.value == null) return;
    final db = await DatabaseHelper.database;
    // Verificar cantidad de ganadores y viviendas
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [participante.value!['neighborhood'], participante.value!['group']],
    );
    final countGanadores =
        countResult.first['count'] is int
            ? countResult.first['count'] as int
            : int.tryParse(countResult.first['count']?.toString() ?? '0') ?? 0;
    // Obtener cantidad de viviendas
    final infoResult = await db.query(
      'participantes',
      columns: ['viviendas'],
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [
        participante.value!['neighborhood'],
        participante.value!['group'],
      ],
      limit: 1,
    );
    int viviendas = 0;
    if (infoResult.isNotEmpty) {
      final v = infoResult.first['viviendas'];
      viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    }
    // Si ya se llegó al límite de ganadores
    if (countGanadores >= viviendas && viviendas > 0) {
      mostrarAlerta(
        context,
        "Sorteo completo",
        "Se completó el sorteo del Barrio '${participante.value!['neighborhood']}' Grupo '${participante.value!['group']}' con $viviendas Viviendas.",
      );
      participante.value = null;
      mensaje.value = '';
      return;
    }
    // Verificar si el participante ya es ganador
    final yaGanador = await db.query(
      'ganadores',
      where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
      whereArgs: [
        participante.value!['order_number'],
        participante.value!['neighborhood'],
        participante.value!['group'],
      ],
    );
    if (yaGanador.isNotEmpty) {
      mensaje.value = 'Este participante ya fue registrado como ganador.';
      return;
    }
    // Obtener todas las posiciones ocupadas
    final posicionesResult = await db.query(
      'ganadores',
      columns: ['position'],
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [
        participante.value!['neighborhood'],
        participante.value!['group'],
      ],
      orderBy: 'position ASC',
    );
    // Buscar el menor hueco disponible
    int nuevaPosicion = 1;
    final posicionesOcupadas =
        posicionesResult.map((e) => e['position'] as int).toList()..sort();
    for (int i = 1; i <= posicionesOcupadas.length; i++) {
      if (!posicionesOcupadas.contains(i)) {
        nuevaPosicion = i;
        break;
      }
      // Si no hay huecos, asignar la siguiente
      if (i == posicionesOcupadas.length) {
        nuevaPosicion = i + 1;
      }
    }
    // Guardar en SQLite local
    await db.insert('ganadores', {
      'participanteId': participante.value!['id'],
      'fecha': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'neighborhood': participante.value!['neighborhood'],
      'group': participante.value!['group'],
      'position': nuevaPosicion,
      'order_number': participante.value!['order_number'],
      'document': participante.value!['document'],
      'full_name': participante.value!['full_name'],
    });

    // Guardar también en Firestore (sincronización híbrida)
    final fecha = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await FirestoreService.guardarGanador(
      barrio: participante.value!['neighborhood'],
      grupo: participante.value!['group'],
      participanteId: participante.value!['id'],
      orderNumber: participante.value!['order_number'],
      fullName: participante.value!['full_name'],
      document: participante.value!['document'],
      position: nuevaPosicion,
      fecha: fecha,
    );

    // Obtener el id del último ganador insertado
    final idResult = await db.rawQuery('SELECT last_insert_rowid() as id');
    if (idResult.isNotEmpty) {
      ultimoGanadorId.value = idResult.first['id'] as int?;
    } else {
      ultimoGanadorId.value = null;
    }
    mensaje.value = 'Ganador registrado correctamente.';
    numeroController.clear();
    participante.value = null;
    await cargarGanadoresRecientes();
    await cargarInfoGrupo();
    await actualizarGruposCerrados();
    // Mostrar alert de cierre si se completó el sorteo justo ahora
    if (nuevaPosicion == viviendas && viviendas > 0) {
      mostrarAlerta(
        context,
        "Sorteo completo",
        "Se completó el sorteo del Barrio '${barrioSeleccionado.value}' Grupo '${grupoSeleccionado.value}' con $viviendas Viviendas.",
      );
    }
  }

  Future<void> eliminarGanador(
    BuildContext context,
    Map<String, dynamic> ganador,
  ) async {
    final TextEditingController pinUsuarioController = TextEditingController();
    final TextEditingController pinEscribanoController =
        TextEditingController();
    bool eliminado = false;
    String pinEscribano = await DatabaseHelper.getPinEscribano() ?? '';
    final focusNode = FocusNode();
    String errorPinUsuario = '';
    String errorPinEscribano = '';
    final String errorPin = [
      errorPinUsuario,
      errorPinEscribano,
    ].where((e) => e.isNotEmpty).join(' | ');
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: 'Cerrar alerta',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomRight,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.47,
                height: MediaQuery.of(context).size.height * 0.28,
                margin: const EdgeInsets.all(24),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RawKeyboardListener(
                      focusNode: focusNode,
                      autofocus: true,
                      onKey: (RawKeyEvent event) async {
                        if (event is RawKeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.numpadEnter)) {
                          final loginCtrl = Get.find<LoginController>();
                          final user = loginCtrl.usuarioLogueado.value;
                          final pinUsuarioIngresado = pinUsuarioController.text;
                          final pinEscribanoIngresado =
                              pinEscribanoController.text;
                          final perfil = user?['perfil_user']?.toString() ?? '';
                          final pinHashGuardado =
                              user?['password']?.toString() ?? '';
                          final pinHashUsuarioIngresado =
                              sha256
                                  .convert(utf8.encode(pinUsuarioIngresado))
                                  .toString();
                          final pinUsuarioOk =
                              pinUsuarioIngresado.length == 6 &&
                              perfil.isNotEmpty &&
                              (perfil == 'Desarrollador' ||
                                  perfil == 'Administrador') &&
                              pinHashUsuarioIngresado == pinHashGuardado;
                          final pinEscribanoOk =
                              pinEscribanoIngresado == pinEscribano &&
                              pinEscribanoIngresado.length == 6;
                          if (pinUsuarioOk && pinEscribanoOk) {
                            eliminado = true;
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              errorPinUsuario =
                                  pinUsuarioOk
                                      ? ''
                                      : 'Pin de usuario incorrecto';
                              errorPinEscribano =
                                  pinEscribanoOk
                                      ? ''
                                      : 'Pin de escribano incorrecto';
                            });
                          }
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Eliminar ganador',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveConfig.titleSize * 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (errorPin.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 6),
                              child: SizedBox(
                                width: ResponsiveConfig.standarSize * 0.4,
                                child: Text(
                                  errorPin,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          // Quitar los subtítulos de los pines
                          SizedBox(
                            width: 220,
                            child: Pinput(
                              length: 6,
                              controller: pinUsuarioController,
                              obscureText: true,
                              autofocus: true,
                              defaultPinTheme: PinTheme(
                                width: 28,
                                height: 36,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              focusedPinTheme: PinTheme(
                                width: 28,
                                height: 36,
                                textStyle: const TextStyle(
                                  fontSize: 18,
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
                                width: 28,
                                height: 36,
                                textStyle: const TextStyle(
                                  fontSize: 18,
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
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 220,
                            child: Pinput(
                              length: 6,
                              controller: pinEscribanoController,
                              obscureText: true,
                              defaultPinTheme: PinTheme(
                                width: 28,
                                height: 36,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              focusedPinTheme: PinTheme(
                                width: 28,
                                height: 36,
                                textStyle: const TextStyle(
                                  fontSize: 18,
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
                                width: 28,
                                height: 36,
                                textStyle: const TextStyle(
                                  fontSize: 18,
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
                          if (errorPinUsuario.isNotEmpty)
                            SizedBox(
                              width: ResponsiveConfig.standarSize * 0.4,
                              child: Text(
                                errorPinUsuario,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (errorPinEscribano.isNotEmpty)
                            SizedBox(
                              width: ResponsiveConfig.standarSize * 0.4,
                              child: Text(
                                errorPinEscribano,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  final loginCtrl = Get.find<LoginController>();
                                  final user = loginCtrl.usuarioLogueado.value;
                                  final pinUsuarioIngresado =
                                      pinUsuarioController.text;
                                  final pinEscribanoIngresado =
                                      pinEscribanoController.text;
                                  final perfil =
                                      user?['perfil_user']?.toString() ?? '';
                                  final pinHashGuardado =
                                      user?['password']?.toString() ?? '';
                                  final pinHashUsuarioIngresado =
                                      sha256
                                          .convert(
                                            utf8.encode(pinUsuarioIngresado),
                                          )
                                          .toString();
                                  final pinUsuarioOk =
                                      pinUsuarioIngresado.length == 6 &&
                                      perfil.isNotEmpty &&
                                      (perfil == 'Desarrollador' ||
                                          perfil == 'Administrador') &&
                                      pinHashUsuarioIngresado ==
                                          pinHashGuardado;
                                  final pinEscribanoOk =
                                      pinEscribanoIngresado == pinEscribano &&
                                      pinEscribanoIngresado.length == 6;
                                  if (pinUsuarioOk && pinEscribanoOk) {
                                    eliminado = true;
                                    Navigator.pop(context);
                                  } else {
                                    setState(() {
                                      errorPinUsuario =
                                          pinUsuarioOk
                                              ? ''
                                              : 'Pin de usuario incorrecto';
                                      errorPinEscribano =
                                          pinEscribanoOk
                                              ? ''
                                              : 'Pin de escribano incorrecto';
                                    });
                                  }
                                },
                                child: const Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
    if (eliminado) {
      try {
        final loginCtrl = Get.find<LoginController>();
        final idUser = loginCtrl.usuarioLogueado.value?['id_user'] ?? 0;

        // Eliminar de SQLite local
        await DatabaseHelper.eliminarGanadorPorId(ganador['id'] as int, idUser);

        // Eliminar también de Firestore
        await FirestoreService.eliminarGanador(
          barrio: ganador['neighborhood'],
          grupo: ganador['group'],
          orderNumber: ganador['order_number'],
        );

        await cargarGanadoresRecientes();
        await cargarInfoGrupo();
        mensaje.value = 'Ganador eliminado correctamente.';
        Get.snackbar(
          'Éxito',
          'Ganador eliminado y registrado en historial.',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );
      } catch (e) {
        mensaje.value = 'Error al eliminar ganador.';
        Get.snackbar(
          'Error',
          'No se pudo eliminar el ganador.',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    }
  }

  void reenfocarCampoNumero() {
    numeroController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: numeroController.text.length,
    );
  }

  /// Formatea el número de sorteo con ceros a la izquierda basado en las familias empadronadas
  String formatearNumeroSorteo(dynamic orderNumber) {
    if (orderNumber == null) return '000';

    final numero = int.tryParse(orderNumber.toString()) ?? 0;
    final familias = familiasGrupo.value;

    // Calcular dígitos necesarios basado en el número de familias
    int digitos = 3; // Mínimo 3 dígitos
    if (familias > 0) {
      digitos = familias.toString().length;
      if (digitos < 3) digitos = 3;
    }

    return numero.toString().padLeft(digitos, '0');
  }
}

List<InlineSpan> _parseBoldText(String text) {
  final regex = RegExp(r'<b>(.*?)<\/b>');
  final spans = <InlineSpan>[];
  int start = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }
  return spans;
}
