/// Modelo para estadísticas por categoría en el dashboard
class CategoryStats {
  final String categoryId;
  final String categoryName;
  final double amount;
  final int transactionCount;
  final String tipo; // 'ingreso' o 'gasto'

  const CategoryStats({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.transactionCount,
    required this.tipo,
  });

  /// Porcentaje respecto al total (será calculado externamente)
  double calculatePercentage(double total) {
    if (total <= 0) return 0.0;
    return ((amount / total) * 100).clamp(0.0, 100.0);
  }
}

/// Resumen mensual de ingresos y gastos
class MonthlyStats {
  final int year;
  final int month;
  final double totalIngresos;
  final double totalGastos;
  final double balance;
  final int cantidadTransacciones;

  const MonthlyStats({
    required this.year,
    required this.month,
    required this.totalIngresos,
    required this.totalGastos,
    required this.balance,
    required this.cantidadTransacciones,
  });

  /// Balance positivo o negativo
  bool get isPositive => balance >= 0;

  /// Porcentaje de ahorro respecto a ingresos
  double get savingsPercentage {
    if (totalIngresos <= 0) return 0.0;
    return ((balance / totalIngresos) * 100).clamp(-100.0, 100.0);
  }

  /// Ratio de gastos vs ingresos (0-100+)
  double get spendingRatio {
    if (totalIngresos <= 0) return 0.0;
    return (totalGastos / totalIngresos) * 100;
  }
}

/// Resumen de un plan financiero para el dashboard
class PlanSummary {
  final String planId;
  final String planName;
  final double totalBudget;
  final double totalSpent;
  final int month;
  final int year;
  final bool isActive;
  final int categoriesCount;

  const PlanSummary({
    required this.planId,
    required this.planName,
    required this.totalBudget,
    required this.totalSpent,
    required this.month,
    required this.year,
    required this.isActive,
    required this.categoriesCount,
  });

  /// Porcentaje utilizado del presupuesto
  double get usagePercentage {
    if (totalBudget <= 0) return 0.0;
    return ((totalSpent / totalBudget) * 100).clamp(0.0, 100.0);
  }

  /// Monto restante
  double get remainingAmount => (totalBudget - totalSpent).clamp(0.0, totalBudget);

  /// Si está sobre presupuesto
  bool get isOverBudget => totalSpent > totalBudget;

  /// Estado del plan basado en el porcentaje usado
  PlanStatus get status {
    if (isOverBudget) return PlanStatus.exceeded;
    if (usagePercentage >= 90) return PlanStatus.warning;
    if (usagePercentage >= 70) return PlanStatus.caution;
    return PlanStatus.healthy;
  }
}

/// Estados del plan financiero
enum PlanStatus {
  healthy,   // < 70% usado
  caution,   // 70-89% usado
  warning,   // 90-99% usado
  exceeded,  // >= 100% usado
}

/// Modelo principal del Dashboard con todas las estadísticas
class DashboardStatsModel {
  final MonthlyStats monthlyStats;
  final List<CategoryStats> gastosPorCategoria;
  final List<CategoryStats> ingresosPorCategoria;
  final List<PlanSummary> planesActivos;
  final DateTime lastUpdated;

  const DashboardStatsModel({
    required this.monthlyStats,
    required this.gastosPorCategoria,
    required this.ingresosPorCategoria,
    required this.planesActivos,
    required this.lastUpdated,
  });

  /// Total de categorías con gastos
  int get totalCategoriesWithExpenses => gastosPorCategoria.length;

  /// Categoría con mayor gasto
  CategoryStats? get topExpenseCategory {
    if (gastosPorCategoria.isEmpty) return null;
    return gastosPorCategoria.reduce(
      (curr, next) => curr.amount > next.amount ? curr : next,
    );
  }

  /// Total de planes activos
  int get activePlansCount => planesActivos.where((p) => p.isActive).length;

  /// Planes en estado de alerta (warning o exceeded)
  int get alertPlansCount => planesActivos
      .where((p) => p.status == PlanStatus.warning || p.status == PlanStatus.exceeded)
      .length;
}
