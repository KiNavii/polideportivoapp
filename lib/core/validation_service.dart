class ValidationService {
  // Validación de email
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  // Validación de contraseña
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    if (password.length < 6) return false;
    
    // Al menos una letra y un número
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    
    return hasLetter && hasNumber;
  }

  // Validación de nombre
  static bool isValidName(String name) {
    if (name.isEmpty) return false;
    if (name.length < 2) return false;
    
    // Solo letras, espacios y algunos caracteres especiales
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\-\.]+$');
    return nameRegex.hasMatch(name);
  }

  // Validación de teléfono
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    
    // Formato español: +34 XXX XXX XXX o 9XX XXX XXX
    final phoneRegex = RegExp(r'^(\+34|0034|34)?[6789]\d{8}$');
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    return phoneRegex.hasMatch(cleanPhone);
  }

  // Validación de DNI/NIE
  static bool isValidDNI(String dni) {
    if (dni.isEmpty) return false;
    
    final dniRegex = RegExp(r'^[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKE]$');
    final nieRegex = RegExp(r'^[XYZ][0-9]{7}[TRWAGMYFPDXBNJZSQVHLCKE]$');
    
    final upperDni = dni.toUpperCase();
    
    if (dniRegex.hasMatch(upperDni)) {
      return _validateDNILetter(upperDni);
    } else if (nieRegex.hasMatch(upperDni)) {
      return _validateNIELetter(upperDni);
    }
    
    return false;
  }

  // Validación de fecha
  static bool isValidDate(String date) {
    if (date.isEmpty) return false;
    
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Validación de hora
  static bool isValidTime(String time) {
    if (time.isEmpty) return false;
    
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  // Validación de precio
  static bool isValidPrice(String price) {
    if (price.isEmpty) return false;
    
    try {
      final priceValue = double.parse(price);
      return priceValue >= 0;
    } catch (e) {
      return false;
    }
  }

  // Validación de capacidad
  static bool isValidCapacity(String capacity) {
    if (capacity.isEmpty) return false;
    
    try {
      final capacityValue = int.parse(capacity);
      return capacityValue > 0;
    } catch (e) {
      return false;
    }
  }

  // Validación de URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return true; // URL opcional
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Validación de código postal
  static bool isValidPostalCode(String postalCode) {
    if (postalCode.isEmpty) return false;
    
    final postalCodeRegex = RegExp(r'^[0-9]{5}$');
    return postalCodeRegex.hasMatch(postalCode);
  }

  // Mensajes de error
  static String getEmailError(String email) {
    if (email.isEmpty) return 'El email es obligatorio';
    if (!isValidEmail(email)) return 'Formato de email inválido';
    return '';
  }

  static String getPasswordError(String password) {
    if (password.isEmpty) return 'La contraseña es obligatoria';
    if (password.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) return 'La contraseña debe contener al menos una letra';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'La contraseña debe contener al menos un número';
    return '';
  }

  static String getNameError(String name) {
    if (name.isEmpty) return 'El nombre es obligatorio';
    if (name.length < 2) return 'El nombre debe tener al menos 2 caracteres';
    if (!isValidName(name)) return 'El nombre contiene caracteres no válidos';
    return '';
  }

  static String getPhoneError(String phone) {
    if (phone.isEmpty) return 'El teléfono es obligatorio';
    if (!isValidPhone(phone)) return 'Formato de teléfono inválido';
    return '';
  }

  static String getDNIError(String dni) {
    if (dni.isEmpty) return 'El DNI/NIE es obligatorio';
    if (!isValidDNI(dni)) return 'DNI/NIE inválido';
    return '';
  }

  static String getPriceError(String price) {
    if (price.isEmpty) return 'El precio es obligatorio';
    if (!isValidPrice(price)) return 'Precio inválido';
    return '';
  }

  static String getCapacityError(String capacity) {
    if (capacity.isEmpty) return 'La capacidad es obligatoria';
    if (!isValidCapacity(capacity)) return 'Capacidad inválida';
    return '';
  }

  // Métodos privados para validación de DNI/NIE
  static bool _validateDNILetter(String dni) {
    const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
    final number = int.parse(dni.substring(0, 8));
    final letter = dni.substring(8);
    final expectedLetter = letters[number % 23];
    
    return letter == expectedLetter;
  }

  static bool _validateNIELetter(String nie) {
    const letters = 'TRWAGMYFPDXBNJZSQVHLCKE';
    const nieLetters = {'X': '0', 'Y': '1', 'Z': '2'};
    
    final firstLetter = nie.substring(0, 1);
    final numberPart = nieLetters[firstLetter]! + nie.substring(1, 8);
    final letter = nie.substring(8);
    
    final number = int.parse(numberPart);
    final expectedLetter = letters[number % 23];
    
    return letter == expectedLetter;
  }

  // Validación de rangos de fechas
  static bool isValidDateRange(DateTime startDate, DateTime endDate) {
    return startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate);
  }

  // Validación de rangos de horas
  static bool isValidTimeRange(String startTime, String endTime) {
    if (!isValidTime(startTime) || !isValidTime(endTime)) return false;
    
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    return start.isBefore(end);
  }

  static DateTime _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Validación de edad mínima
  static bool isValidAge(DateTime birthDate, int minAge) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1 >= minAge;
    }
    
    return age >= minAge;
  }

  // Validación de texto con longitud mínima y máxima
  static bool isValidTextLength(String text, int minLength, int maxLength) {
    return text.length >= minLength && text.length <= maxLength;
  }

  // Validación de números en rango
  static bool isValidNumberRange(double number, double min, double max) {
    return number >= min && number <= max;
  }
} 