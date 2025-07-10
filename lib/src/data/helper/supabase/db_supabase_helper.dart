import 'package:dio/dio.dart';
import 'dart:convert';

const supabaseUrl =
    'https://ojtzumpgnbbeahzmzfbe.supabase.co'; // reemplazá con tu URL
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qdHp1bXBnbmJiZWFoem16ZmJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNDQyMTQsImV4cCI6MjA2NzcyMDIxNH0.KoSFNal83Tac5cipRjzecizDZv-FVS4WnjQpawxRUWc'; // reemplazá con tu API Key

final dio = Dio(
  BaseOptions(
    baseUrl: '$supabaseUrl/rest/v1',
    headers: {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
  ),
);

/// Respaldar una lista de ganadores en Supabase (inserción en lote)
Future<bool> respaldarGanadoresEnSupabase(
  List<Map<String, dynamic>> ganadores,
) async {
  if (ganadores.isEmpty) return true;
  try {
    // Agregar created_at a cada ganador
    final now = DateTime.now().toUtc().toIso8601String();
    final data = ganadores.map((g) => {...g, 'created_at': now}).toList();

    final response = await dio.post(
      '/ganadores',
      data: json.encode(data),
      options: Options(
        headers: {
          // Upsert por participanteId (debe haber unique constraint en la tabla)
          'Prefer': 'resolution=merge-duplicates',
        },
      ),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      print(
        '✅ Ganadores respaldados correctamente en Supabase (upsert, sin duplicados)',
      );
      return true;
    } else {
      print('❌ Falló el respaldo de ganadores: \\${response.statusCode}');
      print(response.data);
      return false;
    }
  } catch (e) {
    print('🔥 Error al respaldar ganadores: $e');
    return false;
  }
}
