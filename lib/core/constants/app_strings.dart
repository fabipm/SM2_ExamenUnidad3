/// Strings centralizados para VanguardMoney
/// Facilita la internacionalización y mantenimiento
class AppStrings {
  // ========== APP GENERAL ==========
  static const String appName = 'VanguardMoney';
  static const String appTagline = 'Tu aliado financiero inteligente';
  static const String appDescription =
      'Gestiona tus finanzas con análisis inteligente';

  // ========== NAVEGACIÓN ==========
  static const String navHome = 'Inicio';
  static const String navPlanes = 'Planes';
  static const String navAnalysisIA = 'Análisis IA';
  static const String navTransactions = 'Agregar';
  static const String navReports = 'Reportes';

  // ========== AUTENTICACIÓN ==========
  static const String loginTitle = 'Iniciar Sesión';
  static const String loginSubtitle = 'Ingresa a tu cuenta VanguardMoney';
  static const String registerTitle = 'Crear Cuenta';
  static const String registerSubtitle = 'Únete a VanguardMoney';

  // Campos de formulario
  static const String emailLabel = 'Correo electrónico';
  static const String emailHint = 'ejemplo@correo.com';
  static const String passwordLabel = 'Contraseña';
  static const String passwordHint = 'Ingresa tu contraseña';
  static const String confirmPasswordLabel = 'Confirmar contraseña';
  static const String nameLabel = 'Nombre completo';
  static const String nameHint = 'Tu nombre';

  // Botones y acciones
  static const String loginButton = 'Iniciar Sesión';
  static const String registerButton = 'Crear Cuenta';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String noAccount = '¿No tienes cuenta?';
  static const String hasAccount = '¿Ya tienes cuenta?';
  static const String createAccount = 'Crear cuenta';
  static const String signInHere = 'Inicia sesión aquí';
  static const String continueWithGoogle = 'Continuar con Google';
  static const String registerWithGoogle = 'Registrarse con Google';
  static const String featureInDevelopment = 'Función en desarrollo';
  static const String logout = 'Cerrar Sesión';

  // ========== DASHBOARD / HOME ==========
  static const String welcomeBack = 'Bienvenido de vuelta';
  static const String totalBalance = 'Balance Total';
  static const String monthlyIncome = 'Ingresos del Mes';
  static const String monthlyExpenses = 'Gastos del Mes';
  static const String recentTransactions = 'Transacciones Recientes';
  static const String viewAll = 'Ver Todo';
  static const String quickActions = 'Acciones Rápidas';
  static const String addIncome = 'Agregar Ingreso';
  static const String addExpense = 'Agregar Gasto';
  static const String viewReports = 'Ver Reportes';

  // ========== TRANSACCIONES ==========
  static const String transactions = 'Transacciones';
  static const String addTransaction = 'Agregar Transacción';
  static const String income = 'Ingreso';
  static const String expense = 'Gasto';
  static const String amount = 'Monto';
  static const String description = 'Descripción';
  static const String category = 'Categoría';
  static const String date = 'Fecha';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String edit = 'Editar';
  static const String delete = 'Eliminar';

  // Categorías predefinidas
  static const String categoryFood = 'Alimentación';
  static const String categoryTransport = 'Transporte';
  static const String categoryEntertainment = 'Entretenimiento';
  static const String categoryEducation = 'Educación';
  static const String categoryHealth = 'Salud';
  static const String categoryOther = 'Otros';
  static const String categorySalary = 'Salario';
  static const String categoryFreelance = 'Freelance';
  static const String categoryInvestments = 'Inversiones';

  // ========== PLANES FINANCIEROS ==========
  static const String financialPlans = 'Planes Financieros';
  static const String createPlan = 'Crear Plan';
  static const String editPlan = 'Editar Plan';
  static const String planName = 'Nombre del Plan';
  static const String targetAmount = 'Monto Objetivo';
  static const String currentAmount = 'Monto Actual';
  static const String targetDate = 'Fecha Objetivo';
  static const String progress = 'Progreso';
  static const String completed = 'Completado';
  static const String inProgress = 'En Progreso';
  static const String paused = 'Pausado';

  // ========== ANÁLISIS IA ==========
  static const String aiAnalysisTitle = 'Análisis Inteligente';
  static const String aiAnalysisSubtitle =
      'Descubre insights sobre tus finanzas';
  static const String aiGenerating = 'Generando análisis...';
  static const String aiNoData = 'No hay suficientes datos para el análisis';
  static const String aiInsights = 'Insights Financieros';
  static const String aiRecommendations = 'Recomendaciones';
  static const String aiSpendingPatterns = 'Patrones de Gasto';
  static const String aiSavingsSuggestions = 'Sugerencias de Ahorro';
  static const String generateAnalysis = 'Generar Análisis';
  static const String refreshAnalysis = 'Actualizar Análisis';

