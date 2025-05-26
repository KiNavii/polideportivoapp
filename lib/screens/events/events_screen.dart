import 'package:deportivov1/constants/app_theme.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Aquí podrías cargar tus datos de eventos

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco como en la imagen
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor, // O el color que prefieras para la AppBar
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder para la imagen del balón
            Image.asset(
              'assets/images/soccer_ball.png', // <<-- Asegúrate de que esta ruta sea correcta y el archivo exista
              width: 150, // Ajusta el tamaño si es necesario
              height: 150, // Ajusta el tamaño si es necesario
            ),
            const SizedBox(height: 24), // Espacio
            Text(
              'Próximos Eventos', // Título de la sección
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
            const SizedBox(height: 16),
            // Aquí iría tu lista de eventos (ListView.builder, etc.)
            // Por ahora, un texto simple como placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Cargando eventos...', // O un mensaje si no hay eventos
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 