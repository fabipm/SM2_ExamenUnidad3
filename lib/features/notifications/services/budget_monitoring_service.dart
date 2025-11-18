import '../models/notification_model.dart';
import '../constants/notification_constants.dart';
import '../services/notification_service.dart';
import '../../financial_plans/models/financial_plan_model.dart';

/// Servicio para monitorear presupuestos y generar notificaciones automáticas
class BudgetMonitoringService {
  static final BudgetMonitoringService _instance = BudgetMonitoringService._internal();
  factory BudgetMonitoringService() => _instance;
  BudgetMonitoringService._internal();

  final NotificationService _notificationService = NotificationService();

  /// Verificar presupuestos y crear notificaciones cuando sea necesario
  Future<void> checkBudgetThresholds({
    required String userId,
    required FinancialPlanModel plan,
    required String categoryId,
    required double newSpentAmount,
  }) async {
    try {
      // Buscar el presupuesto de la categoría específica
      final categoryBudget = plan.categoryBudgets.firstWhere(
        (budget) => budget.categoryId == categoryId,
        orElse: () => throw Exception('Categoría no encontrada en el plan'),
      );

      // Crear una copia actualizada con el nuevo monto gastado
      final updatedBudget = categoryBudget.copyWith(spentAmount: newSpentAmount);
      final percentage = updatedBudget.usagePercentage;

      print('Verificando presupuesto: ${categoryBudget.categoryName}');
      print('Monto gastado: ${newSpentAmount} / ${categoryBudget.budgetAmount}');
      print('Porcentaje: ${percentage.toStringAsFixed(1)}%');

      // Verificar umbral del 80%
      await _checkWarning80Threshold(
        userId: userId,
        plan: plan,
        categoryBudget: updatedBudget,
        percentage: percentage,
      );

      // Verificar umbral del 100%
      await _checkExceeded100Threshold(
        userId: userId,
        plan: plan,
        categoryBudget: updatedBudget,
        percentage: percentage,
      );

      // Verificar si se excedió el presupuesto
      await _checkOverspentThreshold(
        userId: userId,
        plan: plan,
        categoryBudget: updatedBudget,
        percentage: percentage,
      );
    } catch (e) {
      print('Error al verificar umbrales de presupuesto: $e');
    }
  }

  /// Verificar y crear notificación de alerta al 80%
  Future<void> _checkWarning80Threshold({
    required String userId,
    required FinancialPlanModel plan,
    required CategoryBudget categoryBudget,
    required double percentage,
  }) async {
    // Solo crear notificación si se alcanza exactamente el 80% o si se cruza este umbral
    if (percentage >= NotificationConstants.warningThreshold && percentage < NotificationConstants.exceededThreshold) {
      final notification = NotificationModel(
        id: '', // Se asignará automáticamente
        userId: userId,
        planId: plan.id,
        categoryId: categoryBudget.categoryId,
        categoryName: categoryBudget.categoryName,
        type: NotificationType.budgetWarning80,
        title: NotificationConstants.warning80Title,
        message: NotificationConstants.getWarning80Message(
          categoryBudget.categoryName,
          categoryBudget.spentAmount,
          categoryBudget.budgetAmount,
        ),
        currentAmount: categoryBudget.spentAmount,
        budgetAmount: categoryBudget.budgetAmount,
        percentage: percentage,
        createdAt: DateTime.now(),
      );

      await _notificationService.createNotification(notification);
      print('Notificación de alerta 80% creada para ${categoryBudget.categoryName}');
    }
  }

  /// Verificar y crear notificación al alcanzar el 100%
  Future<void> _checkExceeded100Threshold({
    required String userId,
    required FinancialPlanModel plan,
    required CategoryBudget categoryBudget,
    required double percentage,
  }) async {
    // Solo crear notificación si se alcanza exactamente el 100%
    if (percentage >= NotificationConstants.exceededThreshold && !categoryBudget.isOverBudget) {
      final notification = NotificationModel(
        id: '', // Se asignará automáticamente
        userId: userId,
        planId: plan.id,
        categoryId: categoryBudget.categoryId,
        categoryName: categoryBudget.categoryName,
        type: NotificationType.budgetExceeded100,
        title: NotificationConstants.exceeded100Title,
        message: NotificationConstants.getExceeded100Message(
          categoryBudget.categoryName,
          categoryBudget.budgetAmount,
        ),
        currentAmount: categoryBudget.spentAmount,
        budgetAmount: categoryBudget.budgetAmount,
        percentage: percentage,
        createdAt: DateTime.now(),
      );

      await _notificationService.createNotification(notification);
      print('Notificación de presupuesto alcanzado creada para ${categoryBudget.categoryName}');
    }
  }

