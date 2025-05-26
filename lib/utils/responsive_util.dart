import 'package:flutter/material.dart';

class ResponsiveUtil {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Determina si es un dispositivo móvil pequeño
  static bool isSmallMobile(BuildContext context) => screenWidth(context) < 360;

  // Determina si es una tableta
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;

  // Escala texto según tamaño de pantalla
  static double getAdaptiveTextSize(BuildContext context, double fontSize) {
    double scaleFactor = isSmallMobile(context) ? 0.8 : 1.0;
    return fontSize * scaleFactor;
  }

  // Obtiene padding adaptativo (menor para móviles pequeños)
  static double getAdaptivePadding(
    BuildContext context,
    double defaultPadding,
  ) {
    double scaleFactor = isSmallMobile(context) ? 0.7 : 1.0;
    return defaultPadding * scaleFactor;
  }

  // Obtiene ancho adaptativo para contenedores
  static double getAdaptiveWidth(BuildContext context, double maxWidth) {
    double width = screenWidth(context);
    return width > maxWidth ? maxWidth : width * 0.9;
  }

  // Obtiene altura adaptativa para SizedBox
  static double getAdaptiveHeight(BuildContext context, double defaultHeight) {
    double scaleFactor = isSmallMobile(context) ? 0.85 : 1.0;
    return defaultHeight * scaleFactor;
  }
}
