import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          // --- Gestión de usuarios ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Gestión de usuarios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onExpansionChanged: (expanded) {
                if (expanded) controller.cargarUsuarios();
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Obx(() {
                    final usuarios = controller.usuarios;
                    if (usuarios.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: usuarios.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final usuario = usuarios[index];
                            final esUsuarioDefecto =
                                usuario['email_user'] ==
                                'yamilsaad00@gmail.com';
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text('${usuario['user_name']}'),
                              subtitle: Text(
                                '${usuario['email_user']}\nPerfil: ${usuario['perfil_user']}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    value: usuario['perfil_user'],
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Desarrollador',
                                        child: Text('Desarrollador'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Ministro',
                                        child: Text('Ministro'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Gobernador',
                                        child: Text('Gobernador'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Operador',
                                        child: Text('Operador'),
                                      ),
                                    ],
                                    onChanged:
                                        esUsuarioDefecto
                                            ? null
                                            : (nuevoPerfil) {
                                              if (nuevoPerfil != null &&
                                                  nuevoPerfil !=
                                                      usuario['perfil_user']) {
                                                controller
                                                    .actualizarPerfilUsuario(
                                                      usuario['id_user'],
                                                      nuevoPerfil,
                                                    );
                                              }
                                            },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip:
                                        esUsuarioDefecto
                                            ? 'No se puede eliminar este usuario'
                                            : 'Eliminar usuario',
                                    onPressed:
                                        esUsuarioDefecto
                                            ? null
                                            : () => controller
                                                .eliminarUsuarioConConfirmacion(
                                                  context,
                                                  usuario,
                                                ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Obx(
                          () =>
                              controller.mensajeUsuario.value.isNotEmpty
                                  ? Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      controller.mensajeUsuario.value,
                                      style: TextStyle(
                                        color:
                                            controller.mensajeUsuario.value
                                                    .contains('correctamente')
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          // --- Configuración NAS Synology ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Configuración NAS Synology',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller.nasHostController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Host/IP y puerto',
                          hintText: 'Ej: http://192.168.1.100:5000',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.nasUserController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Usuario',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => TextField(
                          controller: controller.nasPasswordController,
                          obscureText: !controller.nasPasswordVisible.value,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.nasPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () =>
                                      controller.nasPasswordVisible.value =
                                          !controller.nasPasswordVisible.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.nasPathController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Carpeta destino',
                          hintText: 'Ej: /ganadores',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        onPressed: controller.guardarConfigNas,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.wifi_tethering),
                        label: const Text('Probar conexión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: controller.probarConexionNas,
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () =>
                            controller.mensajeNas.value.isNotEmpty
                                ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    controller.mensajeNas.value,
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
          ),
          // --- Configuración FTP ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Configuración FTP',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller.ftpHostController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Host/IP',
                          hintText: 'Ej: 192.168.1.100',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.ftpUserController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Usuario',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => TextField(
                          controller: controller.ftpPasswordController,
                          obscureText: !controller.ftpPasswordVisible.value,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.ftpPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed:
                                  () =>
                                      controller.ftpPasswordVisible.value =
                                          !controller.ftpPasswordVisible.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.ftpPortController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Puerto',
                          hintText: '21 (FTP) o 22 (SFTP)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.ftpDirController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Directorio destino',
                          hintText: '/IPV/ganadores',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Obx(
                            () => Checkbox(
                              value: controller.ftpSftp.value,
                              onChanged:
                                  (v) => controller.ftpSftp.value = v ?? false,
                            ),
                          ),
                          const Text('Usar SFTP (FTP seguro)'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        onPressed: controller.guardarConfigFtp,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.wifi_tethering),
                        label: const Text('Probar conexión FTP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: controller.probarConexionFtp,
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () =>
                            controller.mensajeFtp.value.isNotEmpty
                                ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    controller.mensajeFtp.value,
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
          ),
        ],
      ),
    );
  }
}
