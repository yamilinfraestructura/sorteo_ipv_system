import 'package:flutter/material.dart';

class PadronListComponent extends StatelessWidget {
  final List<Map<String, dynamic>> padrones;
  const PadronListComponent({super.key, required this.padrones});

  @override
  Widget build(BuildContext context) {
    if (padrones.isEmpty) {
      return const Center(child: Text("No hay padrones importados."));
    }
    return ListView.builder(
      itemCount: padrones.length,
      itemBuilder: (context, index) {
        final p = padrones[index];
        return Card(
          child: ListTile(
            title: Text("${p['full_name']} (DNI: ${p['document']})"),
            subtitle: Text(
              "Orden: ${p['order_number']} | Barrio: ${p['neighborhood']} | Grupo: ${p['group']}",
            ),
          ),
        );
      },
    );
  }
}
