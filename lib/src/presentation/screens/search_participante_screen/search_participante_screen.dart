import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';
import 'controllers/search_participante_controller.dart';

class SearchParticipanteScreen extends StatefulWidget {
  const SearchParticipanteScreen({super.key});

  @override
  State<SearchParticipanteScreen> createState() =>
      _SearchParticipanteScreenState();
}

class _SearchParticipanteScreenState extends State<SearchParticipanteScreen> {
  late final FocusNode numeroFocusNode;
  late final TextEditingController numeroController;
  late final SearchParticipanteController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SearchParticipanteController>();
    numeroFocusNode = FocusNode();
    numeroController = controller.numeroController;

    // Observar cambios en barrio/grupo y ganadores recientes para pedir foco
    controller.barrioSeleccionado.listen((_) => _tryRequestFocus());
    controller.grupoSeleccionado.listen((_) => _tryRequestFocus());
    controller.ganadoresRecientes.listen((_) => _tryRequestFocus());
  }

  void _tryRequestFocus() {
    if (controller.barrioSeleccionado.value != 'Seleccionar' &&
        controller.grupoSeleccionado.value != 'Seleccionar') {
      // Esperar un frame para asegurar que el campo esté habilitado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        numeroFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    numeroFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Obx(
        () => Column(
          children: [
            // Info grupo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Viviendas a sortear: \\ ${controller.viviendasGrupo.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
                Text(
                  'Familias empadronadas: \\ ${controller.familiasGrupo.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
                Text(
                  'Última posición sorteada: \\ ${controller.ultimaPosicion.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
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
                        items:
                            controller.barrios
                                .map(
                                  (barrio) => DropdownMenuItem(
                                    value: barrio,
                                    child: Text(
                                      barrio,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color:
                                            barrio == 'Seleccionar'
                                                ? Colors.grey
                                                : null,
                                      ),
                                    ),
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
              ],
            ),
            const SizedBox(height: 20),
            // Campo búsqueda
            TextField(
              controller: numeroController,
              focusNode: numeroFocusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Ingresá el Número de Sorteo (Nro de Orden)',
                border: OutlineInputBorder(),
              ),
              enabled:
                  controller.barrioSeleccionado.value != 'Seleccionar' &&
                  controller.grupoSeleccionado.value != 'Seleccionar' &&
                  !controller.sorteoCerrado.value,
              onSubmitted: (_) {
                controller.buscarParticipante(
                  context,
                  onDialogClosed: _tryRequestFocus,
                );
                // El foco se volverá a pedir automáticamente por el listener de ganadoresRecientes
              },
            ),
            SizedBox(height: ResponsiveConfig.standarSize * 0.01),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed:
                    (controller.barrioSeleccionado.value != 'Seleccionar' &&
                            controller.grupoSeleccionado.value != 'Seleccionar')
                        ? () => controller.buscarParticipante(
                          context,
                          onDialogClosed: _tryRequestFocus,
                        )
                        : null,
                icon: const Icon(Icons.search),
                label: const Text("Buscar participante"),
              ),
            ),
            SizedBox(height: ResponsiveConfig.standarSize * 0.01),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                controller.mensaje.value,
                style: TextStyle(
                  color:
                      controller.mensaje.value.contains("correctamente")
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: ResponsiveConfig.standarSize * 0.0005),
            // Mensaje de sorteo cerrado
            if (controller.sorteoCerrado.value)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.35,
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
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            Expanded(
              child:
                  controller.ganadoresRecientes.isEmpty
                      ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No hay ganadores registrados recientemente.',
                        ),
                      )
                      : Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.35,
                          child: Card(
                            elevation: 2,
                            child: ListView.builder(
                              itemCount: controller.ganadoresRecientes.length,
                              itemBuilder: (context, index) {
                                final g = controller.ganadoresRecientes[index];
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color:
                                        g['eliminado'] == true
                                            ? Colors.grey.shade300
                                            : controller.sorteoCerrado.value
                                            ? Colors.green.shade100
                                            : (controller
                                                        .ultimoGanadorId
                                                        .value !=
                                                    null &&
                                                g['id'] ==
                                                    controller
                                                        .ultimoGanadorId
                                                        .value)
                                            ? Colors.greenAccent.withOpacity(
                                              0.4,
                                            )
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading:
                                        g['eliminado'] == true
                                            ? const Icon(
                                              Icons.delete_forever,
                                              color: Colors.red,
                                            )
                                            : null,
                                    title: Text(
                                      '${g['full_name']} | Número de SORTEO: \\ ${g['order_number']}' ??
                                          '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            g['eliminado'] == true
                                                ? Colors.red.shade700
                                                : controller.sorteoCerrado.value
                                                ? Colors.green
                                                : null,
                                        decoration:
                                            g['eliminado'] == true
                                                ? TextDecoration.lineThrough
                                                : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'POSICIÓN: \\ ${g['position']} | DNI: \\${g['document']}',
                                          style: TextStyle(
                                            color:
                                                g['eliminado'] == true
                                                    ? Colors.red.shade700
                                                    : controller
                                                        .sorteoCerrado
                                                        .value
                                                    ? Colors.green
                                                    : null,
                                            decoration:
                                                g['eliminado'] == true
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                          ),
                                        ),
                                        if (g['eliminado'] == true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              'Eliminado por: \\${g['eliminado_por'] ?? '-'} | Fecha de baja: \\${g['fecha_baja'] != null ? g['fecha_baja'].toString().replaceFirst('T', ' ').substring(0, 19) : '-'}',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontStyle: FontStyle.italic,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing:
                                        g['eliminado'] == true
                                            ? null
                                            : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 60,
                                                  child: Text(
                                                    'Fecha: \\${g['fecha']}',
                                                    style: TextStyle(
                                                      color:
                                                          controller
                                                                  .sorteoCerrado
                                                                  .value
                                                              ? Colors.green
                                                              : null,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip: 'Eliminar ganador',
                                                  onPressed:
                                                      () => controller
                                                          .eliminarGanador(
                                                            context,
                                                            g,
                                                          ),
                                                ),
                                              ],
                                            ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
