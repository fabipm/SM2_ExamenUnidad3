import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo extendido de perfil de usuario que se guarda en Firestore
class UserProfileModel {
  final String uid;
  final String username;
  final String email;
  final String currency;
  final int? edad;
  final String? ocupacion;
  final double? ingresoMensualAprox;

  // 🆕 NUEVOS CAMPOS DEMOGRÁFICOS para análisis de IA personalizado
  final String? estadoCivil; // Soltero, Casado, Divorciado, Viudo, Unión libre
  final int?
  numeroDependientes; // Número total de personas que dependen económicamente
  final bool? tieneHijos; // Si tiene hijos o no
  final String?
  nivelEducacion; // Primaria, Secundaria, Técnico, Universitario, Posgrado
  final List<String>?
  objetivosFinancieros; // Ahorro, Inversión, Deuda, Vivienda, Educación, Retiro, etc.

  final DateTime createdAt;
  final bool verified;
  final int loginAttempts;
  final DateTime? lastAttempt;

  UserProfileModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.currency,
    this.edad,
    this.ocupacion,
    this.ingresoMensualAprox,
    this.estadoCivil,
    this.numeroDependientes,
    this.tieneHijos,
    this.nivelEducacion,
    this.objetivosFinancieros,
    required this.createdAt,
    required this.verified,
    this.loginAttempts = 0,
    this.lastAttempt,
  });

  /// Factory constructor para crear UserProfileModel desde Firebase User
  factory UserProfileModel.fromFirebaseUser({
    required String uid,
    required String email,
    required String username,
    required String currency,
    int? edad,
    String? ocupacion,
    double? ingresoMensualAprox,
    String? estadoCivil,
    int? numeroDependientes,
    bool? tieneHijos,
    String? nivelEducacion,
    List<String>? objetivosFinancieros,
    bool verified = false,
  }) {
    return UserProfileModel(
      uid: uid,
      username: username,
      email: email,
      currency: currency,
      edad: edad,
      ocupacion: ocupacion,
      ingresoMensualAprox: ingresoMensualAprox,
      estadoCivil: estadoCivil,
      numeroDependientes: numeroDependientes,
      tieneHijos: tieneHijos,
      nivelEducacion: nivelEducacion,
      objetivosFinancieros: objetivosFinancieros,
      createdAt: DateTime.now(),
      verified: verified,
      loginAttempts: 0,
    );
  }

  /// Factory constructor para crear desde Map (Firestore)
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      currency: map['currency'] ?? 'S/',
      edad: map['edad']?.toInt(),
      ocupacion: map['ocupacion'],
      ingresoMensualAprox: map['ingresoMensualAprox']?.toDouble(),
      estadoCivil: map['estadoCivil'],
      numeroDependientes: map['numeroDependientes']?.toInt(),
      tieneHijos: map['tieneHijos'],
      nivelEducacion: map['nivelEducacion'],
      objetivosFinancieros: map['objetivosFinancieros'] != null
          ? List<String>.from(map['objetivosFinancieros'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verified: map['verified'] ?? false,
      loginAttempts: map['loginAttempts'] ?? 0,
      lastAttempt: (map['lastAttempt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convierte el modelo a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'currency': currency,
      'edad': edad,
      'ocupacion': ocupacion,
      'ingresoMensualAprox': ingresoMensualAprox,
      'estadoCivil': estadoCivil,
      'numeroDependientes': numeroDependientes,
      'tieneHijos': tieneHijos,
      'nivelEducacion': nivelEducacion,
      'objetivosFinancieros': objetivosFinancieros,
      'createdAt': Timestamp.fromDate(createdAt),
      'verified': verified,
      'loginAttempts': loginAttempts,
      'lastAttempt': lastAttempt != null
          ? Timestamp.fromDate(lastAttempt!)
          : null,
    };
  }

  /// Método para copiar con nuevos valores
  UserProfileModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? currency,
    int? edad,
    String? ocupacion,
    double? ingresoMensualAprox,
    String? estadoCivil,
    int? numeroDependientes,
    bool? tieneHijos,
    String? nivelEducacion,
    List<String>? objetivosFinancieros,
    DateTime? createdAt,
    bool? verified,
    int? loginAttempts,
    DateTime? lastAttempt,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      edad: edad ?? this.edad,
      ocupacion: ocupacion ?? this.ocupacion,
      ingresoMensualAprox: ingresoMensualAprox ?? this.ingresoMensualAprox,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      numeroDependientes: numeroDependientes ?? this.numeroDependientes,
      tieneHijos: tieneHijos ?? this.tieneHijos,
      nivelEducacion: nivelEducacion ?? this.nivelEducacion,
      objetivosFinancieros: objetivosFinancieros ?? this.objetivosFinancieros,
      createdAt: createdAt ?? this.createdAt,
      verified: verified ?? this.verified,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }

  /// Verifica si la cuenta está bloqueada por intentos fallidos
  bool get isBlocked {
    if (loginAttempts < 5) return false;
    if (lastAttempt == null) return false;

    // Bloquear por 5 minutos después de 5 intentos fallidos
    final timeDifference = DateTime.now().difference(lastAttempt!);
    return timeDifference.inMinutes < 5;
  }

  /// Tiempo restante de bloqueo en minutos
  int get blockedTimeRemaining {
    if (!isBlocked) return 0;
    final timeDifference = DateTime.now().difference(lastAttempt!);
    return 5 - timeDifference.inMinutes;
  }

  /// Verifica si el perfil está completo
  bool get isComplete {
    return uid.isNotEmpty &&
        username.isNotEmpty &&
        email.isNotEmpty &&
        currency.isNotEmpty &&
        edad != null &&
        ocupacion != null &&
        ocupacion!.isNotEmpty &&
        ingresoMensualAprox != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserProfileModel(uid: $uid, username: $username, email: $email, '
        'currency: $currency, edad: $edad, ocupacion: $ocupacion, '
        'ingresoMensualAprox: $ingresoMensualAprox, verified: $verified, '
        'loginAttempts: $loginAttempts)';
  }
}
