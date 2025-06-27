import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';
import 'package:flutter/services.dart';

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
    final result = await db.rawQuery('SELECT DISTINCT "group" FROM participantes');
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
    List<Map<String, dynamic>> resultado;
    if (barrio != null && barrio != 'Seleccionar' && grupo != null && grupo != 'Seleccionar') {
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
      resultado = await db.query(
        'ganadores',
        orderBy: 'fecha DESC',
        limit: 10,
      );
    }
    final List<Map<String, dynamic>> lista = [];
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
        });
      }
    }
    ganadoresRecientes.value = lista;
  }

  Future<void> cargarInfoGrupo() async {
    if (barrioSeleccionado.value == 'Seleccionar' || grupoSeleccionado.value == 'Seleccionar') {
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
      ultimaPos = posResult.first['maxPos'] is int
        ? posResult.first['maxPos'] as int
        : int.tryParse(posResult.first['maxPos']?.toString() ?? '0') ?? 0;
    }
    viviendasGrupo.value = viviendas;
    familiasGrupo.value = familias;
    ultimaPosicion.value = ultimaPos;
  }

  void onBarrioChanged(String? val) async {
    barrioSeleccionado.value = val ?? 'Seleccionar';
    participante.value = null;
    mensaje.value = '';
    numeroController.clear();
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
    if (barrioSeleccionado.value == 'Seleccionar' || grupoSeleccionado.value == 'Seleccionar') {
      mensaje.value = "Seleccioná un barrio y grupo primero.";
      return;
    }
    final numero = int.tryParse(numeroController.text);
    if (numero == null) {
      mensaje.value = "Número inválido.";
      mostrarAlerta(context, "Número inválido", "Por favor, ingresa un número de orden válido.");
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
        mostrarAlerta(context, "Ya registrado", "Este participante ya ha sido registrado como ganador. Posición Número $pos");
        participante.value = null;
        mensaje.value = '';
        return;
      }
      mostrarAlertaParticipante(context, part);
      participante.value = part;
      mensaje.value = '';
    } else {
      participante.value = null;
      mensaje.value = "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.";
      mostrarAlerta(context, "No encontrado", "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.");
    }
  }

  void mostrarAlerta(BuildContext context, String titulo, String mensajeAlerta) {
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return RawKeyboardListener(
            focusNode: focusNode,
            autofocus: true,
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                Navigator.pop(context);
              }
            },
            child: AlertDialog(
              title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveConfig.subtitleSize)),
              content: Text(mensajeAlerta),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void mostrarAlertaParticipante(BuildContext context, Map<String, dynamic> part) {
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return RawKeyboardListener(
            focusNode: focusNode,
            autofocus: true,
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                Navigator.pop(context);
                registrarGanador(context);
              }
            },
            child: AlertDialog(
              title: Text(
                part['full_name'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveConfig.titleSize),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("DNI: \\${part['document']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                  Text("Barrio: \\${part['neighborhood']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                  Text("Grupo: \\${part['group']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                  Text("Nro de Orden: \\${part['order_number']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    registrarGanador(context);
                  },
                  child: Text("Aceptar y Registrar", style: TextStyle(fontSize: ResponsiveConfig.bodySize, color: Colors.green, fontWeight: FontWeight.bold)),
                )
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
    final yaGanador = await db.query(
      'ganadores',
      where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
      whereArgs: [participante.value!['order_number'], participante.value!['neighborhood'], participante.value!['group']],
    );
    if (yaGanador.isNotEmpty) {
      mensaje.value = 'Este participante ya fue registrado como ganador.';
      return;
    }
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [participante.value!['neighborhood'], participante.value!['group']]
    );
    final countGanadores = countResult.first['count'] as int? ?? 0;
    final nuevaPosicion = countGanadores + 1;
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
    mensaje.value = 'Ganador registrado correctamente.';
    numeroController.clear();
    participante.value = null;
    await cargarGanadoresRecientes();
    await cargarInfoGrupo();
  }
}
