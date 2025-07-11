import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart'; // Importa audioplayers

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AudioPlayer _audioPlayer; // Declara el AudioPlayer

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playWelcomeSound(); // Reproduce el sonido al iniciar

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
    _audioPlayer.dispose(); // Libera el recurso
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
