import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/export_ganadores_screen/components/export_ganadores_list_component.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/export_ganadores_screen/widgets/export_ganadores_form_widget.dart';
import 'controllers/export_ganadores_controller.dart';

class ExportGanadoresScreen extends StatelessWidget {
  const ExportGanadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExportGanadoresController>();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Obx(() => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Seleccioná un barrio',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.barrioSeleccionado.value.isEmpty ? null : controller.barrioSeleccionado.value,
                      isExpanded: true,
                      items: controller.barrios
                          .map((barrio) => DropdownMenuItem(
                                value: barrio,
                                child: Text(barrio),
                              ))
                          .toList(),
                      onChanged: controller.onBarrioChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Seleccioná un grupo',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.grupoSeleccionado.value.isEmpty ? null : controller.grupoSeleccionado.value,
                      isExpanded: true,
                      items: controller.grupos
                          .map((grupo) => DropdownMenuItem(
                                value: grupo,
                                child: Text(grupo),
                              ))
                          .toList(),
                      onChanged: controller.onGrupoChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text("Exportar ganadores a Excel"),
            onPressed: () => controller.exportarExcel(context),
          ),
          const SizedBox(height: 16),
          if (controller.mensaje.value.isNotEmpty)
            Text(
              controller.mensaje.value,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      )),
    );
  }
}
