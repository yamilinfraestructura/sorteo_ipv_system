import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/data/helper/database_helper.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'package:pinput/pinput.dart';
import 'package:sorteo_ipv_system/src/data/helper/synology_nas_helper.dart';
import 'package:sorteo_ipv_system/src/data/helper/ftp_helper.dart';

class SettingsController extends GetxController {
  final TextEditingController pathController = TextEditingController();
  final RxString mensaje = ''.obs;
  // Gestión de usuarios
  final RxList<Map<String, dynamic>> usuarios = <Map<String, dynamic>>[].obs;
  final RxString mensajeUsuario = ''.obs;

  // --- Configuración NAS Synology ---
  final TextEditingController nasHostController = TextEditingController();
  final TextEditingController nasUserController = TextEditingController();
  final TextEditingController nasPasswordController = TextEditingController();
  final TextEditingController nasPathController = TextEditingController();
  final RxBool nasPasswordVisible = false.obs;
  final RxString mensajeNas = ''.obs;

  // --- Configuración FTP ---
  final TextEditingController ftpHostController = TextEditingController();
  final TextEditingController ftpUserController = TextEditingController();
  final TextEditingController ftpPasswordController = TextEditingController();
  final TextEditingController ftpPortController = TextEditingController();
  final TextEditingController ftpDirController = TextEditingController();
  final RxBool ftpPasswordVisible = false.obs;
  final RxBool ftpSftp = false.obs;
  final RxString mensajeFtp = ''.obs;

