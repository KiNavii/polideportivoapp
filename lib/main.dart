import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/screens/auth/login_screen.dart';
import 'package:deportivov1/screens/auth/register_screen.dart';
import 'package:deportivov1/screens/main_navigation.dart';
import 'package:deportivov1/screens/splash_screen.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Variable global para controlar la visibilidad de las marcas de agua
// Establecer a false para resolver problemas de overflow en algunos dispositivos
bool showWatermarks = false; // Confirmed as false to fix overflow issues

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar soporte para español
  await initializeDateFormatting('es_ES', null);

  // Inicializar Supabase
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polideportivo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      routes: {
        '/': (context) => const AppWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      initialRoute: '/',
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Mostrar pantalla de carga mientras se inicializa
    if (authProvider.status == AuthStatus.initial) {
      return const SplashScreen();
    }

    // Mostrar pantalla de autenticación o navegación principal
    return authProvider.isAuthenticated
        ? const MainNavigation()
        : LoginScreen();
  }
}
