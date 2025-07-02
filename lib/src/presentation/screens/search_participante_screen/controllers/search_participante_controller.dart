import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
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
    if (grupos.length > 1 && !grupos.contains(grupoSeleccionado.value)) {
      grupoSeleccionado.value = 'Seleccionar';
    }
  }

  Future<void> cargarGanadoresRecientes() async {
    final db = await DatabaseHelper.database;
    String? barrio = barrioSeleccionado.value;
    String? grupo = grupoSeleccionado.value;
    List<Map<String, dynamic>> lista = [];
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
    for (var item in resultado) {
      final participanteDb = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [item['participanteId']],
      );
      if (participanteDb.isNotEmpty) {
        lista.add({
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
    for (var e in eliminados) {
      lista.add({...e, 'eliminado': true});
    }
    // Ordenar por fecha (puedes ajustar el criterio si lo deseas)
    lista.sort((a, b) {
      final fa = a['eliminado'] ? a['fecha_baja'] ?? '' : a['fecha'] ?? '';
      final fb = b['eliminado'] ? b['fecha_baja'] ?? '' : b['fecha'] ?? '';
      return (fb as String).compareTo(fa as String);
    });
    ganadoresRecientes.value = lista;

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
      'SELECT MAX(position) as maxPos FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [barrioSeleccionado.value, grupoSeleccionado.value],
    );
    int ultimaPos = 0;
    if (posResult.isNotEmpty) {
      ultimaPos =
          posResult.first['maxPos'] is int
              ? posResult.first['maxPos'] as int
              : int.tryParse(posResult.first['maxPos']?.toString() ?? '0') ?? 0;
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
    } else {
      grupos.value = ['Seleccionar'];
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

  Future<void> buscarParticipante(BuildContext context) async {
    if (barrioSeleccionado.value == 'Seleccionar' ||
        grupoSeleccionado.value == 'Seleccionar') {
      mensaje.value = "Seleccioná un barrio y grupo primero.";
      return;
    }
    final numero = int.tryParse(numeroController.text);
    if (numero == null) {
      mensaje.value = "Número inválido.";
      mostrarAlerta(
        context,
        "Número inválido",
        "Por favor, ingresa un número de orden válido.",
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
          "Este participante ya ha sido registrado como ganador. Posición Número $pos",
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
        "No encontrado",
        "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.",
      );
    }
  }

  void mostrarAlerta(
    BuildContext context,
    String titulo,
    String mensajeAlerta,
  ) {
    if (!context.mounted) return;
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
                child:
                    titulo == "Sorteo completo"
                        ? AlertDialog(
                          backgroundColor: Colors.amber[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Column(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Colors.amber[800],
                                size: 60,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  color: Colors.amber[900],
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          content: Text(
                            mensajeAlerta,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
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
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Aceptar"),
                            ),
                          ],
                        )
                        : AlertDialog(
                          title: Text(
                            titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveConfig.subtitleSize,
                            ),
                          ),
                          content: Text(mensajeAlerta),
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

  void mostrarAlertaParticipante(
    BuildContext context,
    Map<String, dynamic> part,
  ) {
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
                    registrarGanador(context);
                  }
                },
                child: AlertDialog(
                  title: Text(
                    part['full_name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveConfig.titleSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "DNI: \\${part['document']}",
                        style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                      ),
                      Text(
                        "Barrio: \\${part['neighborhood']}",
                        style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                      ),
                      Text(
                        "Grupo: \\${part['group']}",
                        style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                      ),
                      Text(
                        "Nro de Orden: \\${part['order_number']}",
                        style: TextStyle(fontSize: ResponsiveConfig.bodySize),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        registrarGanador(context);
                      },
                      child: Text(
                        "Aceptar y Registrar",
                        style: TextStyle(
                          fontSize: ResponsiveConfig.bodySize,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
    final TextEditingController pinController = TextEditingController();
    bool eliminado = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final focusNode = FocusNode();
        String errorPin = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return RawKeyboardListener(
              focusNode: focusNode,
              autofocus: true,
              onKey: (RawKeyEvent event) async {
                if (event is RawKeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                  final loginCtrl = Get.find<LoginController>();
                  final user = loginCtrl.usuarioLogueado.value;
                  final pinIngresado = pinController.text;
                  final perfil = user?['perfil_user']?.toString() ?? '';
                  final pinHashGuardado = user?['password']?.toString() ?? '';
                  final pinHashIngresado =
                      sha256.convert(utf8.encode(pinIngresado)).toString();
                  if (pinIngresado.length == 6 &&
                      perfil.isNotEmpty &&
                      (perfil == 'Desarrollador' ||
                          perfil == 'Ministro' ||
                          perfil == 'Gobernador') &&
                      pinHashIngresado == pinHashGuardado) {
                    eliminado = true;
                    Navigator.pop(context);
                  } else {
                    setState(() => errorPin = 'Pin o perfil incorrecto');
                  }
                }
              },
              child: AlertDialog(
                title: const Text('Eliminar ganador'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('¿Estás seguro que deseas eliminar a este ganador?'),
                    const SizedBox(height: 12),
                    Text('Nombre: ' + (ganador['full_name'] ?? '')),
                    Text('DNI: ' + (ganador['document'] ?? '')),
                    const SizedBox(height: 16),
                    const Text('Ingresá el pin de 6 dígitos para confirmar:'),
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
                        // No eliminar al completar el pin, solo con botón o enter
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
                    onPressed: () async {
                      final loginCtrl = Get.find<LoginController>();
                      final user = loginCtrl.usuarioLogueado.value;
                      final pinIngresado = pinController.text;
                      final perfil = user?['perfil_user']?.toString() ?? '';
                      final pinHashGuardado =
                          user?['password']?.toString() ?? '';
                      final pinHashIngresado =
                          sha256.convert(utf8.encode(pinIngresado)).toString();
                      if (pinIngresado.length == 6 &&
                          perfil.isNotEmpty &&
                          (perfil == 'Desarrollador' ||
                              perfil == 'Ministro' ||
                              perfil == 'Gobernador') &&
                          pinHashIngresado == pinHashGuardado) {
                        eliminado = true;
                        Navigator.pop(context);
                      } else {
                        setState(() => errorPin = 'Pin o perfil incorrecto');
                      }
                    },
                    child: const Text(
                      'Eliminar',
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
    if (eliminado) {
      try {
        final loginCtrl = Get.find<LoginController>();
        final idUser = loginCtrl.usuarioLogueado.value?['id_user'] ?? 0;
        await DatabaseHelper.eliminarGanadorPorId(ganador['id'] as int, idUser);
        await cargarGanadoresRecientes();
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
}
