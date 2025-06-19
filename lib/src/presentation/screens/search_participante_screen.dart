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

  Future<void> buscarParticipante() async {
    final db = await DatabaseHelper.database;
    final numero = int.tryParse(_controller.text);

    if (numero == null) {
      setState(() => _mensaje = "Número inválido.");
      return;
    }

    final resultados = await db.query(
      'participantes',
      where: 'numero_bolilla = ?',
      whereArgs: [numero],
    );

    if (resultados.isNotEmpty) {
      setState(() {
        _participante = resultados.first;
        _mensaje = '';
      });
    } else {
      setState(() {
        _participante = null;
        _mensaje = "No se encontró participante con esa bolilla.";
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingresá el número de bolilla',
              border: OutlineInputBorder(),
            ),
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
          )
        ],
      ),
    );
  }
}
