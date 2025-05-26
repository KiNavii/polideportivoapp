import 'package:flutter/material.dart';
import 'package:deportivov1/utils/responsive_util.dart';
import 'package:deportivov1/main.dart'; // Importar para acceder a showWatermarks

/// Clase para gestionar y configurar marcas de agua en la aplicación
class WatermarkConfig {
  /// Determina si las marcas de agua están habilitadas
  static bool get enabled => showWatermarks;

  /// Tamaño de la fuente base para marcas de agua
  static double baseFontSize = 12.0;

  /// Opacidad de las marcas de agua
  static double opacity = 0.4;

  /// Ancho del contenedor de marca de agua vertical
  static double verticalWatermarkWidth = 18.0;

  /// Obtiene el tamaño de fuente adaptable para marcas de agua
  static double getAdaptiveFontSize(BuildContext context) {
    if (!enabled) return 0;

    final bool isSmallDevice = ResponsiveUtil.isSmallMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // More aggressive font size reduction for smaller screens
    if (screenWidth < 360) {
      return ResponsiveUtil.getAdaptiveTextSize(context, baseFontSize - 3);
    } else if (isSmallDevice) {
      return ResponsiveUtil.getAdaptiveTextSize(context, baseFontSize - 2);
    }
    return ResponsiveUtil.getAdaptiveTextSize(context, baseFontSize);
  }

  /// Obtiene el espaciado de letras para las marcas de agua
  static double getLetterSpacing(BuildContext context) {
    final bool isSmallDevice = ResponsiveUtil.isSmallMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Tighter letter spacing for very small devices
    if (screenWidth < 360) return -0.5;
    return isSmallDevice ? 0 : 0.8;
  }

  /// Construye un widget de marca de agua vertical
  static Widget buildVerticalWatermark(
    BuildContext context, {
    String text = 'DEPORTIVO PAULAS',
    Color? color,
    BorderRadius? borderRadius,
  }) {
    if (!enabled) return const SizedBox.shrink();

    final fontSize = getAdaptiveFontSize(context);
    final letterSpacing = getLetterSpacing(context);
    final watermarkColor = color ?? Colors.grey.withOpacity(opacity);

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          width: verticalWatermarkWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.03)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: RotatedBox(
            quarterTurns: 1,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: watermarkColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: letterSpacing,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
