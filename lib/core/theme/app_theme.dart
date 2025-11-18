import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Sistema de tema completo para VanguardMoney
/// Implementa el design system usando los colores oficiales del branding
class AppTheme {
  // ========== TEMA CLARO (Principal) ==========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme usando el branding VanguardMoney Premium
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blueClassic,
        brightness: Brightness.light,
        primary: AppColors.blueClassic,
        onPrimary: AppColors.white,
        secondary: AppColors.greenJade,
        onSecondary: AppColors.white,
        tertiary: AppColors.purplePremium,
        onTertiary: AppColors.white,
        error: AppColors.redCoral,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.blackGrey,
        surfaceContainerHighest: AppColors.greyLight,
        outline: AppColors.greyMedium,
        outlineVariant: AppColors.greyLight,
      ),

      // ========== SCAFFOLD ==========
      scaffoldBackgroundColor: AppColors.offWhite,

      // ========== APP BAR - Diseño iOS Premium ==========
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.blackGrey,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.withOpacity(AppColors.blackGrey, 0.05),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          color: AppColors.blackGrey,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.blackGrey, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColors.blackGrey,
          size: 22,
        ),
      ),

      // ========== NAVEGACIÓN - Diseño minimalista ==========
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.blueClassic,
        unselectedItemColor: AppColors.greyDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),

      // ========== BOTONES - Diseño Premium ==========
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueClassic,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.greyLight,
          disabledForegroundColor: AppColors.greyDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blueClassic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blueClassic,
          side: const BorderSide(color: AppColors.greyMedium, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ========== FLOATING ACTION BUTTON ==========
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blueClassic,
        foregroundColor: AppColors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: CircleBorder(),
      ),

      // ========== TARJETAS - Diseño Premium con sombras sutiles ==========
      cardTheme: CardThemeData(
        color: AppColors.white,
        shadowColor: AppColors.withOpacity(AppColors.blackGrey, 0.06),
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.withOpacity(AppColors.greyMedium, 0.3),
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
      ),

      // ========== CAMPOS DE TEXTO - Diseño iOS ==========
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greyLight,
        hintStyle: TextStyle(
          color: AppColors.withOpacity(AppColors.greyDark, 0.6),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.blackGrey,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),

        // Estados de los bordes - Más sutiles
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.withOpacity(AppColors.greyMedium, 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blueClassic, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.redCoral, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.redCoral, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.greyLight, width: 1),
        ),

        // Padding interno
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        // Colores de error
        errorStyle: const TextStyle(
          color: AppColors.redCoral,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ========== TIPOGRAFÍA Premium - Inspirada en iOS ==========
      textTheme: const TextTheme(
        // Títulos grandes
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.blackGrey,
          letterSpacing: -1.2,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.blackGrey,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: -0.5,
          height: 1.2,
        ),

        // Títulos de sección
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: -0.2,
        ),

        // Títulos de tarjetas y componentes
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: -0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
        ),

        // Texto del cuerpo
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: AppColors.blackGrey,
          height: 1.47,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.blackGrey,
          height: 1.4,
          letterSpacing: -0.1,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.greyDark,
          height: 1.35,
        ),

        // Etiquetas y botones
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.blackGrey,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.greyDark,
          letterSpacing: 0.2,
        ),
      ),

      // ========== DIVIDERS ==========
      dividerTheme: DividerThemeData(
        color: AppColors.withOpacity(AppColors.greyMedium, 0.4),
        thickness: 0.5,
        space: 1,
      ),

      // ========== CHIPS ==========
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.greyLight,
        selectedColor: AppColors.blueClassic,
        disabledColor: AppColors.greyLight,
        labelStyle: const TextStyle(
          color: AppColors.blackGrey,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: AppColors.withOpacity(AppColors.greyMedium, 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ========== ICONOS ==========
      iconTheme: const IconThemeData(color: AppColors.blackGrey, size: 22),

      // ========== LISTAS ==========
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  // ========== TEMA OSCURO (Futuro) ==========
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blueClassic,
        brightness: Brightness.dark,
        primary: AppColors.blueClassic,
        onPrimary: AppColors.white,
        secondary: AppColors.greenJade,
        surface: AppColors.blackGrey,
        onSurface: AppColors.white,
        background: const Color(0xFF121212),
        onBackground: AppColors.white,
        error: AppColors.redCoral,
      ),
      // TODO: Implementar theme completo cuando se requiera modo oscuro
    );
  }
}

/// Extensiones útiles para trabajar con el tema
extension ThemeExtensions on ThemeData {
  /// Obtiene el gradiente principal para elementos destacados
  Gradient get primaryGradient => AppColors.primaryGradient;

  /// Obtiene el gradiente para elementos de ingreso
  Gradient get incomeGradient => AppColors.incomeGradient;

  /// Obtiene el gradiente para elementos de gasto
  Gradient get expenseGradient => AppColors.expenseGradient;

  /// Obtiene un color de categoría basado en un índice
  Color getCategoryColor(int index) => AppColors.getCategoryColor(index);
}
