/// Rutas centralizadas para la navegación en VanguardMoney
/// Facilita el mantenimiento y evita errores de tipeo
class AppRoutes {
  // ========== RUTAS DE AUTENTICACIÓN ==========
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ========== RUTAS PRINCIPALES ==========
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // ========== RUTAS DE NAVEGACIÓN PRINCIPAL ==========
  /// Página de inicio (home tab)
  static const String homeTab = '/home/inicio';

  /// Planes financieros (planes tab)
  static const String planesTab = '/home/planes';

  /// Análisis IA (centro - tab principal)
  static const String analysisTab = '/home/analysis';

  /// Transacciones (registro tab)
  static const String transactionsTab = '/home/transactions';

  /// Reportes (reportes tab)
  static const String reportsTab = '/home/reports';

  // ========== RUTAS DE PERFIL ==========
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String profileSettings = '/profile/settings';
  static const String profilePreferences = '/profile/preferences';
  static const String profileSecurity = '/profile/security';
  static const String profilePrivacy = '/profile/privacy';

  // ========== RUTAS DE PLANES FINANCIEROS ==========
  static const String financialPlans = '/plans';
  static const String createPlan = '/plans/create';
  static const String editPlan = '/plans/edit';
  static const String planDetails = '/plans/details';
  static const String planProgress = '/plans/progress';

  // ========== RUTAS DE TRANSACCIONES ==========
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String addIncome = '/transactions/income';
  static const String addExpense = '/transactions/expense';
  static const String editTransaction = '/transactions/edit';
  static const String transactionDetails = '/transactions/details';
  static const String transactionHistory = '/transactions/history';

  // ========== RUTAS DE ANÁLISIS IA ==========
  static const String aiAnalysis = '/analysis';
  static const String aiInsights = '/analysis/insights';
  static const String aiRecommendations = '/analysis/recommendations';
  static const String aiPatterns = '/analysis/patterns';
  static const String aiPredictions = '/analysis/predictions';

  // ========== RUTAS DE REPORTES ==========
  static const String reports = '/reports';
  static const String monthlyReports = '/reports/monthly';
  static const String yearlyReports = '/reports/yearly';
  static const String customReports = '/reports/custom';
  static const String reportDetails = '/reports/details';
  static const String exportReport = '/reports/export';

  // ========== RUTAS DE CONFIGURACIÓN ==========
  static const String settings = '/settings';
  static const String settingsGeneral = '/settings/general';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsCurrency = '/settings/currency';
  static const String settingsLanguage = '/settings/language';
  static const String settingsBackup = '/settings/backup';

  // ========== RUTAS DE AYUDA Y SOPORTE ==========
  static const String help = '/help';
  static const String support = '/support';
  static const String about = '/about';
  static const String terms = '/terms';
  static const String privacy = '/privacy-policy';
  static const String contact = '/contact';
  static const String faq = '/faq';
  static const String tutorial = '/tutorial';

  // ========== RUTAS DE CATEGORÍAS ==========
  static const String categories = '/categories';
  static const String createCategory = '/categories/create';
  static const String editCategory = '/categories/edit';
  static const String categoryDetails = '/categories/details';

  // ========== RUTAS DE BÚSQUEDA Y FILTROS ==========
  static const String search = '/search';
  static const String searchTransactions = '/search/transactions';
  static const String searchPlans = '/search/plans';
  static const String filters = '/filters';

  // ========== RUTAS DE NOTIFICACIONES ==========
  static const String notifications = '/notifications';
  static const String notificationDetails = '/notifications/details';
  static const String notificationSettings = '/notifications/settings';

  // ========== RUTAS DE IMPORT/EXPORT ==========
  static const String importData = '/import';
  static const String exportData = '/export';
  static const String backupRestore = '/backup-restore';

  // ========== RUTAS DE ONBOARDING ==========
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String setupProfile = '/setup-profile';
  static const String setupCategories = '/setup-categories';
  static const String setupGoals = '/setup-goals';

  // ========== MÉTODOS ÚTILES ==========

  /// Verifica si una ruta es de autenticación
  static bool isAuthRoute(String route) {
    return [
      splash,
      login,
      register,
      forgotPassword,
      resetPassword,
      onboarding,
      welcome,
    ].contains(route);
  }

  /// Verifica si una ruta requiere autenticación
  static bool requiresAuth(String route) {
    return !isAuthRoute(route);
  }

  /// Obtiene la ruta principal de una ruta anidada
  static String getMainRoute(String route) {
    if (route.startsWith('/home/')) return home;
    if (route.startsWith('/profile/')) return profile;
    if (route.startsWith('/plans/')) return financialPlans;
    if (route.startsWith('/transactions/')) return transactions;
    if (route.startsWith('/analysis/')) return aiAnalysis;
    if (route.startsWith('/reports/')) return reports;
    if (route.startsWith('/settings/')) return settings;
    return route;
  }

  /// Lista de rutas principales para la navegación
  static const List<String> mainRoutes = [
    homeTab,
    planesTab,
    analysisTab, // Centro - Análisis IA
    transactionsTab,
    reportsTab,
  ];

  /// Obtiene el índice de una ruta principal para la navegación
  static int getMainRouteIndex(String route) {
    return mainRoutes.indexOf(route);
  }

  /// Verifica si es una ruta de tab principal
  static bool isMainTabRoute(String route) {
    return mainRoutes.contains(route);
  }
}
