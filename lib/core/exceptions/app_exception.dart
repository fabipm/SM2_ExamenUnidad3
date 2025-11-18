/// Excepciones base para VanguardMoney
/// Sistema centralizado para manejo consistente de errores
abstract class AppException implements Exception {
  /// Mensaje descriptivo del error para mostrar al usuario
  final String message;

  /// Código único del error para logging y debugging
  final String code;

  /// Error original que causó esta excepción (si aplica)
  final dynamic originalError;

  /// Stack trace del error original
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    required this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (Code: $code)';

  /// Convierte la excepción a un Map para logging
  Map<String, dynamic> toMap() {
    return {
      'type': runtimeType.toString(),
      'message': message,
      'code': code,
      'originalError': originalError?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}

// ========== EXCEPCIONES DE RED ==========

/// Errores relacionados con conectividad y operaciones de red
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
    super.stackTrace,
  });

  /// Error de conexión a internet
  NetworkException.noConnection()
    : super(message: 'Sin conexión a internet', code: 'NO_CONNECTION');

  /// Error de timeout
  NetworkException.timeout()
    : super(message: 'Tiempo de espera agotado', code: 'TIMEOUT');

  /// Error del servidor
  NetworkException.serverError([int? statusCode])
    : super(
        message:
            'Error del servidor${statusCode != null ? ' ($statusCode)' : ''}',
        code: 'SERVER_ERROR',
      );

  /// Error de respuesta inválida
  NetworkException.invalidResponse()
    : super(
        message: 'Respuesta del servidor inválida',
        code: 'INVALID_RESPONSE',
      );
}

// ========== EXCEPCIONES DE AUTENTICACIÓN ==========

/// Errores relacionados con autenticación y autorización
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });

  /// Usuario no encontrado
  AuthException.userNotFound()
    : super(
        message: 'No existe una cuenta con este correo',
        code: 'USER_NOT_FOUND',
      );

  /// Contraseña incorrecta
  AuthException.wrongPassword()
    : super(message: 'Contraseña incorrecta', code: 'WRONG_PASSWORD');

  /// Email ya está en uso
  AuthException.emailAlreadyInUse()
    : super(message: 'Este correo ya está registrado', code: 'EMAIL_IN_USE');

  /// Contraseña muy débil
  AuthException.weakPassword()
    : super(message: 'La contraseña es muy débil', code: 'WEAK_PASSWORD');

  /// Email inválido
  AuthException.invalidEmail()
    : super(message: 'Correo electrónico inválido', code: 'INVALID_EMAIL');

  /// Demasiados intentos
  AuthException.tooManyRequests()
    : super(
        message: 'Demasiados intentos. Intenta más tarde',
        code: 'TOO_MANY_REQUESTS',
      );

  /// Sesión expirada
  AuthException.sessionExpired()
    : super(
        message: 'Tu sesión ha expirado. Inicia sesión nuevamente',
        code: 'SESSION_EXPIRED',
      );

  /// Permisos insuficientes
  AuthException.insufficientPermissions()
    : super(
        message: 'No tienes permisos para realizar esta acción',
        code: 'INSUFFICIENT_PERMISSIONS',
      );
}

// ========== EXCEPCIONES DE VALIDACIÓN ==========

/// Errores de validación de formularios y datos
class ValidationException extends AppException {
  /// Mapa de errores por campo
  final Map<String, String> fieldErrors;

  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors = const {},
    super.originalError,
    super.stackTrace,
  });

  /// Error de campo requerido
  ValidationException.required(String fieldName)
    : fieldErrors = {fieldName: 'Este campo es requerido'},
      super(message: 'Campos requeridos faltantes', code: 'REQUIRED_FIELDS');

  /// Error de formato inválido
  ValidationException.invalidFormat(String fieldName, String format)
    : fieldErrors = {fieldName: 'Formato inválido: $format'},
      super(message: 'Formato de datos inválido', code: 'INVALID_FORMAT');

  /// Error de rango de valores
  ValidationException.outOfRange(String fieldName, String range)
    : fieldErrors = {fieldName: 'Valor fuera de rango: $range'},
      super(message: 'Valores fuera de rango permitido', code: 'OUT_OF_RANGE');

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['fieldErrors'] = fieldErrors;
    return map;
  }
}

// ========== EXCEPCIONES DE LÓGICA DE NEGOCIO ==========

/// Errores específicos de la lógica de negocio de VanguardMoney
class BusinessLogicException extends AppException {
  BusinessLogicException({
    required super.message,
    super.code = 'BUSINESS_ERROR',
    super.originalError,
    super.stackTrace,
  });

  /// Saldo insuficiente
  BusinessLogicException.insufficientBalance()
    : super(
        message: 'Saldo insuficiente para esta transacción',
        code: 'INSUFFICIENT_BALANCE',
      );

  /// Monto inválido
  BusinessLogicException.invalidAmount()
    : super(message: 'El monto debe ser mayor a cero', code: 'INVALID_AMOUNT');

  /// Fecha inválida
  BusinessLogicException.invalidDate()
    : super(
        message: 'La fecha seleccionada no es válida',
        code: 'INVALID_DATE',
      );

  /// Límite de transacciones excedido
  BusinessLogicException.transactionLimitExceeded()
    : super(
        message: 'Has excedido el límite de transacciones',
        code: 'TRANSACTION_LIMIT_EXCEEDED',
      );

  /// Plan financiero no encontrado
  BusinessLogicException.planNotFound()
    : super(message: 'Plan financiero no encontrado', code: 'PLAN_NOT_FOUND');

  /// Categoría no válida
  BusinessLogicException.invalidCategory()
    : super(
        message: 'La categoría seleccionada no es válida',
        code: 'INVALID_CATEGORY',
      );

  /// Datos insuficientes para análisis IA
  BusinessLogicException.insufficientDataForAnalysis()
    : super(
        message: 'No hay suficientes datos para generar el análisis',
        code: 'INSUFFICIENT_DATA',
      );
}

// ========== EXCEPCIÓN GENÉRICA ==========

/// Excepción para errores no categorizados
class UnknownException extends AppException {
  UnknownException({
    super.message = 'Ha ocurrido un error inesperado',
    super.code = 'UNKNOWN_ERROR',
    super.originalError,
    super.stackTrace,
  });
}
