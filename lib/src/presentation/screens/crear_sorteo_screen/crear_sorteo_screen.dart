import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/crear_sorteo_controller.dart';

class CrearSorteoScreen extends StatefulWidget {
  const CrearSorteoScreen({super.key});

  @override
  State<CrearSorteoScreen> createState() => _CrearSorteoScreenState();
}

class _CrearSorteoScreenState extends State<CrearSorteoScreen> {
  bool showSortPanel = false;
  late final CrearSorteoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CrearSorteoController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Sorteo')),
      body: Center(
        child:
            showSortPanel
                ? Obx(
                  () => Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // Columna derecha: Participantes importados
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Participantes Importados',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed:
                                    controller.isLoading.value
                                        ? null
                                        : controller.importarExcel,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Importar Excel'),
                              ),
                              const SizedBox(height: 12),
                              if (controller.isLoading.value)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              if (controller.mensaje.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    controller.mensaje.value,
                                    style: TextStyle(
                                      color:
                                          controller.mensaje.value.contains(
                                                'éxito',
                                              )
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Container(
                                  color: Colors.blue.shade50,
                                  child: ListView.builder(
                                    itemCount: controller.participantes.length,
                                    itemBuilder:
                                        (context, idx) => Card(
                                          child: ListTile(
                                            title: Text(
                                              controller
                                                      .participantes[idx]['nombre'] ??
                                                  '',
                                            ),
                                            subtitle: Text(
                                              'DNI: \\${controller.participantes[idx]['dni']} | Orden: \\${controller.participantes[idx]['orden']}',
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(
                                                Icons.arrow_forward,
                                              ),
                                              tooltip: 'Sortear como ganador',
                                              onPressed:
                                                  null, // Se implementará luego
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),
                        // Columna izquierda: Ganadores
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Ganadores Sorteados',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Container(
                                  color: Colors.green.shade50,
                                  child: ListView.builder(
                                    itemCount: controller.ganadores.length,
                                    itemBuilder:
                                        (context, idx) => Card(
                                          color: Colors.green.shade100,
                                          child: ListTile(
                                            title: Text(
                                              controller
                                                      .ganadores[idx]['nombre'] ??
                                                  '',
                                            ),
                                            subtitle: Text(
                                              'DNI: \\${controller.ganadores[idx]['dni']} | Orden: \\${controller.ganadores[idx]['orden']}',
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : FloatingActionButton.extended(
                  onPressed: () => setState(() => showSortPanel = true),
                  label: const Text('Crear sorteo +'),
                  icon: const Icon(Icons.add),
                ),
      ),
    );
  }
}
