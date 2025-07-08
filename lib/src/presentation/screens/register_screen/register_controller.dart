import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';

class RegisterController extends GetxController {
  final emailController = TextEditingController();
  final userNameController = TextEditingController();
  final pinController = TextEditingController();
  final perfilController = ''.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;

  // Perfiles permitidos para registro
  final List<String> perfiles = ['Desarrollador', 'Administrador'];

  // Perfiles que pueden registrar usuarios
  final List<String> perfilesAutorizados = ['Desarrollador', 'Administrador'];

  Map<String, dynamic>? usuarioAutorizador;

  @override
  void onInit() {
    super.onInit();
    // Obtener el usuario autorizador desde los argumentos
    usuarioAutorizador = Get.arguments as Map<String, dynamic>?;
  }

  bool get puedeRegistrar {
    final user = usuarioAutorizador;
    if (user == null) return false;
    return perfilesAutorizados.contains(user['perfil_user']);
  }

  Future<void> registrar() async {
    errorMessage.value = '';
    successMessage.value = '';
    final email = emailController.text.trim();
    final userName = userNameController.text.trim();
    final pin = pinController.text.trim();
    final perfil = perfilController.value;
    if (email.isEmpty ||
        userName.isEmpty ||
        pin.length != 6 ||
        perfil.isEmpty) {
      errorMessage.value = 'Completa todos los campos correctamente.';
      return;
    }
    isLoading.value = true;
    try {
      final db = await DatabaseHelper.database;
      // Verificar que el email o user_name no existan
      final existing = await db.query(
        'usuarios',
        where: 'email_user = ? OR user_name = ?',
        whereArgs: [email, userName],
      );
      if (existing.isNotEmpty) {
        errorMessage.value = 'El email o nombre de usuario ya existe.';
        isLoading.value = false;
        return;
      }
      final pinHash = sha256.convert(utf8.encode(pin)).toString();
      await db.insert('usuarios', {
        'user_name': userName,
        'password': pinHash,
        'perfil_user': perfil,
        'email_user': email,
      });
      successMessage.value = 'Usuario registrado correctamente.';
      emailController.clear();
      userNameController.clear();
      pinController.clear();
      perfilController.value = '';
    } catch (e) {
      errorMessage.value = 'Error al registrar usuario.';
    } finally {
      isLoading.value = false;
    }
  }
}
