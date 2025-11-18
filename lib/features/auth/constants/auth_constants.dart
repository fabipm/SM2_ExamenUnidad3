import '../../../core/constants/app_sizes.dart';

/// Constantes específicas para el módulo de autenticación
class AuthConstants {
  // ========== ESPECÍFICAS DE AUTH ==========

  /// Tamaño del logo en pantallas de autenticación
  static const double logoSize = 85.0;

  /// Tamaño de fuente para el indicador de fortaleza de contraseña
  static const double strengthIndicatorFontSize = 12.0;

  /// Espaciado entre letras para títulos de auth
  static const double titleLetterSpacing = -1.2;

  /// Elevación específica para tarjetas de auth (más alta que normal)
  static const double cardElevation = 25.0;

  /// Duración específica para animación del indicador de fortaleza
  static const Duration strengthIndicatorDuration = Duration(milliseconds: 200);

  // Currency options
  static const List<Map<String, String>> currencies = [
    {'code': 'S/', 'name': 'Sol Peruano (S/)'},
    {'code': 'USD', 'name': 'Dólar Americano (USD)'},
    {'code': 'EUR', 'name': 'Euro (EUR)'},
    {'code': 'GBP', 'name': 'Libra Esterlina (GBP)'},
  ];

  // Password strength levels
  static const List<String> strengthLabels = [
    'Muy Débil',
    'Débil',
    'Regular',
    'Buena',
    'Fuerte',
    'Muy Fuerte',
  ];
}

/// Helper para obtener padding responsivo
class AuthResponsive {
  static double getHorizontalPadding(double screenWidth) {
    if (screenWidth < AppSizes.tabletBreakpoint) {
      return screenWidth * 0.05; // Factor móvil
    } else if (screenWidth < AppSizes.desktopBreakpoint) {
      return screenWidth * 0.08; // Factor tablet
    } else {
      return screenWidth * 0.12; // Factor desktop
    }
  }

  static double getCardWidth(double screenWidth) {
    final maxWidth = AppSizes.maxContentWidth;
    final responsiveWidth = screenWidth * 0.9;
    return responsiveWidth < maxWidth ? responsiveWidth : maxWidth;
  }

  static bool isMobile(double screenWidth) =>
      screenWidth <= AppSizes.mobileMaxWidth;

  static bool isTablet(double screenWidth) =>
      screenWidth >= AppSizes.tabletBreakpoint &&
      screenWidth < AppSizes.desktopBreakpoint;
}
