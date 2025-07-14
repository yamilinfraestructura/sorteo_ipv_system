import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      // Navegar al login después del splash
      Get.offAllNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 180,
          height: 180,
        ).animate().fadeIn(duration: 3000.ms),
      ),
    );
  }
}
///El siguiente código es un ejemplo de una pantalla de splash en 
///Flutter que muestra un logo y navega a la pantalla de login 
///después de 3 segundos. Utiliza el paquete `audioplayer´ para integrearle 
///un sonido de intro welcome.mp3.
///Se necesita agregar el paquete `audioplayers` en el archivo `pubspec.yaml`
///y también agregar el archivo de sonido en la carpeta `assets/sounds/`.
/*
  import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart'; // 1. Importa audioplayers

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AudioPlayer _audioPlayer; // 2. Declara el AudioPlayer

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playWelcomeSound(); // 3. Reproduce el sonido al iniciar

    Future.delayed(const Duration(milliseconds: 3000), () {
      // Navegar al login después del splash
      Get.offAllNamed('/login');
    });
  }

  Future<void> _playWelcomeSound() async {
    await _audioPlayer.play(AssetSource('sounds/welcome.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // 4. Libera el recurso
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 180,
          height: 180,
        ).animate().fadeIn(duration: 3000.ms),
      ),
    );
  }
}

 */