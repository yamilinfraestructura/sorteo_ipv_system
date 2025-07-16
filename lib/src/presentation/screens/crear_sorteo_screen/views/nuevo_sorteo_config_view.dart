import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../src/data/helper/db/database_helper.dart';
import '../controllers/crear_sorteo_controller.dart';

class NuevoSorteoConfigView extends StatefulWidget {
  final Function(int idSorteo) onSorteoCreado;
  const NuevoSorteoConfigView({Key? key, required this.onSorteoCreado})
    : super(key: key);

  @override
  State<NuevoSorteoConfigView> createState() => _NuevoSorteoConfigViewState();
}

class _NuevoSorteoConfigViewState extends State<NuevoSorteoConfigView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  String tipoSorteo = 'vivienda';
  int cantidadManzanas = 1;
  int cantidadViviendasPorManzana = 1;
  String tipoManzana = 'numérica';
  String tipoIdentificadorCasa = 'numérica';
  DateTime? fechaCierre;
  // Suponiendo que tienes el id_usuario en el controlador o sesión
  int idUsuario = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar nuevo sorteo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del sorteo',
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipoSorteo,
                decoration: const InputDecoration(labelText: 'Tipo de sorteo'),
                items: const [
                  DropdownMenuItem(value: 'vivienda', child: Text('Vivienda')),
                  DropdownMenuItem(value: 'lote', child: Text('Lote/Terreno')),
                ],
                onChanged: (v) => setState(() => tipoSorteo = v ?? 'vivienda'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad de manzanas',
                ),
                keyboardType: TextInputType.number,
                initialValue: cantidadManzanas.toString(),
                onChanged: (v) => cantidadManzanas = int.tryParse(v) ?? 1,
                validator:
                    (v) =>
                        (v == null ||
                                int.tryParse(v) == null ||
                                int.parse(v) < 1)
                            ? 'Ingrese un número válido'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Viviendas por manzana',
                ),
                keyboardType: TextInputType.number,
                initialValue: cantidadViviendasPorManzana.toString(),
                onChanged:
                    (v) => cantidadViviendasPorManzana = int.tryParse(v) ?? 1,
                validator:
                    (v) =>
                        (v == null ||
                                int.tryParse(v) == null ||
                                int.parse(v) < 1)
                            ? 'Ingrese un número válido'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipoManzana,
                decoration: const InputDecoration(labelText: 'Tipo de manzana'),
                items: const [
                  DropdownMenuItem(value: 'numérica', child: Text('Numérica')),
                  DropdownMenuItem(
                    value: 'alfabética',
                    child: Text('Alfabética'),
                  ),
                  DropdownMenuItem(
                    value: 'alfanumérica',
                    child: Text('Alfanumérica'),
                  ),
                ],
                onChanged: (v) => setState(() => tipoManzana = v ?? 'numérica'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipoIdentificadorCasa,
                decoration: const InputDecoration(
                  labelText: 'Identificador de casa',
                ),
                items: const [
                  DropdownMenuItem(value: 'numérica', child: Text('Numérica')),
                  DropdownMenuItem(
                    value: 'alfabética',
                    child: Text('Alfabética'),
                  ),
                  DropdownMenuItem(
                    value: 'alfanumérica',
                    child: Text('Alfanumérica'),
                  ),
                ],
                onChanged:
                    (v) =>
                        setState(() => tipoIdentificadorCasa = v ?? 'numérica'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  fechaCierre == null
                      ? 'Fecha de cierre: No seleccionada'
                      : 'Fecha de cierre: ${fechaCierre!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => fechaCierre = picked);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      'nombre_sorteo': nombreController.text.trim(),
                      'tipo_sorteo': tipoSorteo,
                      'cantidad_manzanas': cantidadManzanas,
                      'cantidad_viviendas_por_manzana':
                          cantidadViviendasPorManzana,
                      'tipo_manzana': tipoManzana,
                      'tipo_identificador_casa': tipoIdentificadorCasa,
                      'fecha_creacion': DateTime.now().toIso8601String(),
                      'fecha_cierre': fechaCierre?.toIso8601String(),
                      'fecha_eliminacion': null,
                      'id_usuario': idUsuario,
                    };
                    final idSorteo = await DatabaseHelper.insertarSorteoCreado(
                      data,
                    );
                    widget.onSorteoCreado(idSorteo);
                  }
                },
                child: const Text('Guardar y continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
