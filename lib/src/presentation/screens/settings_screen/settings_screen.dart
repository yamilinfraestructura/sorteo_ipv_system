import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, size: 32),
              const SizedBox(width: 12),
              Text(
                'Configuración',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Ruta de guardado por defecto',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextField(
                    controller: controller.pathController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ingrese la ruta de guardado',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: controller.guardarRuta,
                ),
                const SizedBox(height: 16),
                Obx(
                  () =>
                      controller.mensaje.value.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              controller.mensaje.value,
                              style: const TextStyle(color: Colors.green),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Restaurar Base de Datos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.red),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡Precaución! Esta acción eliminará todos los datos de participantes, ganadores y eliminados. No se puede deshacer.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10.0,
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Restaurar Base de Datos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        () => controller.limpiarDatosPrincipalesConConfirmacion(
                          context,
                        ),
                  ),
                ),
                Obx(
                  () =>
                      controller.mensaje.value.contains('restaurada')
                          ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              controller.mensaje.value,
                              style: const TextStyle(color: Colors.green),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
