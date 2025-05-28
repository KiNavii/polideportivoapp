import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/screens/auth/login_screen.dart';
import 'package:deportivov1/screens/auth/register_screen.dart';
import 'package:deportivov1/screens/main_navigation.dart';
import 'package:deportivov1/screens/splash_screen.dart';
import 'package:deportivov1/services/auth_provider.dart';
import 'package:deportivov1/services/supabase_service.dart';
import 'package:deportivov1/services/notification_provider.dart';
import 'package:deportivov1/services/scheduled_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Variable global para controlar la visibilidad de las marcas de agua
// Establecer a false para resolver problemas de overflow en algunos dispositivos
bool showWatermarks = false; // Confirmed as false to fix overflow issues

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar soporte para español
  await initializeDateFormatting('es_ES', null);

  // Inicializar Firebase (para notificaciones push)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Supabase
  await SupabaseService.initialize();

  // 🚀 INICIALIZAR SERVICIO DE RECORDATORIOS AUTOMÁTICOS
  ScheduledNotificationService.startReminderService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
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

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, NotificationProvider>(
      builder: (context, authProvider, notificationProvider, child) {
        // Mostrar pantalla de carga mientras se inicializa
        if (authProvider.status == AuthStatus.initial) {
          return const SplashScreen();
        }

        // Si el usuario está autenticado, inicializar notificaciones
        if (authProvider.isAuthenticated && authProvider.user != null) {
          // Inicializar notificaciones solo una vez
          if (!notificationProvider.isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notificationProvider.initialize(authProvider.user!.id);
            });
          }
          return const MainNavigation();
        }

        // Si no está autenticado, limpiar notificaciones
        if (!authProvider.isAuthenticated && notificationProvider.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notificationProvider.dispose();
          });
        }

        return const LoginScreen();
      },
    );
  }
}