  /// Verificar y crear notificación cuando se excede el presupuesto
  Future<void> _checkOverspentThreshold({
    required String userId,
    required FinancialPlanModel plan,
    required CategoryBudget categoryBudget,
    required double percentage,
  }) async {
    // Solo crear notificación si se excede el presupuesto
    if (categoryBudget.isOverBudget && percentage > NotificationConstants.exceededThreshold) {
      final notification = NotificationModel(
        id: '', // Se asignará automáticamente
        userId: userId,
        planId: plan.id,
        categoryId: categoryBudget.categoryId,
        categoryName: categoryBudget.categoryName,
        type: NotificationType.budgetOverspent,
        title: NotificationConstants.overspentTitle,
        message: NotificationConstants.getOverspentMessage(
          categoryBudget.categoryName,
          categoryBudget.spentAmount,
          categoryBudget.budgetAmount,
        ),
        currentAmount: categoryBudget.spentAmount,
        budgetAmount: categoryBudget.budgetAmount,
        percentage: percentage,
        createdAt: DateTime.now(),
      );

      await _notificationService.createNotification(notification);
      print('Notificación de presupuesto excedido creada para ${categoryBudget.categoryName}');
    }
  }

  /// Verificar presupuestos de todo un plan financiero
  Future<void> checkAllCategoriesInPlan({
    required String userId,
    required FinancialPlanModel plan,
  }) async {
    for (final categoryBudget in plan.categoryBudgets) {
      await checkBudgetThresholds(
        userId: userId,
        plan: plan,
        categoryId: categoryBudget.categoryId,
        newSpentAmount: categoryBudget.spentAmount,
      );
    }
  }

  /// Verificar si debe crear notificación basado en cambio de monto
  bool shouldCreateNotification({
    required double oldAmount,
    required double newAmount,
    required double budgetAmount,
    required NotificationType type,
  }) {
    final oldPercentage = (oldAmount / budgetAmount) * 100;
    final newPercentage = (newAmount / budgetAmount) * 100;

    switch (type) {
      case NotificationType.budgetWarning80:
        // Crear si cruza el umbral del 80%
        return oldPercentage < NotificationConstants.warningThreshold &&
            newPercentage >= NotificationConstants.warningThreshold;

      case NotificationType.budgetExceeded100:
        // Crear si cruza el umbral del 100%
        return oldPercentage < NotificationConstants.exceededThreshold &&
            newPercentage >= NotificationConstants.exceededThreshold;

      case NotificationType.budgetOverspent:
        // Crear si se excede por primera vez
        return oldAmount <= budgetAmount && newAmount > budgetAmount;
    }
  }

  /// Método helper para crear notificación personalizada
  Future<void> createCustomBudgetNotification({
    required String userId,
    required String planId,
    required String categoryId,
    required String categoryName,
    required NotificationType type,
    required double currentAmount,
    required double budgetAmount,
  }) async {
    final percentage = (currentAmount / budgetAmount) * 100;

    String title;
    String message;

    switch (type) {
      case NotificationType.budgetWarning80:
        title = NotificationConstants.warning80Title;
        message = NotificationConstants.getWarning80Message(
          categoryName,
          currentAmount,
          budgetAmount,
        );
        break;
      case NotificationType.budgetExceeded100:
        title = NotificationConstants.exceeded100Title;
        message = NotificationConstants.getExceeded100Message(
          categoryName,
          budgetAmount,
        );
        break;
      case NotificationType.budgetOverspent:
        title = NotificationConstants.overspentTitle;
        message = NotificationConstants.getOverspentMessage(
          categoryName,
          currentAmount,
          budgetAmount,
        );
        break;
    }

    final notification = NotificationModel(
      id: '',
      userId: userId,
      planId: planId,
      categoryId: categoryId,
      categoryName: categoryName,
      type: type,
      title: title,
      message: message,
      currentAmount: currentAmount,
      budgetAmount: budgetAmount,
      percentage: percentage,
      createdAt: DateTime.now(),
    );

    await _notificationService.createNotification(notification);
  }
}