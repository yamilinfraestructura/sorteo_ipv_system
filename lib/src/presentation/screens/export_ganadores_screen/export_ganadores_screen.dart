import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/export_ganadores_controller.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';

class ExportGanadoresScreen extends StatelessWidget {
  const ExportGanadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExportGanadoresController>();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Obx(
        () => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recargar barrios y grupos'),
                  onPressed: () => controller.recargarBarriosYGrupos(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        value:
                            controller.barrioSeleccionado.value.isEmpty
                                ? null
                                : controller.barrioSeleccionado.value,
                        isExpanded: true,
                        items:
                            controller.barrios
                                .map(
                                  (barrio) => DropdownMenuItem(
                                    value: barrio,
                                    child: Text(barrio),
                                  ),
                                )
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
                        value:
                            controller.grupoSeleccionado.value.isEmpty
                                ? null
                                : controller.grupoSeleccionado.value,
                        isExpanded: true,
                        items:
                            controller.grupos
                                .map(
                                  (grupo) => DropdownMenuItem(
                                    value: grupo,
                                    child: Text(grupo),
                                  ),
                                )
                                .toList(),
                        onChanged: controller.onGrupoChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Mensaje de sorteo cerrado o no cerrado
            controller.sorteoCerrado.value
                ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Text(
                    '¡El sorteo de este barrio y grupo ya está CERRADO! Puedes exportar los ganadores.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Text(
                    'El sorteo de este barrio y grupo NO está cerrado. No puedes exportar hasta que se complete el sorteo.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Exportar ganadores a Excel"),
              onPressed:
                  controller.sorteoCerrado.value
                      ? () => controller.exportarConPin(context)
                      : null,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Exportar ganadores a PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed:
                  controller.sorteoCerrado.value
                      ? () => controller.exportarPdf(context)
                      : null,
            ),
            const SizedBox(height: 16),
            if (controller.mensaje.value.isNotEmpty)
              Text(
                controller.mensaje.value,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: ResponsiveConfig.bodySize,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
