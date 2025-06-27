import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/import_padrones_screen/controllers/import_padrones_controller.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';

class ImportPadronesScreen extends StatelessWidget {
  const ImportPadronesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImportPadronesController>();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Importar archivo Excel"),
                onPressed: () {
                  controller.importarExcel(context);
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Obx(() => Text(
                  controller.mensaje.value,
                  textAlign: TextAlign.center,
                )),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Obx(() => InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Barrios cargados',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.barrioSeleccionado.value,
                      isExpanded: true,
                      items: controller.barrios
                          .map((barrio) => DropdownMenuItem(
                                value: barrio,
                                child: Text(barrio, style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                              ))
                          .toList(),
                      onChanged: controller.onBarrioChanged,
                    ),
                  ),
                )),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Obx(() => InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Grupos cargados',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.grupoSeleccionado.value,
                      isExpanded: true,
                      items: controller.grupos
                          .map((grupo) => DropdownMenuItem(
                                value: grupo,
                                child: Text(grupo, style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                              ))
                          .toList(),
                      onChanged: controller.onGrupoChanged,
                    ),
                  ),
                )),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() {
              if (controller.barrioSeleccionado.value == 'Seleccionar' ||
                  controller.grupoSeleccionado.value == 'Seleccionar') {
                return Center(
                  child: Text('Selecciona un barrio y grupo para ver los participantes.', style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                );
              } else if (controller.participantesFiltrados.isEmpty) {
                return Center(
                  child: Text('No hay participantes para este barrio y grupo.', style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                );
              } else {
                return Card(
                  elevation: 2,
                  child: ListView.builder(
                    itemCount: controller.participantesFiltrados.length,
                    itemBuilder: (context, index) {
                      final p = controller.participantesFiltrados[index];
                      return ListTile(
                        title: Text(p['full_name'] ?? '', style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
                        subtitle: Text(
                          'Número de Sorteo \\ ${p['order_number']} | Documento: \\${p['document']} | Grupo: \\${p['group']} | Barrio: \\${p['neighborhood']} | Viviendas: \\${p['viviendas'] ?? '-'} | Familias: \\${p['familias'] ?? '-'}',
                          style: TextStyle(fontSize: ResponsiveConfig.smallSize),
                        ),
                      );
                    },
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}
