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
        () => Stack(
          children: [
            Column(
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
                            hint: const Text('Selecciona un barrio'),
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
                          labelText: 'Grupo',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                controller.grupoSeleccionado.value.isEmpty
                                    ? null
                                    : controller.grupoSeleccionado.value,
                            isExpanded: true,
                            hint: const Text('Selecciona un grupo'),
                            items:
                                controller.grupos.map((grupo) {
                                  final cerrado =
                                      controller.gruposCerrados[grupo] == true;
                                  return DropdownMenuItem(
                                    value: grupo,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            cerrado
                                                ? Colors.green.shade100
                                                : null,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          if (cerrado) ...[
                                            const Icon(
                                              Icons.lock,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            grupo,
                                            style: TextStyle(
                                              color:
                                                  cerrado
                                                      ? Colors.green.shade800
                                                      : null,
                                              fontWeight:
                                                  cerrado
                                                      ? FontWeight.bold
                                                      : null,
                                            ),
                                          ),
                                          if (cerrado)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Text(
                                                '(CERRADO)',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
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
                SizedBox(height: 10),
                // =============================
                // Los siguientes botones de exportación han sido comentados para dejar solo el de FTP visible.
                // Para volver a habilitarlos, descomenta el bloque correspondiente.
                // =============================

                /*
                // Botón: Exportar Excel de Ganadores
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Exportar Excel de Ganadores"),
                  onPressed: () => controller.exportarExcel(context),
                ),

                // Botón: Exportar Excel a directorio predeterminado
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder),
                  label: const Text("Exportar Excel a directorio predeterminado"),
                  onPressed: () => controller.exportarExcelConRutaConfig(context),
                ),

                // Botón: Subir Excel al NAS (prueba)
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Subir Excel al NAS (prueba)"),
                  onPressed: () => controller.subirExcelAlNas(context),
                ),
                */

                // Botón principal: Exportar Ganadores (antes: Subir Excel por FTP (prueba))
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Exportar Ganadores"),
                  // El botón solo se habilita si el sorteo está finalizado y hay barrio y grupo seleccionados
                  // (como antes, usando controller.sorteoCerrado.value)
                  onPressed:
                      controller.sorteoCerrado.value
                          ? () => controller.subirExcelPorFtp(context)
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
            if (controller.isExporting.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
