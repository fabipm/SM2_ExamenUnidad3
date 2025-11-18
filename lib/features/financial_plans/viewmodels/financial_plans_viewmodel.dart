import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_plan_model.dart';
import '../services/financial_plans_service.dart';
import '../../transactions/models/categoria_model.dart';
import '../../transactions/services/categoria_service.dart';
import '../../auth/providers/auth_providers.dart';

/// Estados para el ViewModel de planes financieros
sealed class FinancialPlansState {
  const FinancialPlansState();
}

class FinancialPlansInitial extends FinancialPlansState {
  const FinancialPlansInitial();
}

class FinancialPlansLoading extends FinancialPlansState {
  const FinancialPlansLoading();
}

class FinancialPlansLoaded extends FinancialPlansState {
  final List<FinancialPlanModel> plans;
  final FinancialPlanModel? currentPlan;
  const FinancialPlansLoaded(this.plans, {this.currentPlan});
}

class FinancialPlansError extends FinancialPlansState {
  final String message;
  const FinancialPlansError(this.message);
}

/// Provider para el servicio de planes financieros
final financialPlansServiceProvider = Provider<FinancialPlansService>((ref) {
  return FinancialPlansService();
});

/// Provider para el servicio de categorías
final categoriaServiceProvider = Provider<CategoriaService>((ref) {
  return CategoriaService();
});

/// ViewModel principal para planes financieros
class FinancialPlansViewModel extends AsyncNotifier<FinancialPlansState> {
  late FinancialPlansService _financialPlansService;
  late CategoriaService _categoriaService;

  @override
  Future<FinancialPlansState> build() async {
    _financialPlansService = ref.read(financialPlansServiceProvider);
    _categoriaService = ref.read(categoriaServiceProvider);

    return const FinancialPlansInitial();
  }

