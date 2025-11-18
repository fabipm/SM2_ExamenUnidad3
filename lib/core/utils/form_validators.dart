/// Clase que contiene todos los validadores para formularios
class FormValidators {
  /// Validador para nombre de usuario/alias
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    if (value.length > 30) {
      return 'El nombre no puede tener más de 30 caracteres';
    }

    // Solo letras, números, espacios y algunos caracteres especiales
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-_.]+$').hasMatch(value)) {
      return 'El nombre contiene caracteres no válidos';
    }

    return null;
  }

  /// Validador para email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    // Expresión regular más estricta para emails
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  /// Validador para contraseña con reglas estrictas
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña no puede tener más de 128 caracteres';
    }

    // Al menos una letra mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe tener al menos una mayúscula';
    }

    // Al menos una letra minúscula
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'La contraseña debe tener al menos una minúscula';
    }

    // Al menos un número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe tener al menos un número';
    }

    // Caracteres especiales opcionales pero recomendados
    // if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    //   return 'La contraseña debe tener al menos un carácter especial';
    // }

    return null;
  }

  /// Validador para confirmar contraseña
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Validador para moneda
  static String? validateCurrency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Selecciona una moneda';
    }

    return null;
  }
}

/// Clase helper para mostrar la fuerza de la contraseña
class PasswordStrength {
  static const int weak = 1;
  static const int medium = 2;
  static const int strong = 3;
  static const int veryStrong = 4;

  /// Calcula la fuerza de la contraseña
  static int calculate(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Longitud
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Tipos de caracteres
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // Penalizar patrones comunes
    if (RegExp(r'(.)\1{2,}').hasMatch(password))
      score--; // caracteres repetidos
    if (RegExp(
      r'123|abc|qwe|password',
      caseSensitive: false,
    ).hasMatch(password))
      score--; // patrones comunes

    return score.clamp(0, 4);
  }

  /// Obtiene el texto descriptivo de la fuerza
  static String getText(int strength) {
    switch (strength) {
      case 0:
        return 'Muy débil';
      case weak:
        return 'Débil';
      case medium:
        return 'Regular';
      case strong:
        return 'Fuerte';
      case veryStrong:
        return 'Muy fuerte';
      default:
        return 'Muy débil';
    }
  }

  /// Obtiene el color para mostrar la fuerza
  static String getColorHex(int strength) {
    switch (strength) {
      case 0:
        return '#F44336'; // Red
      case weak:
        return '#FF9800'; // Orange
      case medium:
        return '#FFC107'; // Amber
      case strong:
        return '#4CAF50'; // Green
      case veryStrong:
        return '#2E7D32'; // Dark Green
      default:
        return '#F44336';
    }
  }
}
