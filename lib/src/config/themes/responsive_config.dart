import 'package:flutter/material.dart';

class ResponsiveConfig {
  static late double _screenWidth;
  static late double _screenHeight;

  // Inicializar las dimensiones
  static void init(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
  }

  // Tamaños de texto
  static double get titleSize => _screenWidth * 0.02;  // Títulos principales
  static double get subtitleSize => _screenWidth * 0.018;  // Subtítulos
  static double get bodySize => _screenWidth * 0.015;  // Texto normal
  static double get smallSize => _screenWidth * 0.012;  // Texto pequeño

  // Espaciados
  static double get paddingSmall => _screenWidth * 0.01;  // 1% del ancho
  static double get paddingMedium => _screenWidth * 0.02;  // 2% del ancho
  static double get paddingLarge => _screenWidth * 0.03;  // 3% del ancho
  static double get paddingXLarge => _screenWidth * 0.04;  // 4% del ancho

  // Alturas
  static double get buttonHeight => _screenHeight * 0.05;  // 5% del alto
  static double get inputHeight => _screenHeight * 0.06;  // 6% del alto
  static double get cardHeight => _screenHeight * 0.15;  // 15% del alto
  static double get listItemHeight => _screenHeight * 0.08;  // 8% del alto

  // Anchos
  static double get buttonWidth => _screenWidth * 0.15;  // 15% del ancho
  static double get inputWidth => _screenWidth * 0.2;  // 20% del ancho
  static double get cardWidth => _screenWidth * 0.3;  // 30% del ancho

  // Bordes
  static double get borderRadius => _screenWidth * 0.01;  // 1% del ancho
  static double get borderWidth => _screenWidth * 0.001;  // 0.1% del ancho

  // Iconos
  static double get iconSizeSmall => _screenWidth * 0.015;  // 1.5% del ancho
  static double get iconSizeMedium => _screenWidth * 0.02;  // 2% del ancho
  static double get iconSizeLarge => _screenWidth * 0.03;  // 3% del ancho

  // Márgenes entre elementos
  static double get spacingXSmall => _screenWidth * 0.005;  // 0.5% del ancho
  static double get spacingSmall => _screenWidth * 0.01;  // 1% del ancho
  static double get spacingMedium => _screenWidth * 0.02;  // 2% del ancho
  static double get spacingLarge => _screenWidth * 0.03;  // 3% del ancho

  // Dimensiones máximas
  static double get maxWidth => _screenWidth * 0.9;  // 90% del ancho
  static double get maxHeight => _screenHeight * 0.9;  // 90% del alto

  // Dimensiones mínimas
  static double get minButtonWidth => _screenWidth * 0.1;  // 10% del ancho
  static double get minInputWidth => _screenWidth * 0.15;  // 15% del ancho

  // Helpers para obtener porcentajes personalizados del ancho/alto
  static double widthPercent(double percent) => _screenWidth * (percent / 100);
  static double heightPercent(double percent) => _screenHeight * (percent / 100);
} 