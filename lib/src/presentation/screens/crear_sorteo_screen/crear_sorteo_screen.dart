import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/crear_sorteo_controller.dart';
import 'views/nuevo_sorteo_config_view.dart';

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.nombreSorteoActual.value.isNotEmpty
                              ? 'Sorteo: ${controller.nombreSorteoActual.value}'
                              : '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            children: [
                              // Columna derecha: Participantes importados
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Participantes Importados',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                                controller.mensaje.value
                                                        .contains('éxito')
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
                                          itemCount:
                                              controller.participantes.length,
                                          itemBuilder:
                                              (context, idx) => Card(
                                                child: ListTile(
                                                  title: Text(
                                                    controller
                                                            .participantes[idx]['nombre'] ??
                                                        '',
                                                  ),
                                                  subtitle: Text(
                                                    'DNI: ${controller.participantes[idx]['dni']} | Orden: ${controller.participantes[idx]['orden']}',
                                                  ),
                                                  trailing: IconButton(
                                                    icon: const Icon(
                                                      Icons.arrow_forward,
                                                    ),
                                                    tooltip:
                                                        'Sortear como ganador',
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Ganadores Sorteados',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: Container(
                                        color: Colors.green.shade50,
                                        child: ListView.builder(
                                          itemCount:
                                              controller.ganadores.length,
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
                                                    'DNI: ${controller.ganadores[idx]['dni']} | Orden: ${controller.ganadores[idx]['orden']}',
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
                      ],
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: () async {
                        // Navegar a la vista de configuración y esperar el id del sorteo creado
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => NuevoSorteoConfigView(
                                  onSorteoCreado: (int idSorteo) {
                                    setState(() {
                                      showSortPanel = true;
                                      controller.idSorteoActual.value =
                                          idSorteo;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                ),
                          ),
                        );
                      },
                      label: const Text('Crear sorteo +'),
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 24),
                    FloatingActionButton.extended(
                      heroTag: 'abrir_existente',
                      backgroundColor: Colors.blueGrey,
                      onPressed: () async {
                        // Mostrar diálogo para seleccionar sorteo existente
                        final sorteos =
                            await controller.obtenerSorteosCreados();
                        List<Map<String, dynamic>> sorteosDialog = List.from(
                          sorteos,
                        );
                        if (sorteosDialog.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No hay sorteos creados.'),
                            ),
                          );
                          return;
                        }
                        final seleccionado = await showDialog<
                          Map<String, dynamic>
                        >(
                          context: context,
                          builder:
                              (context) => StatefulBuilder(
                                builder:
                                    (context, setStateDialog) => AlertDialog(
                                      title: const Text(
                                        'Seleccionar sorteo existente',
                                      ),
                                      content: SizedBox(
                                        width: 350,
                                        height: 300,
                                        child: ListView.builder(
                                          itemCount: sorteosDialog.length,
                                          itemBuilder: (context, idx) {
                                            final s = sorteosDialog[idx];
                                            return ListTile(
                                              title: Text(
                                                s['nombre_sorteo'] ?? '',
                                              ),
                                              subtitle: Text(
                                                'Tipo: ${s['tipo_sorteo']} | Manzanas: ${s['cantidad_manzanas']}',
                                              ),
                                              onTap:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(s),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Eliminar sorteo',
                                                onPressed: () async {
                                                  final confirm = await showDialog<
                                                    bool
                                                  >(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: const Text(
                                                            'Confirmar eliminación',
                                                          ),
                                                          content: Text(
                                                            '¿Seguro que deseas eliminar el sorteo "${s['nombre_sorteo']}" y todos sus datos asociados?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                              child: const Text(
                                                                'Cancelar',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                              child: const Text(
                                                                'Eliminar',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                  if (confirm == true) {
                                                    await controller
                                                        .eliminarSorteoCompleto(
                                                          s['id_sorteo'] as int,
                                                        );
                                                    setStateDialog(() {
                                                      sorteosDialog.removeAt(
                                                        idx,
                                                      );
                                                    });
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Sorteo eliminado correctamente.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                              ),
                        );
                        if (seleccionado != null) {
                          await controller.cargarParticipantesPorSorteo(
                            seleccionado['id_sorteo'] as int,
                          );
                          setState(() {
                            showSortPanel = true;
                            controller.idSorteoActual.value =
                                seleccionado['id_sorteo'] as int;
                          });
                        }
                      },
                      label: const Text('Abrir sorteo existente'),
                      icon: const Icon(Icons.folder_open),
                    ),
                  ],
                ),
      ),
    );
  }
}
