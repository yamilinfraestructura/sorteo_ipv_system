import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'dart:io';

class CrearSorteoController extends GetxController {
  var participantes = <Map<String, dynamic>>[].obs;
  var ganadores = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var mensaje = ''.obs;

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
          nuevos.add(data);
          await DatabaseHelper.insertarGanadoresPorSortear(data);
        }
        print('Total participantes importados: ${nuevos.length}');
        participantes.assignAll(nuevos);
        mensaje.value = 'Importación exitosa: ${nuevos.length} participantes.';
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

  void sortearGanador(int index) {
    ganadores.add(participantes[index]);
    participantes.removeAt(index);
    // Aquí podrías guardar en la tabla ganadores_posicionados si lo deseas
  }

  void limpiarListas() {
    participantes.clear();
    ganadores.clear();
  }
}
