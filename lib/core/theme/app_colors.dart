import 'package:flutter/material.dart';

/// Colores oficiales del branding VanguardMoney - Premium Design System
class AppColors {
  // ========== COLORES BASE ==========
  /// Blanco principal - fondo principal de la app
  static const Color white = Color(0xFFFFFFFF);

  /// Blanco humo - fondos secundarios y tarjetas
  static const Color offWhite = Color(0xFFFAFAFC);

  /// Negro profundo - texto principal y elementos de contraste
  static const Color blackGrey = Color(0xFF1A1D1F);

  /// Negro suave - texto secundario
  static const Color blackSoft = Color(0xFF2F3336);

  // ========== BRAND COLOURS Premium (Tonos refinados) ==========

  /// Azul Navy Profundo - Color principal de marca (más profesional)
  static const Color blueClassic = Color(0xFF0A4D8C);

  /// Azul brillante - Acentos y estados activos
  static const Color blueBright = Color(0xFF1E88E5);

  /// Azul lavanda suave - Fondos y tarjetas
  static const Color blueLavender = Color(0xFFE8EAF6);

  /// Verde esmeralda - Ingresos y éxito (más elegante)
  static const Color greenJade = Color(0xFF10A37F);

  /// Verde menta - Fondos de ingreso
  static const Color greenMint = Color(0xFFE6F7F3);

  /// Rojo sofisticado - Gastos y alertas (menos agresivo)
  static const Color redCoral = Color(0xFFDC3545);

  /// Rojo suave - Fondos de gasto
  static const Color redSoft = Color(0xFFFEF2F2);

  /// Amarillo ámbar - Advertencias y pendientes
  static const Color yellowPastel = Color(0xFFFBBF24);

  /// Naranja premium - Categorías especiales
  static const Color orangePremium = Color(0xFFFF6B35);

  /// Rosa premium - Categorías y acentos
  static const Color pinkPastel = Color(0xFFEC4899);

  /// Púrpura elegante - Características premium
  static const Color purplePremium = Color(0xFF8B5CF6);

  // ========== COLORES DERIVADOS ==========

  /// Variaciones del color principal (Azul Navy)
  static const Color primaryLight = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF003C71);
  static const Color primarySurface = Color(0xFFE3F2FD);

  /// Grises neutros premium para UI
  static const Color greyLight = Color(0xFFF7F8FA);
  static const Color greyMedium = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF6B7280);
  static const Color greyText = Color(0xFF9CA3AF);

  /// Colores de estado
  static const Color success = greenJade;
  static const Color warning = yellowPastel;
  static const Color error = redCoral;
  static const Color info = blueBright;

  // ========== GRADIENTES PREMIUM ==========

  /// Gradiente principal - Azul profundo y elegante
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blueClassic, blueBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente para elementos de ahorro/ingresos
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [greenJade, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente para elementos de gastos/alertas
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [redCoral, Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente suave para tarjetas premium
  static const LinearGradient cardGradient = LinearGradient(
    colors: [white, offWhite],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente sutil para fondos
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [white, greyLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ========== PALETA DE CATEGORÍAS PREMIUM ==========
  /// Lista de colores elegantes para diferenciar categorías
  static const List<Color> categoryColors = [
    blueClassic, // Azul navy - Profesional
    greenJade, // Verde esmeralda - Naturaleza
    purplePremium, // Púrpura - Premium
    orangePremium, // Naranja - Energía
    pinkPastel, // Rosa - Delicado
    blueBright, // Azul brillante - Confianza
    yellowPastel, // Amarillo - Optimismo
    redCoral, // Rojo - Urgencia
  ];

  // ========== MÉTODOS ÚTILES ==========

  /// Obtiene un color de categoría basado en un índice
  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// Obtiene una versión con opacidad de cualquier color
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Retorna color para balance (positivo verde, negativo rojo)
  static Color getBalanceColor(double amount) {
    return amount >= 0 ? greenJade : redCoral;
  }

  /// Retorna color de fondo suave según tipo de transacción
  static Color getTransactionBackground(String tipo) {
    return tipo == 'ingreso' ? greenMint : redSoft;
  }

  /// Obtiene el color de texto apropiado para un fondo dado
  static Color getTextColor(Color backgroundColor) {
    // Calcula la luminancia para determinar si usar texto claro u oscuro
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? blackGrey : white;
  }
}
