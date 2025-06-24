import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Archivos Importados
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';


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
  String? _barrioSeleccionado = 'Seleccionar';
  List<String> _grupos = [];
  String? _grupoSeleccionado = 'Seleccionar';

  List<Map<String, dynamic>> _ganadoresRecientes = [];
  bool _isLoading = false;

  int _viviendasGrupo = 0;
  int _familiasGrupo = 0;
  int _ultimaPosicionGanador = 0;

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
        _cargarInfoGrupo(),
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
        _barrios = ['Seleccionar', ...barrios];
        if (_barrios.length > 1 && (_barrioSeleccionado == null || !_barrios.contains(_barrioSeleccionado))) {
          _barrioSeleccionado = 'Seleccionar';
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
      final grupos = result.map((e) => e['group'] as String).toList();
      setState(() {
        _grupos = ['Seleccionar', ...grupos];
        if (_grupos.length > 1 && (_grupoSeleccionado == null || !_grupos.contains(_grupoSeleccionado))) {
          _grupoSeleccionado = 'Seleccionar';
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

  Future<void> _cargarInfoGrupo() async {
    if (_barrioSeleccionado == null || _grupoSeleccionado == null) {
      setState(() {
        _viviendasGrupo = 0;
        _familiasGrupo = 0;
        _ultimaPosicionGanador = 0;
      });
      return;
    }
    final db = await DatabaseHelper.database;
    // Buscar viviendas y familias del grupo
    final infoResult = await db.query(
      'participantes',
      columns: ['viviendas', 'familias'],
      where: 'neighborhood = ? AND "group" = ?',
      whereArgs: [_barrioSeleccionado, _grupoSeleccionado],
      limit: 1,
    );
    int viviendas = 0;
    int familias = 0;
    if (infoResult.isNotEmpty) {
      final v = infoResult.first['viviendas'];
      final f = infoResult.first['familias'];
      viviendas = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      familias = f is int ? f : int.tryParse(f?.toString() ?? '0') ?? 0;
    }
    // Buscar última posición de ganador
    final posResult = await db.rawQuery(
      'SELECT MAX(position) as maxPos FROM ganadores WHERE neighborhood = ? AND "group" = ?',
      [_barrioSeleccionado, _grupoSeleccionado],
    );
    int ultimaPos = 0;
    if (posResult.isNotEmpty) {
      ultimaPos = posResult.first['maxPos'] is int
        ? posResult.first['maxPos'] as int
        : int.tryParse(posResult.first['maxPos']?.toString() ?? '0') ?? 0;
    }
    setState(() {
      _viviendasGrupo = viviendas;
      _familiasGrupo = familias;
      _ultimaPosicionGanador = ultimaPos;
    });
  }

  Future<void> buscarParticipante() async {
    if (!mounted) return;
    if (_barrioSeleccionado == null || _grupoSeleccionado == null || _barrioSeleccionado == 'Seleccionar' || _grupoSeleccionado == 'Seleccionar') {
      setState(() => _mensaje = "Seleccioná un barrio y grupo primero.");
      return;
    }
    final db = await DatabaseHelper.database;
    final numero = int.tryParse(_controller.text);
    if (numero == null) {
      setState(() => _mensaje = "Número inválido.");
      _mostrarAlerta(context, "Número inválido", "Por favor, ingresa un número de orden válido.");
      return;
    }
    final resultados = await db.query(
      'participantes',
      where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
      whereArgs: [numero, _barrioSeleccionado, _grupoSeleccionado],
    );
    if (!mounted) return;
    if (resultados.isNotEmpty) {
      final participante = resultados.first;
      // Verificar si ya fue registrado como ganador
      final yaGanador = await db.query(
        'ganadores',
        where: 'order_number = ? AND neighborhood = ? AND "group" = ?',
        whereArgs: [participante['order_number'], participante['neighborhood'], participante['group']],
      );
      if (yaGanador.isNotEmpty) {
        final pos = yaGanador.first['position'] ?? '-';
        _mostrarAlerta(context, "Ya registrado", "Este participante ya ha sido registrado como ganador. Posición Número $pos");
        setState(() {
          _participante = null;
          _mensaje = '';
        });
        return;
      }
      // Mostrar alerta con el nombre en grande y negrita
      _mostrarAlertaParticipante(context, participante);
      setState(() {
        _participante = participante;
        _mensaje = '';
      });
    } else {
      setState(() {
        _participante = null;
        _mensaje = "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.";
      });
      _mostrarAlerta(context, "No encontrado", "No se encontró participante con ese Nro de Orden en el barrio y grupo seleccionados.");
    }
  }

  void _mostrarAlerta(BuildContext context, String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveConfig.subtitleSize)),
        content: Text(mensaje, style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Aceptar", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
          )
        ],
      ),
    );
  }

  void _mostrarAlertaParticipante(BuildContext context, Map<String, dynamic> participante) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          participante['full_name'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveConfig.titleSize),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("DNI: ${participante['document']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
            Text("Barrio: ${participante['neighborhood']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
            Text("Grupo: ${participante['group']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
            Text("Nro de Orden: ${participante['order_number']}", style: TextStyle(fontSize: ResponsiveConfig.bodySize)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              registrarGanador();
            },
            child: Text("Aceptar y Registrar", 
              style: TextStyle(
                fontSize: ResponsiveConfig.bodySize,
                color: Colors.green,
                fontWeight: FontWeight.bold
              )
            ),
          )
        ],
      ),
    );
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
      padding: EdgeInsets.all(ResponsiveConfig.paddingLarge),
      child: Column(
        children: [
          // Row informativo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Viviendas a sortear: $_viviendasGrupo',
                style: TextStyle(fontSize: ResponsiveConfig.bodySize, fontWeight: FontWeight.bold),
              ),
              Text(
                'Familias empadronadas: $_familiasGrupo',
                style: TextStyle(fontSize: ResponsiveConfig.bodySize, fontWeight: FontWeight.bold),
              ),
              Text(
                'Última posición sorteada: $_ultimaPosicionGanador',
                style: TextStyle(fontSize: ResponsiveConfig.bodySize, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConfig.spacingLarge),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Seleccioná un barrio',
                    labelStyle: TextStyle(fontSize: ResponsiveConfig.bodySize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveConfig.borderRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConfig.paddingMedium,
                      vertical: ResponsiveConfig.paddingSmall,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _barrioSeleccionado,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: ResponsiveConfig.bodySize,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
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
                        _cargarInfoGrupo();
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveConfig.spacingMedium),
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Seleccioná un grupo',
                    labelStyle: TextStyle(fontSize: ResponsiveConfig.bodySize),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ResponsiveConfig.borderRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveConfig.paddingMedium,
                      vertical: ResponsiveConfig.paddingSmall,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _grupoSeleccionado,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: ResponsiveConfig.bodySize,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
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
                        _cargarInfoGrupo();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveConfig.spacingMedium),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingresá el Número de Sorteo(Nro de Orden)',
              border: OutlineInputBorder(),
            ),
            enabled: _barrioSeleccionado != null && _barrioSeleccionado != 'Seleccionar' && _grupoSeleccionado != null && _grupoSeleccionado != 'Seleccionar',
            onSubmitted: (_) => buscarParticipante(),
          ),
          SizedBox(height: ResponsiveConfig.spacingMedium),
          ElevatedButton.icon(
            onPressed: (_barrioSeleccionado != null && _barrioSeleccionado != 'Seleccionar' && _grupoSeleccionado != null && _grupoSeleccionado != 'Seleccionar') ? buscarParticipante : null,
            icon: const Icon(Icons.search),
            label: const Text("Buscar participante"),
          ),
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