  // ========== REPORTES ==========
  static const String reports = 'Reportes';
  static const String monthlyReport = 'Reporte Mensual';
  static const String yearlyReport = 'Reporte Anual';
  static const String customReport = 'Reporte Personalizado';
  static const String incomeVsExpenses = 'Ingresos vs Gastos';
  static const String categoryBreakdown = 'Desglose por Categoría';
  static const String trends = 'Tendencias';
  static const String export = 'Exportar';
  static const String share = 'Compartir';

  // ========== PERFIL ==========
  static const String profile = 'Perfil';
  static const String editProfile = 'Editar Perfil';
  static const String personalInfo = 'Información Personal';
  static const String settings = 'Configuración';
  static const String preferences = 'Preferencias';
  static const String notifications = 'Notificaciones';
  static const String security = 'Seguridad';
  static const String privacy = 'Privacidad';
  static const String about = 'Acerca de';
  static const String version = 'Versión';
  static const String support = 'Soporte';
  static const String contactUs = 'Contáctanos';

  // ========== MENSAJES DE ÉXITO ==========
  static const String successLogin = 'Bienvenido a VanguardMoney';
  static const String successRegister = 'Cuenta creada exitosamente';
  static const String successLogout = 'Sesión cerrada correctamente';
  static const String successSave = 'Guardado exitosamente';
  static const String successUpdate = 'Actualizado correctamente';
  static const String successDelete = 'Eliminado exitosamente';
  static const String successTransaction = 'Transacción registrada';

  // ========== MENSAJES DE ERROR ==========
  static const String errorLoadingProfile = 'Error al cargar el perfil';
  static const String errorTryAgain = 'Por favor, intenta nuevamente';
  static const String successPlan = 'Plan financiero creado';

  // ========== MENSAJES DE ERROR ==========
  static const String errorGeneral =
      'Ha ocurrido un error. Intenta nuevamente.';
  static const String errorNetwork = 'Sin conexión a internet';
  static const String errorAuth = 'Credenciales incorrectas';
  static const String errorTimeout = 'Tiempo de espera agotado';
  static const String errorPermissions = 'Permisos insuficientes';
  static const String errorNotFound = 'Recurso no encontrado';
  static const String errorServerError = 'Error del servidor';
  static const String errorInvalidData = 'Datos inválidos';
  static const String errorEmailInUse = 'Este correo ya está registrado';
  static const String errorWeakPassword = 'La contraseña es muy débil';
  static const String errorUserNotFound = 'Usuario no encontrado';
  static const String errorWrongPassword = 'Contraseña incorrecta';
  static const String errorTooManyRequests =
      'Demasiados intentos. Intenta más tarde';

  // ========== VALIDACIONES ==========
  static const String validationRequired = 'Este campo es requerido';
  static const String validationEmailInvalid = 'Correo electrónico inválido';
  static const String validationPasswordShort =
      'La contraseña debe tener al menos 6 caracteres';
  static const String validationPasswordMismatch =
      'Las contraseñas no coinciden';
  static const String validationAmountInvalid = 'Monto inválido';
  static const String validationAmountPositive = 'El monto debe ser positivo';
  static const String validationDateInvalid = 'Fecha inválida';
  static const String validationNameTooShort = 'El nombre es muy corto';

  // ========== ACCIONES GENERALES ==========
  static const String ok = 'OK';
  static const String yes = 'Sí';
  static const String no = 'No';
  static const String confirm = 'Confirmar';
  static const String close = 'Cerrar';
  static const String back = 'Atrás';
  static const String next = 'Siguiente';
  static const String finish = 'Finalizar';
  static const String skip = 'Omitir';
  static const String retry = 'Reintentar';
  static const String refresh = 'Actualizar';
  static const String loading = 'Cargando...';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';
  static const String sort = 'Ordenar';
  static const String clear = 'Limpiar';
  static const String apply = 'Aplicar';
  static const String reset = 'Restablecer';

  // ========== ESTADOS VACÍOS ==========
  static const String noTransactions = 'No hay transacciones registradas';
  static const String noPlans = 'No tienes planes financieros';
  static const String noReports = 'No hay reportes disponibles';
  static const String noData = 'No hay datos disponibles';
  static const String emptySearch = 'No se encontraron resultados';

  // ========== CONFIRMACIONES ==========
  static const String confirmDelete = '¿Estás seguro de que deseas eliminar?';
  static const String confirmLogout = '¿Deseas cerrar sesión?';
  static const String confirmCancel = '¿Deseas cancelar los cambios?';
  static const String deleteTransaction = 'Eliminar Transacción';
  static const String deletePlan = 'Eliminar Plan';

  // ========== TIEMPO ==========
  static const String today = 'Hoy';
  static const String yesterday = 'Ayer';
  static const String thisWeek = 'Esta Semana';
  static const String thisMonth = 'Este Mes';
  static const String thisYear = 'Este Año';
  static const String lastMonth = 'Mes Anterior';
  static const String lastYear = 'Año Anterior';

  // ========== MONEDAS ==========
  static const String currency = 'Moneda';
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';
}
