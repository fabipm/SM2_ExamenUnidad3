/// Tamaños, espaciados y dimensiones centralizadas para VanguardMoney
/// Garantiza consistencia visual en toda la aplicación
class AppSizes {
  // ========== ESPACIADOS ==========
  /// Espaciado extra pequeño (4px)
  static const double spaceXS = 4.0;

  /// Espaciado pequeño (8px)
  static const double spaceS = 8.0;

  /// Espaciado mediano (16px) - más usado
  static const double spaceM = 16.0;

  /// Espaciado grande (24px)
  static const double spaceL = 24.0;

  /// Espaciado extra grande (32px)
  static const double spaceXL = 32.0;

  /// Espaciado extra extra grande (48px)
  static const double spaceXXL = 48.0;

  /// Espaciado gigante (64px)
  static const double spaceGigante = 64.0;

  // ========== BORDER RADIUS ==========
  /// Radio pequeño para elementos sutiles (4px)
  static const double radiusXS = 4.0;

  /// Radio pequeño (8px)
  static const double radiusS = 8.0;

  /// Radio mediano (12px) - más usado
  static const double radiusM = 12.0;

  /// Radio grande (16px) - para tarjetas
  static const double radiusL = 16.0;

  /// Radio extra grande (24px)
  static const double radiusXL = 24.0;

  /// Radio circular (50px) - para elementos circulares
  static const double radiusCircular = 50.0;

  // ========== TAMAÑOS DE ICONOS ==========
  /// Icono extra pequeño (12px)
  static const double iconXS = 12.0;

  /// Icono pequeño (16px)
  static const double iconS = 16.0;

  /// Icono mediano (24px) - estándar
  static const double iconM = 24.0;

  /// Icono grande (32px)
  static const double iconL = 32.0;

  /// Icono extra grande (48px)
  static const double iconXL = 48.0;

  /// Icono gigante (64px)
  static const double iconXXL = 64.0;

  // ========== TAMAÑOS DE BOTONES ==========
  /// Altura de botón pequeño (32px)
  static const double buttonHeightS = 32.0;

  /// Altura de botón mediano (40px)
  static const double buttonHeightM = 40.0;

  /// Altura de botón estándar (48px)
  static const double buttonHeight = 48.0;

  /// Altura de botón grande (56px)
  static const double buttonHeightL = 56.0;

  /// Altura de botón extra grande (64px)
  static const double buttonHeightXL = 64.0;

  /// Ancho mínimo de botón
  static const double buttonMinWidth = 64.0;

  // ========== DIMENSIONES DE LA APP ==========
  /// Ancho máximo del contenido en pantallas grandes
  static const double maxContentWidth = 400.0;

  /// Altura de la barra de navegación inferior
  static const double bottomNavHeight = 60.0;

  /// Altura del AppBar
  static const double appBarHeight = 56.0;

  /// Tamaño del FloatingActionButton
  static const double fabSize = 56.0;

  /// Tamaño del FAB central personalizado (para IA)
  static const double fabCenterSize = 60.0;

  /// Altura mínima de las tarjetas
  static const double cardMinHeight = 80.0;

  /// Altura de los elementos de lista
  static const double listItemHeight = 72.0;

  /// Altura de los campos de texto
  static const double textFieldHeight = 56.0;

  // ========== ELEVACIONES Y SOMBRAS ==========
  /// Elevación baja para elementos sutiles
  static const double elevationLow = 1.0;

  /// Elevación estándar para tarjetas
  static const double elevationMedium = 2.0;

  /// Elevación alta para elementos flotantes
  static const double elevationHigh = 4.0;

  /// Elevación extra alta para modales
  static const double elevationExtra = 8.0;

  /// Elevación máxima para elementos destacados
  static const double elevationMax = 16.0;

  // ========== DURACIONES DE ANIMACIÓN ==========
  /// Animación muy rápida (100ms)
  static const int animationFastest = 100;

  /// Animación rápida (200ms)
  static const int animationFast = 200;

  /// Animación normal (300ms) - estándar
  static const int animationNormal = 300;

  /// Animación lenta (500ms)
  static const int animationSlow = 500;

