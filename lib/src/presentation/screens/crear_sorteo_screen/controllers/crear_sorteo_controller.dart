import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:sorteo_ipv_system/src/data/helper/db/database_helper.dart';
import 'dart:io';
import 'package:flutter/material.dart'; // Added for Get.snackbar

class CrearSorteoController extends GetxController {
  var participantes = <Map<String, dynamic>>[].obs;
  var ganadores = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var mensaje = ''.obs;
  var idSorteoActual = 0.obs;
  var nombreSorteoActual = ''.obs;

  Future<void> importarExcel() async {
    isLoading.value = true;
    mensaje.value = '';
    try {
      print('Iniciando importación de Excel...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      print('Resultado del file picker: ${result?.files.single.path}');
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final bytes = await File(path).readAsBytes();
        print('Bytes leídos: ${bytes.length}');
        final excelFile = excel.Excel.decodeBytes(bytes);
        print('Archivo Excel decodificado. Hojas: ${excelFile.tables.keys}');
        final sheet = excelFile.tables.values.first;
        if (sheet == null) {
          print('No se encontró hoja en el archivo.');
          mensaje.value = 'No se encontró hoja en el archivo.';
          isLoading.value = false;
          return;
        }
        print('Filas en la hoja: ${sheet.maxRows}');
        List<Map<String, dynamic>> nuevos = [];
        int duplicados = 0;
        // Obtener todos los DNIs del Excel
        List<String> dnisExcel = [];
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          if (row.isEmpty || row[3] == null) continue;
          dnisExcel.add(row[3]?.value?.toString() ?? '');
        }
        // Verificar si algún DNI ya fue importado en otro sorteo
        final mensajePadron = await DatabaseHelper.existePadronEnOtroSorteo(
          dnisExcel,
          idSorteoActual.value,
        );
        if (mensajePadron != null) {
          Get.snackbar(
            'Padrón ya importado',
            mensajePadron,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
          );
          isLoading.value = false;
          // Mantener la lista actual de participantes importados
          final actuales = await DatabaseHelper.database.then(
            (db) => db.query(
              'ganadores_por_sortear',
              where: 'id_sorteo = ?',
              whereArgs: [idSorteoActual.value],
            ),
          );
          participantes.assignAll(actuales);
          return;
        }
        // Importar registros
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          print('Fila $i: ${row.map((c) => c?.value).toList()}');
          if (row.isEmpty || row[3] == null || row[4] == null)
            continue; // DNI y Apellido
          final data = {
            'nro_para_sorteo': row[0]?.value?.toString() ?? '',
            'orden_sorteado': row[1]?.value?.toString() ?? '',
            'nro_inscripcion': row[2]?.value?.toString() ?? '',
            'dni': row[3]?.value?.toString() ?? '',
            'apellido': row[4]?.value?.toString() ?? '',
            'nombre': row[5]?.value?.toString() ?? '',
            'sexo': row[6]?.value?.toString() ?? '',
            'f_nac': row[7]?.value?.toString() ?? '',
            'ingreso_mensual': row[8]?.value?.toString() ?? '',
            'estudios': row[9]?.value?.toString() ?? '',
            'f_fall': row[10]?.value?.toString() ?? '',
            'f_baja': row[11]?.value?.toString() ?? '',
            'departamento': row[12]?.value?.toString() ?? '',
            'localidad': row[13]?.value?.toString() ?? '',
            'barrio': row[14]?.value?.toString() ?? '',
            'domicilio': row[15]?.value?.toString() ?? '',
            'tel': row[16]?.value?.toString() ?? '',
            'cant_ocupantes': row[17]?.value?.toString() ?? '',
            'descripcion1': row[18]?.value?.toString() ?? '',
            'descripcion2': row[19]?.value?.toString() ?? '',
            'grupreferencial': row[20]?.value?.toString() ?? '',
            'preferencial_ficha': row[21]?.value?.toString() ?? '',
            'ficha': row[22]?.value?.toString() ?? '',
            'f_alta': row[23]?.value?.toString() ?? '',
            'fmodif': row[24]?.value?.toString() ?? '',
            'f_baja2': row[25]?.value?.toString() ?? '',
            'expediente': row[26]?.value?.toString() ?? '',
            'reemp': row[27]?.value?.toString() ?? '',
            'estado_txt': row[28]?.value?.toString() ?? '',
            'circuitoipv_txt': row[29]?.value?.toString() ?? '',
            'circuitoipv_nota': row[30]?.value?.toString() ?? '',
          };
          print('Datos a insertar: $data');
          // Validar duplicado por DNI e idSorteoActual
          final existe = await DatabaseHelper.existeGanadorPorSortear(
            dni: data['dni'] ?? '',
            idSorteo: idSorteoActual.value,
          );
          if (existe) {
            duplicados++;
            // Mostrar alerta solo la primera vez
            if (duplicados == 1) {
              Get.snackbar(
                'Duplicado',
                'El ganador ya ha sido cargado',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange.shade100,
              );
            }
            continue;
          }
          // Convertir todos los valores a String antes de insertar
          final dataString = Map<String, dynamic>.from(
            data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
          );
          await DatabaseHelper.insertarGanadorPorSortearConSorteo(
            dataString,
            idSorteoActual.value,
          );
          nuevos.add(dataString);
        }
        print('Total participantes importados: ${nuevos.length}');
        // Si no se importó ningún nuevo registro, mantener la lista actual
        if (nuevos.isEmpty) {
          final actuales = await DatabaseHelper.database.then(
            (db) => db.query(
              'ganadores_por_sortear',
              where: 'id_sorteo = ?',
              whereArgs: [idSorteoActual.value],
            ),
          );
          participantes.assignAll(actuales);
        } else {
          participantes.assignAll(nuevos);
        }
        mensaje.value =
            'Importación exitosa: ${nuevos.length} participantes.' +
            (duplicados > 0 ? ' ($duplicados duplicados omitidos)' : '');
      } else {
        print('No se seleccionó archivo.');
        mensaje.value = 'No se seleccionó archivo.';
      }
    } catch (e, st) {
      print('Error al importar: ${e.toString()}');
      print(st);
      mensaje.value = 'Error al importar: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Cargar participantes y nombre del sorteo seleccionado
  Future<void> cargarParticipantesPorSorteo(int idSorteo) async {
    final db = await DatabaseHelper.database;
    final lista = await db.query(
      'ganadores_por_sortear',
      where: 'id_sorteo = ?',
      whereArgs: [idSorteo],
    );
    participantes.assignAll(lista);
    // Obtener nombre del sorteo
    final sorteos = await db.query(
      'sorteos_creados',
      where: 'id_sorteo = ?',
      whereArgs: [idSorteo],
      limit: 1,
    );
    if (sorteos.isNotEmpty) {
      nombreSorteoActual.value =
          sorteos.first['nombre_sorteo']?.toString() ?? '';
    } else {
      nombreSorteoActual.value = '';
    }
  }

  void sortearGanador(int index) {
    ganadores.add(participantes[index]);
    participantes.removeAt(index);
    // Aquí podrías guardar en la tabla ganadores_posicionados si lo deseas
  }

  void limpiarListas() {
    participantes.clear();
    ganadores.clear();
  }

  // Obtener lista de sorteos creados
  Future<List<Map<String, dynamic>>> obtenerSorteosCreados() async {
    return await DatabaseHelper.obtenerSorteosCreados();
  }

  // Eliminar sorteo y todos los datos asociados
  Future<void> eliminarSorteoCompleto(int idSorteo) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      'ganadores_por_sortear',
      where: 'id_sorteo = ?',
      whereArgs: [idSorteo],
    );
    await db.delete(
      'ganadores_posicionados',
      where: 'id_sorteo = ?',
      whereArgs: [idSorteo],
    );
    await db.delete(
      'sorteos_creados',
      where: 'id_sorteo = ?',
      whereArgs: [idSorteo],
    );
    // Si hay otras tablas asociadas, agregar aquí
  }
}
