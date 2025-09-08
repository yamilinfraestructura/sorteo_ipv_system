import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para manejar la sincronización con Firestore
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda un ganador en Firestore
  static Future<void> guardarGanador({
    required String barrio,
    required String grupo,
    required int participanteId,
    required int orderNumber,
    required String fullName,
    required String document,
    required int position,
    required String fecha,
  }) async {
    try {
      await _firestore.collection('ganadores').add({
        'barrio': barrio,
        'grupo': grupo,
        'participanteId': participanteId,
        'orderNumber': orderNumber,
        'fullName': fullName,
        'document': document,
        'position': position,
        'fecha': fecha,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Ganador guardado en Firestore: $fullName - Posición $position');
    } catch (e) {
      print('❌ Error al guardar en Firestore: $e');
      // No lanzamos excepción para que no afecte el funcionamiento local
    }
  }

  /// Elimina un ganador de Firestore
  static Future<void> eliminarGanador({
    required String barrio,
    required String grupo,
    required int orderNumber,
  }) async {
    try {
      final query =
          await _firestore
              .collection('ganadores')
              .where('barrio', isEqualTo: barrio)
              .where('grupo', isEqualTo: grupo)
              .where('orderNumber', isEqualTo: orderNumber)
              .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      print(
        '✅ Ganador eliminado de Firestore: $barrio - $grupo - $orderNumber',
      );
    } catch (e) {
      print('❌ Error al eliminar de Firestore: $e');
    }
  }

  /// Obtiene los ganadores recientes de Firestore
  static Stream<QuerySnapshot> obtenerGanadoresRecientes() {
    return _firestore
        .collection('ganadores')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Obtiene ganadores por barrio y grupo
  static Stream<QuerySnapshot> obtenerGanadoresPorBarrioGrupo({
    required String barrio,
    required String grupo,
  }) {
    return _firestore
        .collection('ganadores')
        .where('barrio', isEqualTo: barrio)
        .where('grupo', isEqualTo: grupo)
        .orderBy('position', descending: false)
        .snapshots();
  }

  /// Guarda un participante en Firestore (solo campos básicos)
  static Future<void> guardarParticipante({
    required String fullName,
    required String document,
    required String neighborhood,
  }) async {
    try {
      await _firestore.collection('participantes').add({
        'fullName': fullName,
        'document': document,
        'neighborhood': neighborhood,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Participante guardado en Firestore: $fullName');
    } catch (e) {
      print('❌ Error al guardar participante en Firestore: $e');
    }
  }

  /// Verifica si un DNI existe en los participantes
  static Future<bool> verificarDNI(String document) async {
    try {
      final query =
          await _firestore
              .collection('participantes')
              .where('document', isEqualTo: document)
              .limit(1)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar DNI en Firestore: $e');
      return false;
    }
  }

  /// Verifica la conexión con Firestore
  static Future<bool> verificarConexion() async {
    try {
      await _firestore.collection('ganadores').limit(1).get();
      return true;
    } catch (e) {
      print('❌ Error de conexión con Firestore: $e');
      return false;
    }
  }
}
