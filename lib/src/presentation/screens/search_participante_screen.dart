import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

//Archivos Importados
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';


class SearchParticipanteScreen extends StatefulWidget {
  const SearchParticipanteScreen({super.key});

  @override
  State<SearchParticipanteScreen> createState() => _SearchParticipanteScreenState();
}

class _SearchParticipanteScreenState extends State<SearchParticipanteScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _participante;
  String _mensaje = '';

  List<String> _barrios = [];
  String? _barrioSeleccionado;
  List<String> _grupos = [];
  String? _grupoSeleccionado;

  List<Map<String, dynamic>> _ganadoresRecientes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _cargarBarrios(),
        _cargarGrupos(),
        _cargarGanadoresRecientes(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarBarrios() async {
    if (!mounted) return;
    try {
      final barrios = await DatabaseHelper.obtenerBarrios();
      if (!mounted) return;
      setState(() {
        _barrios = barrios;
        if (_barrios.isNotEmpty && _barrioSeleccionado == null) {
          _barrioSeleccionado = _barrios.first;
        }
      });
    } catch (e) {
      print('Error al cargar barrios: $e');
    }
  }

  Future<void> _cargarGrupos() async {
    if (!mounted) return;
    try {
      final db = await DatabaseHelper.database;
      final result = await db.rawQuery('SELECT DISTINCT "group" FROM participantes');
      if (!mounted) return;
      setState(() {
        _grupos = result.map((e) => e['group'] as String).toList();
        if (_grupos.isNotEmpty && _grupoSeleccionado == null) {
          _grupoSeleccionado = _grupos.first;
        }
      });
    } catch (e) {
      print('Error al cargar grupos: $e');
    }
  }

  Future<void> _cargarGanadoresRecientes() async {
    if (!mounted) return;
    try {
      final db = await DatabaseHelper.database;
      String? barrio = _barrioSeleccionado;
      String? grupo = _grupoSeleccionado;
      List<Map<String, dynamic>> resultado;
      if (barrio != null && grupo != null) {
        resultado = await db.query(
          'ganadores',
          where: 'neighborhood = ? AND "group" = ?',
          whereArgs: [barrio, grupo],
          orderBy: 'fecha DESC',
          limit: 10,
        );
      } else if (barrio != null) {
        resultado = await db.query(
          'ganadores',
          where: 'neighborhood = ?',
          whereArgs: [barrio],
          orderBy: 'fecha DESC',
          limit: 10,
        );
      } else if (grupo != null) {
        resultado = await db.query(
          'ganadores',
          where: '"group" = ?',
          whereArgs: [grupo],
          orderBy: 'fecha DESC',
          limit: 10,
        );
      } else {
        resultado = await db.query(
          'ganadores',
          orderBy: 'fecha DESC',
          limit: 10,
        );
      }
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
            'full_name': participante.first['full_name'],
            'document': participante.first['document'],
          });
        }
      }
      if (!mounted) return;
      setState(() {
        _ganadoresRecientes = lista;
      });
    } catch (e) {
      print('Error al cargar ganadores recientes: $e');
    }
  }

  Future<void> buscarParticipante() async {
    if (!mounted) return;
    if (_barrioSeleccionado == null || _grupoSeleccionado == null) {
      setState(() => _mensaje = "Seleccioná un barrio y grupo primero.");
      return;
    }
    final db = await DatabaseHelper.database;
    final numero = int.tryParse(_controller.text);

    if (numero == null) {
      setState(() => _mensaje = "Número inválido.");
      return;
    }

    final resultados = await db.query(
      'participantes',
      where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
      whereArgs: [numero, _barrioSeleccionado, _grupoSeleccionado],
    );

    if (!mounted) return;
    if (resultados.isNotEmpty) {
      setState(() {
        _participante = resultados.first;
        _mensaje = '';
      });
    } else {
      setState(() {
        _participante = null;
        _mensaje = "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.";
      });
    }
  }

  Future<void> registrarGanador() async {
    if (!mounted) return;
    if (_participante == null) return;

    final db = await DatabaseHelper.database;

    // Verificar si ya fue registrado
    final yaGanador = await db.query(
      'ganadores',
      where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
      whereArgs: [_participante!['order_number'], _participante!['neighborhood'], _participante!['group']],
    );

    if (!mounted) return;
    if (yaGanador.isNotEmpty) {
      setState(() {
        _mensaje = 'Este participante ya fue registrado como ganador.';
      });
      return;
    }

    // Calcular la posición del nuevo ganador (1-based)
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [_participante!['neighborhood'], _participante!['group']]
    );
    final countGanadores = countResult.first['count'] as int? ?? 0;
    final nuevaPosicion = countGanadores + 1;

    await db.insert('ganadores', {
      'participanteId': _participante!['id'],
      'fecha': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'neighborhood': _participante!['neighborhood'],
      'group': _participante!['group'],
      'position': nuevaPosicion, // posición en la lista de ganadores
      'order_number': _participante!['order_number'],
      'document': _participante!['document'],
      'full_name': _participante!['full_name'],
    });

    if (!mounted) return;
    setState(() {
      _mensaje = 'Ganador registrado correctamente.';
      _controller.clear();
      _participante = null;
    });
    await _cargarGanadoresRecientes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Seleccioná un barrio',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _barrioSeleccionado,
                      isExpanded: true,
                      items: _barrios
                          .map((barrio) => DropdownMenuItem(
                                value: barrio,
                                child: Text(barrio),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (!mounted) return;
                        setState(() {
                          _barrioSeleccionado = val;
                          _participante = null;
                          _mensaje = '';
                          _controller.clear();
                        });
                        _cargarGanadoresRecientes();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Seleccioná un grupo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _grupoSeleccionado,
                      isExpanded: true,
                      items: _grupos
                          .map((grupo) => DropdownMenuItem(
                                value: grupo,
                                child: Text(grupo),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (!mounted) return;
                        setState(() {
                          _grupoSeleccionado = val;
                          _participante = null;
                          _mensaje = '';
                          _controller.clear();
                        });
                        _cargarGanadoresRecientes();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingresá el Nro de Orden',
              border: OutlineInputBorder(),
            ),
            enabled: _barrioSeleccionado != null && _grupoSeleccionado != null,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: buscarParticipante,
            icon: const Icon(Icons.search),
            label: const Text("Buscar participante"),
          ),
          const SizedBox(height: 24),
          if (_participante != null) ...[
            Text("DNI: ${_participante!['document']}"),
            Text("Nombre: ${_participante!['full_name']}"),
            Text("Barrio: ${_participante!['neighborhood']}"),
            Text("Grupo: ${_participante!['group']}"),
            Text("Nro de Orden: ${_participante!['order_number']}"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: registrarGanador,
              icon: const Icon(Icons.check_circle),
              label: const Text("Registrar como ganador"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            _mensaje,
            style: TextStyle(
              color: _mensaje.contains("correctamente") ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _ganadoresRecientes.isEmpty
                ? const Center(child: Text('No hay ganadores registrados recientemente.'))
                : Card(
                    elevation: 2,
                    child: ListView.builder(
                      itemCount: _ganadoresRecientes.length,
                      itemBuilder: (context, index) {
                        final g = _ganadoresRecientes[index];
                        return ListTile(
                          title: Text(g['full_name'] ?? ''),
                          subtitle: Text('DNI: ${g['document']} | Bolilla: ${g['position']} | Barrio: ${g['neighborhood']} | Grupo: ${g['group']}'),
                          trailing: Text('Fecha: ${g['fecha']}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
