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
      child: Obx(() => Column(
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
                    labelText: 'Grupo',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.grupoSeleccionado.value,
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
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: controller.actualizarLista,
                icon: const Icon(Icons.refresh),
                label: const Text("Actualizar"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.ganadores.isEmpty
                    ? const Center(child: Text("No hay ganadores registrados."))
                    : GanadoresListComponent(ganadores: controller.ganadores),
          ),
        ],
      )),
    );
  }
}
