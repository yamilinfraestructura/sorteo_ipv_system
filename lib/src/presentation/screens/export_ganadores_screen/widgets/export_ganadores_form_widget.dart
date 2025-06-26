import 'package:flutter/material.dart';
import '../controllers/export_ganadores_controller.dart';

class ExportGanadoresFormWidget extends StatelessWidget {
  final ExportGanadoresController controller;
  const ExportGanadoresFormWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Aquí iría el formulario de exportación (selectores, botón de exportar, etc.)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Text('Exportar ganadores a Excel'),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica para exportar
              },
              child: const Text('Exportar'),
            ),
          ],
        ),
      ),
    );
  }
} 