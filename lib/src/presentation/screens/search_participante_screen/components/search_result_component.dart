import 'package:flutter/material.dart';

class SearchResultComponent extends StatelessWidget {
  final List<Map<String, dynamic>> resultados;
  const SearchResultComponent({super.key, required this.resultados});

  @override
  Widget build(BuildContext context) {
    if (resultados.isEmpty) {
      return const Center(child: Text("No hay resultados."));
    }
    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) {
        final r = resultados[index];
        return Card(
          child: ListTile(
            title: Text("${r['full_name']} (DNI: ${r['document']})"),
            subtitle: Text(
              "Orden: ${r['order_number']} | Barrio: ${r['neighborhood']} | Grupo: ${r['group']}",
            ),
          ),
        );
      },
    );
  }
}
