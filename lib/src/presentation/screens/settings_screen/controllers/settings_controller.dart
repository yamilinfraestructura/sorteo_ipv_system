import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'package:pinput/pinput.dart';

class SettingsController extends GetxController {
  final TextEditingController pathController = TextEditingController();
  final RxString mensaje = ''.obs;

  @override
  void onInit() {
    super.onInit();
    cargarRuta();
  }

  Future<void> cargarRuta() async {
    final ruta = await DatabaseHelper.getSetting('save_path');
    pathController.text = ruta ?? '';
  }

  Future<void> guardarRuta() async {
    final nuevaRuta = pathController.text.trim();
    if (nuevaRuta.isEmpty) {
      mensaje.value = 'La ruta no puede estar vacía.';
      return;
    }
    await DatabaseHelper.upsertSetting('save_path', nuevaRuta);
    mensaje.value = 'Ruta guardada correctamente.';
  }

  Future<void> limpiarDatosPrincipalesConConfirmacion(
    BuildContext context,
  ) async {
    final focusNode = FocusNode();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return RawKeyboardListener(
                focusNode: focusNode,
                autofocus: true,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    Navigator.pop(context, true);
                  }
                },
                child: AlertDialog(
                  title: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Precaución'),
                    ],
                  ),
                  content: const Text(
                    '¿Estás seguro que deseas restaurar la base de datos? Esta acción eliminará todos los datos de participantes, ganadores y eliminados. ¡No se puede deshacer!',
                    style: TextStyle(color: Colors.red),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sí, restaurar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
    if (confirmed == true) {
      // Solicitar PIN y validar perfil
      final loginCtrl = Get.find<LoginController>();
      final user = loginCtrl.usuarioLogueado.value;
      final TextEditingController pinController = TextEditingController();
      bool autorizado = false;
      String errorPin = '';
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final focusNode = FocusNode();
          return StatefulBuilder(
            builder: (context, setState) {
              return RawKeyboardListener(
                focusNode: focusNode,
                autofocus: true,
                onKey: (RawKeyEvent event) async {
                  if (event is RawKeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    final pinIngresado = pinController.text;
                    final perfil = user?['perfil_user']?.toString() ?? '';
                    final pinHashGuardado = user?['password']?.toString() ?? '';
                    final pinHashIngresado =
                        sha256.convert(utf8.encode(pinIngresado)).toString();
                    if (pinIngresado.length == 6 &&
                        perfil.isNotEmpty &&
                        (perfil == 'Desarrollador' ||
                            perfil == 'Ministro' ||
                            perfil == 'Gobernador') &&
                        pinHashIngresado == pinHashGuardado) {
                      autorizado = true;
                      Navigator.pop(context);
                    } else {
                      setState(() => errorPin = 'Pin o perfil incorrecto');
                    }
                  }
                },
                child: AlertDialog(
                  title: const Text('Confirmar restauración'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ingresá tu PIN para confirmar la restauración de la base de datos:',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 220,
                        child: Pinput(
                          length: 6,
                          controller: pinController,
                          obscureText: true,
                          autofocus: true,
                          defaultPinTheme: PinTheme(
                            width: 36,
                            height: 48,
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          focusedPinTheme: PinTheme(
                            width: 36,
                            height: 48,
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[200],
                              border: Border.all(
                                color: Colors.deepOrange,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          submittedPinTheme: PinTheme(
                            width: 36,
                            height: 48,
                            textStyle: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[300],
                              border: Border.all(
                                color: Colors.deepOrange,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onCompleted: (_) {},
                        ),
                      ),
                      if (errorPin.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorPin,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        final pinIngresado = pinController.text;
                        final perfil = user?['perfil_user']?.toString() ?? '';
                        final pinHashGuardado =
                            user?['password']?.toString() ?? '';
                        final pinHashIngresado =
                            sha256
                                .convert(utf8.encode(pinIngresado))
                                .toString();
                        if (pinIngresado.length == 6 &&
                            perfil.isNotEmpty &&
                            (perfil == 'Desarrollador' ||
                                perfil == 'Ministro' ||
                                perfil == 'Gobernador') &&
                            pinHashIngresado == pinHashGuardado) {
                          autorizado = true;
                          Navigator.pop(context);
                        } else {
                          setState(() => errorPin = 'Pin o perfil incorrecto');
                        }
                      },
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (autorizado) {
        await DatabaseHelper.limpiarDatosPrincipales();
        mensaje.value = '¡Base de datos restaurada correctamente!';
        // Mostrar snackbar de éxito
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La restauración de la base de datos ha sido exitosa',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        mensaje.value =
            'PIN o perfil incorrecto. No se realizó la restauración.';
      }
    }
  }

  @override
  void onClose() {
    pathController.dispose();
    super.onClose();
  }
}
