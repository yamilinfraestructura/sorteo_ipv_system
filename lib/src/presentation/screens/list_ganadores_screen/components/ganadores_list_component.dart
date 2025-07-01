import 'package:flutter/material.dart';

class GanadoresListComponent extends StatelessWidget {
  final List<Map<String, dynamic>> ganadores;
  final bool sorteoCerrado;
  const GanadoresListComponent({
    super.key,
    required this.ganadores,
    required this.sorteoCerrado,
  });

  @override
  Widget build(BuildContext context) {
    if (ganadores.isEmpty) {
      return const Center(child: Text("No hay ganadores registrados."));
    }
    return ListView.builder(
      itemCount: ganadores.length,
      itemBuilder: (context, index) {
        final g = ganadores[index];
        return Card(
          color: sorteoCerrado ? Colors.green.shade100 : null,
          child: ListTile(
            title: Text(
              "${g['full_name']} (DNI: ${g['document']})",
              style:
                  sorteoCerrado
                      ? const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      )
                      : null,
            ),
            subtitle: Text(
              "Posición: ${g['position']} | Barrio: ${g['neighborhood']} | Grupo: ${g['group']}",
              style:
                  sorteoCerrado ? const TextStyle(color: Colors.green) : null,
            ),
            trailing: Text(
              "Fecha: ${g['fecha']}",
              style:
                  sorteoCerrado ? const TextStyle(color: Colors.green) : null,
            ),
          ),
        );
      },
    );
  }
}
