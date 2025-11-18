import '../../financial_plans/services/financial_plans_service.dart';
import '../../financial_plans/models/financial_plan_model.dart';
import './budget_monitoring_service.dart';

/// Servicio de integración que combina planes financieros con monitoreo de notificaciones
class FinancialPlansWithNotificationsService {
  final FinancialPlansService _financialPlansService = FinancialPlansService();
  final BudgetMonitoringService _budgetMonitoringService = BudgetMonitoringService();

  /// Actualizar gasto en una categoría específica con monitoreo de notificaciones
  Future<bool> updateCategorySpentWithNotifications({
    required String planId,
    required String categoryId,
    required double newSpentAmount,
  }) async {
    try {
      // Primero obtener el plan actual para comparar el monto anterior
      final plan = await _getPlanById(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado');
      }

      // Obtener el monto anterior gastado
      final categoryBudget = plan.categoryBudgets.firstWhere(
        (cb) => cb.categoryId == categoryId,
        orElse: () => throw Exception('Categoría no encontrada en el plan'),
      );

      final oldSpentAmount = categoryBudget.spentAmount;

      // Actualizar el gasto usando el servicio original
      final success = await _financialPlansService.updateCategorySpent(
        planId: planId,
        categoryId: categoryId,
        newSpentAmount: newSpentAmount,
      );

      if (success) {
        // Verificar umbrales de notificación solo si el monto aumentó
        if (newSpentAmount > oldSpentAmount) {
          await _budgetMonitoringService.checkBudgetThresholds(
            userId: plan.userId,
            plan: plan,
            categoryId: categoryId,
            newSpentAmount: newSpentAmount,
          );
        }
      }

      return success;
    } catch (e) {
      print('Error al actualizar gasto con monitoreo: $e');
      return false;
    }
  }

  /// Agregar gasto a una categoría (incrementar en lugar de establecer)
  Future<bool> addExpenseToCategory({
    required String planId,
    required String categoryId,
    required double expenseAmount,
  }) async {
    try {
      // Obtener el plan actual
      final plan = await _getPlanById(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado');
      }

      // Encontrar la categoría y calcular el nuevo monto
      final categoryBudget = plan.categoryBudgets.firstWhere(
        (cb) => cb.categoryId == categoryId,
        orElse: () => throw Exception('Categoría no encontrada en el plan'),
      );

      final newSpentAmount = categoryBudget.spentAmount + expenseAmount;

      // Usar el método que incluye el monitoreo
      return await updateCategorySpentWithNotifications(
        planId: planId,
        categoryId: categoryId,
        newSpentAmount: newSpentAmount,
      );
    } catch (e) {
      print('Error al agregar gasto a categoría: $e');
      return false;
    }
  }

  /// Quitar gasto de una categoría (decrementar)
  Future<bool> removeExpenseFromCategory({
    required String planId,
    required String categoryId,
    required double expenseAmount,
  }) async {
    try {
      // Obtener el plan actual
      final plan = await _getPlanById(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado');
      }

      // Encontrar la categoría y calcular el nuevo monto
      final categoryBudget = plan.categoryBudgets.firstWhere(
        (cb) => cb.categoryId == categoryId,
        orElse: () => throw Exception('Categoría no encontrada en el plan'),
      );

      final newSpentAmount = (categoryBudget.spentAmount - expenseAmount).clamp(0.0, double.infinity);

      // Actualizar sin crear notificaciones (no verificar umbrales al reducir gastos)
      return await _financialPlansService.updateCategorySpent(
        planId: planId,
        categoryId: categoryId,
        newSpentAmount: newSpentAmount,
      );
    } catch (e) {
      print('Error al quitar gasto de categoría: $e');
      return false;
    }
  }

  /// Verificar todos los umbrales de un plan (útil para auditorías)
  Future<void> auditPlanBudgets({
    required String planId,
  }) async {
    try {
      final plan = await _getPlanById(planId);
      if (plan == null) {
        throw Exception('Plan no encontrado');
      }

      await _budgetMonitoringService.checkAllCategoriesInPlan(
        userId: plan.userId,
        plan: plan,
      );
    } catch (e) {
      print('Error al auditar presupuestos del plan: $e');
    }
  }

  /// Obtener plan actual por mes y año para el usuario
  Future<FinancialPlanModel?> getCurrentPlanForUser({
    required String userId,
    int? year,
    int? month,
  }) async {
    final currentDate = DateTime.now();
    return await _financialPlansService.getPlanByMonth(
      userId: userId,
      year: year ?? currentDate.year,
      month: month ?? currentDate.month,
    );
  }

  /// Helper para obtener plan por ID
  Future<FinancialPlanModel?> _getPlanById(String planId) async {
    return await _financialPlansService.getPlanById(planId);
  }

  /// Delegar métodos básicos al servicio original
  Future<List<FinancialPlanModel>> getUserFinancialPlans(String userId) {
    return _financialPlansService.getUserFinancialPlans(userId);
  }

  Future<FinancialPlanModel?> getPlanByMonth({
    required String userId,
    required int year,
    required int month,
  }) {
    return _financialPlansService.getPlanByMonth(
      userId: userId,
      year: year,
      month: month,
    );
  }

  Future<String?> createFinancialPlan(FinancialPlanModel plan) {
    return _financialPlansService.createFinancialPlan(plan);
  }

  Future<bool> updateFinancialPlan(FinancialPlanModel plan) {
    return _financialPlansService.updateFinancialPlan(plan);
  }

  Future<bool> deleteFinancialPlan(String planId) {
    return _financialPlansService.deleteFinancialPlan(planId);
  }
}