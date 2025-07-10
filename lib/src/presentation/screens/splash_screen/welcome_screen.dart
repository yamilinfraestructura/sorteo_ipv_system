import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sorteo_ipv_system/src/presentation/screens/login_screen/login_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Navegar automáticamente al home después de 3 segundos
    Future.delayed(const Duration(milliseconds: 2000), () {
      Get.offAllNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Get.find<LoginController>();
    final user = loginController.usuarioLogueado.value;
    final nombre = user?['user_name']?.toString() ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Hola $nombre',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: 44,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 3000.ms),
      ),
    );
  }
}