  /// Cargar planes financieros del usuario
  Future<void> loadFinancialPlans() async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        state = const AsyncValue.data(
          FinancialPlansError('Usuario no autenticado'),
        );
        return;
      }

      final plans = await _financialPlansService.getUserFinancialPlans(user.id);

      // Obtener el plan del mes actual si existe
      final now = DateTime.now();
      final currentPlan = await _financialPlansService.getPlanByMonth(
        userId: user.id,
        year: now.year,
        month: now.month,
      );

      state = AsyncValue.data(
        FinancialPlansLoaded(plans, currentPlan: currentPlan),
      );

      // Auto-sincronizar gastos reales de todos los planes en segundo plano (sin await)
      // Esto no bloquea la UI
      unawaited(_autoSyncAllPlans(user.id, plans));
    } catch (e) {
      state = AsyncValue.data(
        FinancialPlansError('Error al cargar planes: $e'),
      );
    }
  }

  /// Sincronizar automáticamente los gastos reales de todos los planes
  Future<void> _autoSyncAllPlans(String userId, List<FinancialPlanModel> plans) async {
    for (final plan in plans) {
      try {
        await _financialPlansService.syncRealExpenses(
          planId: plan.id,
          userId: userId,
          year: plan.year,
          month: plan.month,
        );
      } catch (e) {
        print('Error auto-sincronizando plan ${plan.id}: $e');
      }
    }
    // Recargar silenciosamente después de sincronizar
    try {
      final updatedPlans = await _financialPlansService.getUserFinancialPlans(userId);
      final now = DateTime.now();
      final updatedCurrentPlan = await _financialPlansService.getPlanByMonth(
        userId: userId,
        year: now.year,
        month: now.month,
      );
      state = AsyncValue.data(
        FinancialPlansLoaded(updatedPlans, currentPlan: updatedCurrentPlan),
      );
    } catch (e) {
      print('Error recargando después de auto-sync: $e');
    }
  }

  /// Obtener plan específico por mes/año
  Future<FinancialPlanModel?> getPlanByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return null;

      return await _financialPlansService.getPlanByMonth(
        userId: user.id,
        year: year,
        month: month,
      );
    } catch (e) {
      print('Error al obtener plan del mes: $e');
      return null;
    }
  }

  /// Crear un nuevo plan financiero
  Future<bool> createFinancialPlan({
    required String planName,
    required int year,
    required int month,
    required double totalBudget,
    required PlanType planType,
    List<CategoryBudget>? customBudgets,
  }) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      FinancialPlanModel newPlan;

      switch (planType) {
        case PlanType.standard:
          final categories = await _categoriaService.obtenerCategorias(
            user.id,
            TipoCategoria.egreso,
          );
          newPlan = FinancialPlanModel.createStandardPlan(
            userId: user.id,
            planName: planName,
            year: year,
            month: month,
            totalBudget: totalBudget,
            categories: categories,
          );
          break;

        case PlanType.custom:
          if (customBudgets == null || customBudgets.isEmpty) {
            throw Exception('Se requieren asignaciones personalizadas');
          }
          final now = DateTime.now();
          newPlan = FinancialPlanModel(
            id: '',
            userId: user.id,
            planName: planName,
            year: year,
            month: month,
            totalBudget: totalBudget,
            categoryBudgets: customBudgets,
            planType: planType,
            createdAt: now,
            updatedAt: now,
          );
          break;

        case PlanType.ai:
          // Para el futuro: implementación de IA
          throw Exception('Función de IA aún no implementada');
      }

      final planId = await _financialPlansService.createFinancialPlan(newPlan);
      
      // Auto-sincronizar gastos reales inmediatamente después de crear
      if (planId != null) {
        try {
          await _financialPlansService.syncRealExpenses(
            planId: planId,
            userId: user.id,
            year: year,
            month: month,
          );
        } catch (e) {
          print('Error auto-sincronizando plan recién creado: $e');
        }
      }
      
      await loadFinancialPlans(); // Recargar planes
      return true;
    } catch (e) {
      state = AsyncValue.data(FinancialPlansError('Error al crear plan: $e'));
      return false;
    }
  }

  /// Actualizar plan existente
  Future<bool> updateFinancialPlan(FinancialPlanModel plan) async {
    try {
      final success = await _financialPlansService.updateFinancialPlan(plan);
      if (success) {
        await loadFinancialPlans(); // Recargar planes
      }
      return success;
    } catch (e) {
      state = AsyncValue.data(
        FinancialPlansError('Error al actualizar plan: $e'),
      );
      return false;
    }
  }

  /// Actualizar gasto en una categoría
  Future<bool> updateCategorySpent({
    required String planId,
    required String categoryId,
    required double newSpentAmount,
  }) async {
    try {
      final success = await _financialPlansService.updateCategorySpent(
        planId: planId,
        categoryId: categoryId,
        newSpentAmount: newSpentAmount,
      );

      if (success) {
        await loadFinancialPlans(); // Recargar planes
      }
      return success;
    } catch (e) {
      print('Error al actualizar gasto de categoría: $e');
      return false;
    }
  }

  /// Eliminar plan
  Future<bool> deleteFinancialPlan(String planId) async {
    try {
      final success = await _financialPlansService.deleteFinancialPlan(planId);
      if (success) {
        await loadFinancialPlans(); // Recargar planes
      }
      return success;
    } catch (e) {
      state = AsyncValue.data(
        FinancialPlansError('Error al eliminar plan: $e'),
      );
      return false;
    }
  }

  /// Duplicar plan del mes anterior
  Future<bool> duplicatePreviousMonth({
    required int targetYear,
    required int targetMonth,
  }) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      await _financialPlansService.duplicatePreviousMonth(
        userId: user.id,
        targetYear: targetYear,
        targetMonth: targetMonth,
      );

      await loadFinancialPlans(); // Recargar planes
      return true;
    } catch (e) {
      state = AsyncValue.data(
        FinancialPlansError('Error al duplicar plan: $e'),
      );
      return false;
    }
  }

  /// Obtener categorías disponibles para crear planes
  Future<List<CategoriaModel>> getAvailableCategories() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return [];

      return await _categoriaService.obtenerCategorias(
        user.id,
        TipoCategoria.egreso,
      );
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  /// Obtener estadísticas de un plan
  Future<Map<String, dynamic>> getPlanStatistics(String planId) async {
    try {
      return await _financialPlansService.getPlanStatistics(planId);
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {};
    }
  }

  /// Sincronizar gastos reales desde las transacciones
  Future<bool> syncRealExpenses({
    required String planId,
    required int year,
    required int month,
  }) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return false;

      final success = await _financialPlansService.syncRealExpenses(
        planId: planId,
        userId: user.id,
        year: year,
        month: month,
      );

      if (success) {
        await loadFinancialPlans();
      }
      return success;
    } catch (e) {
      print('Error al sincronizar gastos: $e');
      return false;
    }
  }

  /// Generar preview de plan con IA (sin guardar)
  Future<FinancialPlanModel?> generateAIPlanPreview({
    required int targetYear,
    required int targetMonth,
    required double totalBudget,
  }) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final categories = await getAvailableCategories();
      if (categories.isEmpty) {
        throw Exception('No hay categorías disponibles');
      }

      final aiPlan = await _financialPlansService.createAIPlan(
        userId: user.id,
        targetYear: targetYear,
        targetMonth: targetMonth,
        totalBudget: totalBudget,
        categories: categories,
      );

      return aiPlan;
    } catch (e) {
      print('Error al generar preview de plan IA: $e');
      return null;
    }
  }

  /// Crear plan desde el preview aprobado
  Future<bool> createAIPlanFromPreview(FinancialPlanModel aiPlan) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final planId = await _financialPlansService.createFinancialPlan(aiPlan);
      
      // Auto-sincronizar gastos reales del plan creado con IA
      if (planId != null) {
        try {
          await _financialPlansService.syncRealExpenses(
            planId: planId,
            userId: user.id,
            year: aiPlan.year,
            month: aiPlan.month,
          );
        } catch (e) {
          print('Error auto-sincronizando plan IA: $e');
        }
      }
      
      await loadFinancialPlans();
      return true;
    } catch (e) {
      state = AsyncValue.data(
        FinancialPlansError('Error al crear plan con IA: $e'),
      );
      return false;
    }
  }

  /// Generar resumen con IA para un plan pasado
  Future<bool> generatePlanSummary(String planId) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final success = await _financialPlansService.generateAISummary(
        planId: planId,
        userId: user.id,
      );

      if (success) {
        await loadFinancialPlans();
      }
      return success;
    } catch (e) {
      print('Error al generar resumen IA: $e');
      return false;
    }
  }
}

/// Provider del ViewModel
final financialPlansViewModelProvider =
    AsyncNotifierProvider<FinancialPlansViewModel, FinancialPlansState>(
      () => FinancialPlansViewModel(),
    );

/// Provider para obtener el plan del mes actual
final currentMonthPlanProvider = FutureProvider<FinancialPlanModel?>((
  ref,
) async {
  final viewModel = ref.read(financialPlansViewModelProvider.notifier);
  final now = DateTime.now();

  return await viewModel.getPlanByMonth(year: now.year, month: now.month);
});

/// Provider para obtener categorías disponibles
final availableCategoriesProvider = FutureProvider<List<CategoriaModel>>((
  ref,
) async {
  final viewModel = ref.read(financialPlansViewModelProvider.notifier);
  return await viewModel.getAvailableCategories();
});
