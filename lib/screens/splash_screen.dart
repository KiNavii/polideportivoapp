import 'package:deportivov1/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(Icons.sports, size: 100, color: AppTheme.primaryColor),
            const SizedBox(height: 24),

            // Título
            Text(
              'Polideportivo',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Indicador de carga
            const SpinKitFadingCircle(color: AppTheme.primaryColor, size: 50.0),
            const SizedBox(height: 32),

            // Mensaje de carga
            Text(
              'Cargando...',
              style: TextStyle(color: AppTheme.grayColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
