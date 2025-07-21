import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/list_ganadores_controller.dart';
import 'components/ganadores_list_component.dart';

class ListGanadoresScreen extends StatelessWidget {
  const ListGanadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ListGanadoresController>();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Obx(
        () => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Barrio',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.barrioSeleccionado.value,
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
                      labelText: 'Grupo',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.grupoSeleccionado.value,
                        isExpanded: true,
                        items:
                            controller.grupos.map((grupo) {
                              final cerrado =
                                  controller.gruposCerrados[grupo] == true;
                              return DropdownMenuItem(
                                value: grupo,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        cerrado ? Colors.green.shade100 : null,
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
                                              cerrado ? FontWeight.bold : null,
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
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: controller.actualizarLista,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Actualizar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Mostrar mensaje si el sorteo está cerrado
            if (controller.sorteoCerrado.value)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Text(
                  '¡El sorteo de este barrio y grupo ya está CERRADO!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Obx(
                () =>
                    controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : (!(controller.gruposCerrados[controller
                                    .grupoSeleccionado
                                    .value] ==
                                true) &&
                            controller.barrioSeleccionado.value != 'Todos' &&
                            controller.grupoSeleccionado.value != 'Todos')
                        ? const Center(
                          child: Text(
                            "El sorteo de este barrio y grupo aún no ha finalizado. No se puede mostrar la lista de ganadores.",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : controller.ganadores.isEmpty
                        ? const Center(
                          child: Text("No hay ganadores registrados."),
                        )
                        : GanadoresListComponent(
                          ganadores: controller.ganadores,
                          sorteoCerrado:
                              controller.gruposCerrados[controller
                                  .grupoSeleccionado
                                  .value] ==
                              true,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
