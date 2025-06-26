import 'package:flutter/material.dart';
import '../controllers/search_participante_controller.dart';

class SearchParticipanteFormWidget extends StatelessWidget {
  final SearchParticipanteController controller;
  const SearchParticipanteFormWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar participante',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  controller.buscarParticipante(context);
                },
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                controller.buscarParticipante(context);
              },
              child: const Text('Buscar'),
            ),
          ],
        ),
      ),
    );
  }
} 