  /// Animación muy lenta (800ms)
  static const int animationSlowest = 800;

  // ========== OPACIDADES ==========
  /// Opacidad muy baja para fondos sutiles
  static const double opacityVeryLow = 0.05;

  /// Opacidad baja para overlays
  static const double opacityLow = 0.1;

  /// Opacidad media para elementos deshabilitados
  static const double opacityMedium = 0.38;

  /// Opacidad alta para elementos secundarios
  static const double opacityHigh = 0.6;

  /// Opacidad muy alta para elementos casi opacos
  static const double opacityVeryHigh = 0.87;

  // ========== TAMAÑOS DE FUENTE ==========
  /// Fuente extra pequeña (10px)
  static const double fontSizeXS = 10.0;

  /// Fuente pequeña (12px)
  static const double fontSizeS = 12.0;

  /// Fuente mediana (14px)
  static const double fontSizeM = 14.0;

  /// Fuente grande (16px) - cuerpo principal
  static const double fontSizeL = 16.0;

  /// Fuente extra grande (18px)
  static const double fontSizeXL = 18.0;

  /// Fuente de título pequeño (20px)
  static const double fontSizeTitleS = 20.0;

  /// Fuente de título mediano (24px)
  static const double fontSizeTitleM = 24.0;

  /// Fuente de título grande (28px)
  static const double fontSizeTitleL = 28.0;

  /// Fuente de título extra grande (32px)
  static const double fontSizeTitleXL = 32.0;

  // ========== BREAKPOINTS RESPONSIVOS ==========
  /// Ancho mínimo para tablet
  static const double tabletBreakpoint = 768.0;

  /// Ancho mínimo para desktop
  static const double desktopBreakpoint = 1024.0;

  /// Ancho máximo para móvil
  static const double mobileMaxWidth = 767.0;

  // ========== DIMENSIONES ESPECÍFICAS DE VANGUARDMONEY ==========

  /// Altura de las tarjetas de balance en el dashboard
  static const double balanceCardHeight = 120.0;

  /// Altura de las tarjetas de transacciones
  static const double transactionCardHeight = 80.0;

  /// Altura de las tarjetas de planes financieros
  static const double planCardHeight = 140.0;

  /// Tamaño de los avatares de categoría
  static const double categoryAvatarSize = 40.0;

  /// Altura del botón de análisis IA central
  static const double aiButtonHeight = 60.0;

  /// Ancho del botón de análisis IA central
  static const double aiButtonWidth = 60.0;

  /// Altura de los gráficos en reportes
  static const double chartHeight = 200.0;

  /// Altura de los elementos en listas de transacciones
  static const double transactionListItemHeight = 72.0;

  /// Espaciado entre secciones en el dashboard
  static const double dashboardSectionSpacing = 24.0;

  /// Margen horizontal de las pantallas principales
  static const double screenHorizontalMargin = 16.0;

  /// Margen vertical de las pantallas principales
  static const double screenVerticalMargin = 16.0;

  // ========== MÉTODOS ÚTILES ==========

  /// Obtiene el espaciado apropiado según el tamaño de pantalla
  static double getResponsiveSpacing(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) {
      return spaceXL;
    } else if (screenWidth >= tabletBreakpoint) {
      return spaceL;
    } else {
      return spaceM;
    }
  }

  /// Obtiene el tamaño de fuente apropiado según el tamaño de pantalla
  static double getResponsiveFontSize(double screenWidth, double baseFontSize) {
    if (screenWidth >= desktopBreakpoint) {
      return baseFontSize * 1.2;
    } else if (screenWidth >= tabletBreakpoint) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize;
    }
  }

  /// Verifica si la pantalla es móvil
  static bool isMobile(double screenWidth) {
    return screenWidth <= mobileMaxWidth;
  }

  /// Verifica si la pantalla es tablet
  static bool isTablet(double screenWidth) {
    return screenWidth >= tabletBreakpoint && screenWidth < desktopBreakpoint;
  }

  /// Verifica si la pantalla es desktop
  static bool isDesktop(double screenWidth) {
    return screenWidth >= desktopBreakpoint;
  }
}
