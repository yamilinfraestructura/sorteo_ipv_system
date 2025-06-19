import 'package:flutter/material.dart';

//Archivos importados
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';


class ListGanadoresScreen extends StatefulWidget {
  const ListGanadoresScreen({super.key});

  @override
  State<ListGanadoresScreen> createState() => _ListGanadoresScreenState();
}

class _ListGanadoresScreenState extends State<ListGanadoresScreen> {
  List<Map<String, dynamic>> _ganadores = [];
  String? _barrioSeleccionado;
  String? _grupoSeleccionado;

  List<String> barriosDisponibles = [];
  List<String> gruposDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarGanadores();
    _cargarFiltros();
  }

  Future<void> _cargarGanadores() async {
    final db = await DatabaseHelper.database;
    String where = '';
    List<dynamic> args = [];

    if (_barrioSeleccionado != null && _barrioSeleccionado != 'Todos') {
      where += 'barrio = ?';
      args.add(_barrioSeleccionado);
    }

    if (_grupoSeleccionado != null && _grupoSeleccionado != 'Todos') {
      if (where.isNotEmpty) where += ' AND ';
      where += 'grupo = ?';
      args.add(_grupoSeleccionado);
    }

    final resultado = await db.query(
      'ganadores',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'fecha ASC',
    );

    final List<Map<String, dynamic>> lista = [];

    for (var item in resultado) {
      final participante = await db.query(
        'participantes',
        where: 'id = ?',
        whereArgs: [item['participanteId']],
      );

      if (participante.isNotEmpty) {
        lista.add({
          ...item,
          'nombre': participante.first['nombre'],
          'dni': participante.first['dni'],
        });
      }
    }

    setState(() {
      _ganadores = lista;
    });
  }

  Future<void> _cargarFiltros() async {
    final db = await DatabaseHelper.database;

    final barrios = await db.rawQuery('SELECT DISTINCT barrio FROM ganadores');
    final grupos = await db.rawQuery('SELECT DISTINCT grupo FROM ganadores');

    setState(() {
      barriosDisponibles = ['Todos', ...barrios.map((e) => e['barrio'] as String).toList()];
      gruposDisponibles = ['Todos', ...grupos.map((e) => e['grupo'] as String).toList()];
      if (_barrioSeleccionado == null) _barrioSeleccionado = 'Todos';
      if (_grupoSeleccionado == null) _grupoSeleccionado = 'Todos';
    });
  }

  Widget _buildFiltroDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Expanded(
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildFiltroDropdown(
                label: "Barrio",
                items: barriosDisponibles,
                value: _barrioSeleccionado,
                onChanged: (val) {
                  setState(() {
                    _barrioSeleccionado = val;
                  });
                  _cargarGanadores();
                },
              ),
              const SizedBox(width: 20),
              _buildFiltroDropdown(
                label: "Grupo",
                items: gruposDisponibles,
                value: _grupoSeleccionado,
                onChanged: (val) {
                  setState(() {
                    _grupoSeleccionado = val;
                  });
                  _cargarGanadores();
                },
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _cargarGanadores,
                icon: const Icon(Icons.refresh),
                label: const Text("Actualizar"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _ganadores.isEmpty
                ? const Center(child: Text("No hay ganadores registrados."))
                : ListView.builder(
                    itemCount: _ganadores.length,
                    itemBuilder: (context, index) {
                      final g = _ganadores[index];
                      return Card(
                        child: ListTile(
                          title: Text("${g['nombre']} (DNI: ${g['dni']})"),
                          subtitle: Text(
                              "Bolilla: ${g['numero_bolilla']} | Barrio: ${g['barrio']} | Grupo: ${g['grupo']}"),
                          trailing: Text("Fecha: ${g['fecha']}"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
