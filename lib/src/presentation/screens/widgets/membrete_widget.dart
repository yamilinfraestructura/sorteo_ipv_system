import 'package:flutter/material.dart';
import 'package:sorteo_ipv_system/src/config/themes/responsive_config.dart';

class MembreteWidget extends StatelessWidget {
  const MembreteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Image.asset(
          'assets/images/membrete.png',
          width: ResponsiveConfig.standarSize * 0.35,
          height: ResponsiveConfig.standarSize * 0.05,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
