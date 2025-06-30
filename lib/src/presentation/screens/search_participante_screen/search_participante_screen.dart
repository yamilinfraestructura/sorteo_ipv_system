import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/search_participante_controller.dart';

class SearchParticipanteScreen extends StatelessWidget {
  const SearchParticipanteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SearchParticipanteController>();
    // Guardar el contexto raíz en el controlador
    controller.rootContext ??= context;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Obx(() => Column(
        children: [
          // Info grupo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Viviendas a sortear: \\ ${controller.viviendasGrupo.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Familias empadronadas: \\ ${controller.familiasGrupo.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Última posición sorteada: \\ ${controller.ultimaPosicion.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          // Selectores
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
                    labelText: 'Seleccioná un grupo',
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
            ],
          ),
          const SizedBox(height: 20),
          // Campo búsqueda
          TextField(
            controller: controller.numeroController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingresá el Número de Sorteo (Nro de Orden)',
              border: OutlineInputBorder(),
            ),
            enabled: controller.barrioSeleccionado.value != 'Seleccionar' && controller.grupoSeleccionado.value != 'Seleccionar',
            onSubmitted: (_) => controller.buscarParticipante(context),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: (controller.barrioSeleccionado.value != 'Seleccionar' && controller.grupoSeleccionado.value != 'Seleccionar')
                ? () => controller.buscarParticipante(context)
                : null,
            icon: const Icon(Icons.search),
            label: const Text("Buscar participante"),
          ),
          const SizedBox(height: 24),
          Text(
            controller.mensaje.value,
            style: TextStyle(
              color: controller.mensaje.value.contains("correctamente") ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: controller.ganadoresRecientes.isEmpty
                ? const Center(child: Text('No hay ganadores registrados recientemente.'))
                : Card(
                    elevation: 2,
                    child: ListView.builder(
                      itemCount: controller.ganadoresRecientes.length,
                      itemBuilder: (context, index) {
                        final g = controller.ganadoresRecientes[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: (controller.ultimoGanadorId.value != null && g['id'] == controller.ultimoGanadorId.value)
                                ? Colors.greenAccent.withOpacity(0.4)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text('${g['full_name']} | Número de SORTEO: \\ ${g['order_number']}' ?? '', style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text('POSICIÓN: \\ ${g['position']} | DNI: \\${g['document']} | Barrio: \\${g['neighborhood']} | Grupo: \\${g['group']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Fecha: \\${g['fecha']}'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar ganador',
                                  onPressed: () => controller.eliminarGanador(context, g),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      )),
    );
  }
}
