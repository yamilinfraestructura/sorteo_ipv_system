import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/presentation/pages/home_page.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';

void main() => runApp(const MyApp());

// Widget para inicializar ResponsiveConfig
class ResponsiveInit extends StatelessWidget {
  final Widget child;
  const ResponsiveInit({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    ResponsiveConfig.init(context);
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: ResponsiveInit(child: HomePage()),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
    );
  }
}