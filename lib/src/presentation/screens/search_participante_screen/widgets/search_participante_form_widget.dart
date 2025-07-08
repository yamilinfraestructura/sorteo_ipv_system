import 'package:flutter/material.dart';
import '../controllers/search_participante_controller.dart';

class SearchParticipanteFormWidget extends StatefulWidget {
  final SearchParticipanteController controller;
  const SearchParticipanteFormWidget({super.key, required this.controller});

  @override
  State<SearchParticipanteFormWidget> createState() =>
      _SearchParticipanteFormWidgetState();
}

class _SearchParticipanteFormWidgetState
    extends State<SearchParticipanteFormWidget> {
  late final TextEditingController searchController;
  late final FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    // Pedir el foco automáticamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Buscar participante',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  widget.controller.buscarParticipante(context);
                },
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                widget.controller.buscarParticipante(context);
              },
              child: const Text('Buscar'),
            ),
          ],
        ),
      ),
    );
  }
}
