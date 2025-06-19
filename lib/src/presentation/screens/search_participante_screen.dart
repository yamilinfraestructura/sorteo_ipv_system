import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  List<Map<String, dynamic>> _ganadoresRecientes = [];

  @override
  void initState() {
    super.initState();
    _cargarBarrios();
    _cargarGanadoresRecientes();
  }

  Future<void> _cargarBarrios() async {
    final barrios = await DatabaseHelper.obtenerBarrios();
    setState(() {
      _barrios = barrios;
    });
  }

  Future<void> _cargarGanadoresRecientes() async {
    final db = await DatabaseHelper.database;
    String? barrio = _barrioSeleccionado;
    List<Map<String, dynamic>> resultado;
    if (barrio != null) {
      resultado = await db.query(
        'ganadores',
        where: 'barrio = ?',
        whereArgs: [barrio],
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
          'nombre': participante.first['nombre'],
          'dni': participante.first['dni'],
        });
      }
    }
    setState(() {
      _ganadoresRecientes = lista;
    });
  }

  Future<void> buscarParticipante() async {
    if (_barrioSeleccionado == null) {
      setState(() => _mensaje = "Seleccioná un barrio primero.");
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
      where: 'numero_bolilla = ? AND barrio = ?',
      whereArgs: [numero, _barrioSeleccionado],
    );

    if (resultados.isNotEmpty) {
      setState(() {
        _participante = resultados.first;
        _mensaje = '';
      });
    } else {
      setState(() {
        _participante = null;
        _mensaje = "No se encontró participante con esa bolilla en el barrio seleccionado.";
      });
    }
  }

  Future<void> registrarGanador() async {
    if (_participante == null) return;

    final db = await DatabaseHelper.database;

    // Verificar si ya fue registrado
    final yaGanador = await db.query(
      'ganadores',
      where: 'numero_bolilla = ?',
      whereArgs: [_participante!['numero_bolilla']],
    );

    if (yaGanador.isNotEmpty) {
      setState(() {
        _mensaje = 'Este número ya fue registrado como ganador.';
      });
      return;
    }

    await db.insert('ganadores', {
      'participanteId': _participante!['id'],
      'fecha': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'barrio': _participante!['barrio'],
      'grupo': _participante!['grupo'],
      'numero_bolilla': _participante!['numero_bolilla'],
    });

    setState(() {
      _mensaje = 'Ganador registrado correctamente.';
      _controller.clear();
      _participante = null;
    });
    await _cargarGanadoresRecientes();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          InputDecorator(
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
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingresá el número de bolilla',
              border: OutlineInputBorder(),
            ),
            enabled: _barrioSeleccionado != null,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: buscarParticipante,
            icon: const Icon(Icons.search),
            label: const Text("Buscar participante"),
          ),
          const SizedBox(height: 24),
          if (_participante != null) ...[
            Text("DNI: ${_participante!['dni']}"),
            Text("Nombre: ${_participante!['nombre']}"),
            Text("Barrio: ${_participante!['barrio']}"),
            Text("Grupo: ${_participante!['grupo']}"),
            Text("Bolilla: ${_participante!['numero_bolilla']}"),
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
                          title: Text(g['nombre'] ?? ''),
                          subtitle: Text('DNI: ${g['dni']} | Bolilla: ${g['numero_bolilla']} | Barrio: ${g['barrio']} | Grupo: ${g['grupo']}'),
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
