/// Extensiones útiles para la clase String
extension StringExtension on String {
  /// Convierte la primera letra de una cadena a mayúscula y mantiene el resto igual
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 