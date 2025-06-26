import 'package:flutter/material.dart';

class ExportGanadoresListComponent extends StatelessWidget {
  final List<Map<String, dynamic>> ganadores;
  const ExportGanadoresListComponent({super.key, required this.ganadores});

  @override
  Widget build(BuildContext context) {
    if (ganadores.isEmpty) {
      return const Center(child: Text("No hay ganadores para exportar."));
    }
    return ListView.builder(
      itemCount: ganadores.length,
      itemBuilder: (context, index) {
        final g = ganadores[index];
        return Card(
          child: ListTile(
            title: Text("${g['full_name'] ?? ''} (DNI: ${g['document'] ?? ''})"),
            subtitle: Text(
                "Posición: ${g['position'] ?? ''} | Barrio: ${g['neighborhood'] ?? ''} | Grupo: ${g['group'] ?? ''}"),
            trailing: Text("Fecha: ${g['fecha'] ?? ''}"),
          ),
        );
      },
    );
  }
} 