import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/export_ganadores_screen/controllers/export_ganadores_controller.dart';
///Importación de archivos
import 'package:sorteo_ipv_system/src/presentation/screens/import_padrones_screen/controllers/import_padrones_controller.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/list_ganadores_screen/controllers/list_ganadores_controller.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/search_participante_screen/controllers/search_participante_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies(){
    Get.put(ImportPadronesController());
    Get.put(SearchParticipanteController());
    Get.put(ListGanadoresController());
    Get.put(ExportGanadoresController());
  }
}