  @override
  void onInit() {
    super.onInit();
    cargarRuta();
    cargarConfigNas();
    cargarConfigFtp();
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
                        (perfil == 'Desarrollador') &&
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
                            (perfil == 'Desarrollador') &&
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

  Future<void> cargarUsuarios() async {
    final lista = await DatabaseHelper.obtenerUsuarios();
    usuarios.assignAll(lista);
  }

  Future<void> eliminarUsuarioConConfirmacion(
    BuildContext context,
    Map<String, dynamic> usuario,
  ) async {
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
                      (perfil == 'Desarrollador') &&
                      pinHashIngresado == pinHashGuardado) {
                    autorizado = true;
                    Navigator.pop(context);
                  } else {
                    setState(() => errorPin = 'Pin o perfil incorrecto');
                  }
                }
              },
              child: AlertDialog(
                title: const Text('Eliminar usuario'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ingresá tu PIN para eliminar al usuario: \n${usuario['user_name']}',
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
                            border: Border.all(color: Colors.orange, width: 2),
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
                          sha256.convert(utf8.encode(pinIngresado)).toString();
                      if (pinIngresado.length == 6 &&
                          perfil.isNotEmpty &&
                          (perfil == 'Desarrollador') &&
                          pinHashIngresado == pinHashGuardado) {
                        autorizado = true;
                        Navigator.pop(context);
                      } else {
                        setState(() => errorPin = 'Pin o perfil incorrecto');
                      }
                    },
                    child: const Text(
                      'Eliminar',
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
      final exito = await DatabaseHelper.eliminarUsuarioPorId(
        usuario['id_user'] as int,
      );
      if (exito) {
        mensajeUsuario.value = 'Usuario eliminado correctamente.';
        await cargarUsuarios();
      } else {
        mensajeUsuario.value = 'No se puede eliminar este usuario.';
      }
    }
  }

  Future<void> actualizarPerfilUsuario(int id, String nuevoPerfil) async {
    final exito = await DatabaseHelper.actualizarPerfilUsuario(id, nuevoPerfil);
    if (exito) {
      mensajeUsuario.value = 'Perfil actualizado correctamente.';
      await cargarUsuarios();
    } else {
      mensajeUsuario.value = 'No se pudo actualizar el perfil.';
    }
  }

  Future<void> cargarConfigNas() async {
    nasHostController.text = await DatabaseHelper.getSetting('nas_host') ?? '';
    nasUserController.text = await DatabaseHelper.getSetting('nas_user') ?? '';
    nasPasswordController.text =
        await DatabaseHelper.getSetting('nas_password') ?? '';
    nasPathController.text = await DatabaseHelper.getSetting('nas_path') ?? '';
  }

  Future<void> guardarConfigNas() async {
    final host = nasHostController.text.trim();
    final user = nasUserController.text.trim();
    final pass = nasPasswordController.text.trim();
    final path = nasPathController.text.trim();
    if (host.isEmpty || user.isEmpty || pass.isEmpty || path.isEmpty) {
      mensajeNas.value = 'Todos los campos son obligatorios.';
      return;
    }
    await DatabaseHelper.upsertSetting('nas_host', host);
    await DatabaseHelper.upsertSetting('nas_user', user);
    await DatabaseHelper.upsertSetting('nas_password', pass);
    await DatabaseHelper.upsertSetting('nas_path', path);
    mensajeNas.value = 'Configuración NAS guardada correctamente.';
  }

  Future<void> probarConexionNas() async {
    final host = nasHostController.text.trim();
    final user = nasUserController.text.trim();
    final pass = nasPasswordController.text.trim();
    final path = nasPathController.text.trim();
    if (host.isEmpty || user.isEmpty || pass.isEmpty || path.isEmpty) {
      mensajeNas.value = 'Todos los campos son obligatorios.';
      return;
    }
    final nasHelper = SynologyNasHelper(
      nasHost: host,
      user: user,
      password: pass,
    );
    mensajeNas.value = 'Probando conexión...';
    final sid = await nasHelper.login();
    if (sid == null) {
      mensajeNas.value = 'No se pudo conectar o autenticar con el NAS.';
      return;
    }
    // Validar existencia de la carpeta destino
    final existe = await nasHelper.existeCarpetaDestino(
      sid: sid,
      pathDestino: path,
    );
    await nasHelper.logout(sid);
    if (existe) {
      mensajeNas.value = '¡Conexión exitosa y carpeta destino encontrada!';
    } else {
      mensajeNas.value = 'Conexión exitosa, pero la carpeta destino NO existe.';
    }
  }

  Future<void> cargarConfigFtp() async {
    ftpHostController.text = await DatabaseHelper.getSetting('ftp_host') ?? '';
    ftpUserController.text = await DatabaseHelper.getSetting('ftp_user') ?? '';
    ftpPasswordController.text =
        await DatabaseHelper.getSetting('ftp_password') ?? '';
    ftpPortController.text =
        await DatabaseHelper.getSetting('ftp_port') ?? '21';
    ftpDirController.text = await DatabaseHelper.getSetting('ftp_dir') ?? '/';
    ftpSftp.value =
        (await DatabaseHelper.getSetting('ftp_sftp') ?? 'false') == 'true';
  }

  Future<void> guardarConfigFtp() async {
    final host = ftpHostController.text.trim();
    final user = ftpUserController.text.trim();
    final pass = ftpPasswordController.text.trim();
    final port = ftpPortController.text.trim();
    final dir = ftpDirController.text.trim();
    final sftp = ftpSftp.value;
    if (host.isEmpty || user.isEmpty || pass.isEmpty || dir.isEmpty) {
      mensajeFtp.value = 'Todos los campos son obligatorios.';
      return;
    }
    await DatabaseHelper.upsertSetting('ftp_host', host);
    await DatabaseHelper.upsertSetting('ftp_user', user);
    await DatabaseHelper.upsertSetting('ftp_password', pass);
    await DatabaseHelper.upsertSetting('ftp_port', port);
    await DatabaseHelper.upsertSetting('ftp_dir', dir);
    await DatabaseHelper.upsertSetting('ftp_sftp', sftp ? 'true' : 'false');
    mensajeFtp.value = 'Configuración FTP guardada correctamente.';
  }

  Future<void> probarConexionFtp() async {
    final host = ftpHostController.text.trim();
    final user = ftpUserController.text.trim();
    final pass = ftpPasswordController.text.trim();
    final port = int.tryParse(ftpPortController.text.trim()) ?? 21;
    final dir = ftpDirController.text.trim();
    final sftp = ftpSftp.value;
    if (host.isEmpty || user.isEmpty || pass.isEmpty || dir.isEmpty) {
      mensajeFtp.value = 'Todos los campos son obligatorios.';
      return;
    }
    final ftpHelper = FtpHelper(
      host: host,
      user: user,
      password: pass,
      port: port,
      useSftp: sftp,
    );
    mensajeFtp.value = 'Probando conexión FTP...';
    final ok = await ftpHelper.verificarConexionYDirectorio(remoteDir: dir);
    if (ok) {
      mensajeFtp.value = '¡Conexión exitosa y directorio encontrado!';
    } else {
      mensajeFtp.value =
          'No se pudo conectar o el directorio no existe/acceso denegado.';
    }
  }

  @override
  void onClose() {
    pathController.dispose();
    super.onClose();
  }
}
