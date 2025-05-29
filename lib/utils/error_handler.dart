import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorType { network, authentication, validation, server, unknown }

class AppError {
  final String message;
  final ErrorType type;
  final String? code;
  final dynamic originalError;

  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
  });

  factory AppError.network([String? message]) {
    return AppError(
      message: message ?? 'Error de conexión. Verifica tu internet.',
      type: ErrorType.network,
    );
  }

  factory AppError.authentication([String? message]) {
    return AppError(
      message: message ?? 'Error de autenticación. Inicia sesión nuevamente.',
      type: ErrorType.authentication,
    );
  }

  factory AppError.validation(String message) {
    return AppError(message: message, type: ErrorType.validation);
  }

  factory AppError.server([String? message]) {
    return AppError(
      message: message ?? 'Error del servidor. Intenta más tarde.',
      type: ErrorType.server,
    );
  }

  factory AppError.unknown([String? message]) {
    return AppError(
      message: message ?? 'Ha ocurrido un error inesperado.',
      type: ErrorType.unknown,
    );
  }

  factory AppError.fromException(dynamic error) {
    if (kDebugMode) {
      print('AppError.fromException: $error');
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return AppError.network();
    }

    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return AppError.authentication();
    }

    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return AppError.server();
    }

    return AppError.unknown(error.toString());
  }

  IconData get icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }
}

class ErrorHandler {
  static void showError(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(error.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: error.color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: Icon(error.icon, color: error.color, size: 32),
            title: Text(_getErrorTitle(error.type)),
            content: Text(error.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  static String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Error de Conexión';
      case ErrorType.authentication:
        return 'Error de Autenticación';
      case ErrorType.validation:
        return 'Error de Validación';
      case ErrorType.server:
        return 'Error del Servidor';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  static void logError(AppError error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=== ERROR LOG ===');
      print('Type: ${error.type}');
      print('Message: ${error.message}');
      print('Code: ${error.code}');
      print('Original: ${error.originalError}');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
      print('================');
    }
  }
}
