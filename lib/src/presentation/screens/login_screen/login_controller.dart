import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/data/helper/db/database_helper.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final pinController = TextEditingController();
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Usuario logueado (puedes usar un Map o un modelo)
  var usuarioLogueado = Rxn<Map<String, dynamic>>();

  Future<void> login() async {
    final email = emailController.text.trim();
    final pin = pinController.text.trim();
    errorMessage.value = '';
    if (email.isEmpty || pin.length != 6) {
      errorMessage.value = 'Completa todos los campos correctamente.';
      return;
    }
    isLoading.value = true;
    try {
      final db = await DatabaseHelper.database;
      final result = await db.query(
        'usuarios',
        where: 'email_user = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (result.isEmpty) {
        errorMessage.value = 'Usuario o PIN incorrectos.';
        isLoading.value = false;
        return;
      }
      final user = result.first;
      final pinHash = sha256.convert(utf8.encode(pin)).toString();
      if (user['password'] != pinHash) {
        errorMessage.value = 'Usuario o PIN incorrectos.';
        isLoading.value = false;
        return;
      }
      // Guardar usuario logueado en memoria
      usuarioLogueado.value = user;
      // Navegar a home
      Get.offAllNamed(
        '/welcome',
      ); // Antes: '/home'. Ahora muestra la pantalla de bienvenida intermedia.
    } catch (e) {
      errorMessage.value = 'Error al iniciar sesión.';
    } finally {
      isLoading.value = false;
    }
  }

  // Nuevo método para autorización de registro
  Future<Map<String, dynamic>?> autorizarParaRegistro() async {
    final email = emailController.text.trim();
    final pin = pinController.text.trim();
    if (email.isEmpty || pin.length != 6) {
      errorMessage.value = 'Completa todos los campos correctamente.';
      return null;
    }
    isLoading.value = true;
    try {
      final db = await DatabaseHelper.database;
      final result = await db.query(
        'usuarios',
        where: 'email_user = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (result.isEmpty) {
        errorMessage.value = 'Usuario o PIN incorrectos.';
        isLoading.value = false;
        return null;
      }
      final user = result.first;
      final pinHash = sha256.convert(utf8.encode(pin)).toString();
      if (user['password'] != pinHash) {
        errorMessage.value = 'Usuario o PIN incorrectos.';
        isLoading.value = false;
        return null;
      }
      // Verificar perfil autorizado
      final perfil = user['perfil_user']?.toString() ?? '';
      if (perfil != 'Desarrollador') {
        errorMessage.value =
            'No tienes permisos para registrar nuevos usuarios. Solo el perfil Desarrollador puede hacerlo.';
        isLoading.value = false;
        return null;
      }
      errorMessage.value = '';
      isLoading.value = false;
      return user;
    } catch (e) {
      errorMessage.value = 'Error al autorizar.';
      isLoading.value = false;
      return null;
    }
  }
}
