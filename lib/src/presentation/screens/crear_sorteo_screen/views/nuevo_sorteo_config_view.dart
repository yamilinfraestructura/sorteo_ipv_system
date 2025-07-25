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
  String tipoManzana = 'numérica';
  String tipoIdentificadorCasa = 'numérica';
  DateTime? fechaCierre;
  int idUsuario = 1;

  // Estructura flexible de manzanas y viviendas/lotes
  List<Map<String, dynamic>> manzanas = [
    {
      'identificador': '',
      'cantidad_viviendas': 1,
      'viviendas': [
        {'numero_lote': ''},
      ],
    },
  ];

  void actualizarCantidadManzanas(int nuevaCantidad) {
    setState(() {
      if (nuevaCantidad > manzanas.length) {
        for (int i = manzanas.length; i < nuevaCantidad; i++) {
          manzanas.add({
            'identificador': '',
            'cantidad_viviendas': 1,
            'viviendas': [
              {'numero_lote': ''},
            ],
          });
        }
      } else if (nuevaCantidad < manzanas.length) {
        manzanas = manzanas.sublist(0, nuevaCantidad);
      }
      cantidadManzanas = nuevaCantidad;
    });
  }

  void actualizarCantidadViviendas(int idxManzana, int nuevaCantidad) {
    setState(() {
      List viviendas = manzanas[idxManzana]['viviendas'];
      if (nuevaCantidad > viviendas.length) {
        for (int i = viviendas.length; i < nuevaCantidad; i++) {
          viviendas.add({'numero_lote': ''});
        }
      } else if (nuevaCantidad < viviendas.length) {
        viviendas = viviendas.sublist(0, nuevaCantidad);
      }
      manzanas[idxManzana]['cantidad_viviendas'] = nuevaCantidad;
      manzanas[idxManzana]['viviendas'] = viviendas;
    });
  }

  bool validarEstructura() {
    for (var manzana in manzanas) {
      if ((manzana['identificador'] as String).trim().isEmpty) return false;
      final setViviendas = <String>{};
      for (var vivienda in manzana['viviendas']) {
        final id = (vivienda['numero_lote'] as String).trim();
        if (id.isEmpty || setViviendas.contains(id)) return false;
        setViviendas.add(id);
      }
    }
    return true;
  }

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
                onChanged: (v) {
                  final val = int.tryParse(v) ?? 1;
                  if (val > 0) actualizarCantidadManzanas(val);
                },
                validator:
                    (v) =>
                        (v == null ||
                                int.tryParse(v) == null ||
                                int.parse(v) < 1)
                            ? 'Ingrese un número válido'
                            : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Configurar manzanas y viviendas/lotes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(manzanas.length, (idxManzana) {
                final manzana = manzanas[idxManzana];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: manzana['identificador'],
                                decoration: InputDecoration(
                                  labelText:
                                      'Identificador manzana #${idxManzana + 1}',
                                ),
                                onChanged: (v) => manzana['identificador'] = v,
                                validator:
                                    (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Obligatorio'
                                            : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                initialValue:
                                    manzana['cantidad_viviendas'].toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Viviendas/Lotes',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final val = int.tryParse(v) ?? 1;
                                  if (val > 0)
                                    actualizarCantidadViviendas(
                                      idxManzana,
                                      val,
                                    );
                                },
                                validator:
                                    (v) =>
                                        (v == null ||
                                                int.tryParse(v) == null ||
                                                int.parse(v) < 1)
                                            ? 'Obligatorio'
                                            : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Identificadores de viviendas/lotes:'),
                        ...List.generate(manzana['viviendas'].length, (idxViv) {
                          final vivienda = manzana['viviendas'][idxViv];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: TextFormField(
                              initialValue: vivienda['numero_lote'],
                              decoration: InputDecoration(
                                labelText: 'Vivienda/Lote #${idxViv + 1}',
                              ),
                              onChanged: (v) => vivienda['numero_lote'] = v,
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Obligatorio'
                                          : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
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
                  if (_formKey.currentState!.validate() &&
                      validarEstructura()) {
                    final data = {
                      'nombre_sorteo': nombreController.text.trim(),
                      'tipo_sorteo': tipoSorteo,
                      'cantidad_manzanas': cantidadManzanas,
                      'cantidad_viviendas_por_manzana': null, // No aplica ahora
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
                    // Guardar manzanas y viviendas/lotes
                    for (var manzana in manzanas) {
                      final idManzana = await DatabaseHelper.insertarManzana({
                        'id_sorteo': idSorteo,
                        'identificador': manzana['identificador'],
                        'cantidad_viviendas': manzana['cantidad_viviendas'],
                      });
                      for (var vivienda in manzana['viviendas']) {
                        await DatabaseHelper.insertarVivienda({
                          'id_manzana': idManzana,
                          'id_sorteo': idSorteo,
                          'numero_lote': vivienda['numero_lote'],
                          'id_ganador': null,
                        });
                      }
                    }
                    widget.onSorteoCreado(idSorteo);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, completá todos los campos y asegurate de que no haya identificadores repetidos.',
                        ),
                      ),
                    );
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
