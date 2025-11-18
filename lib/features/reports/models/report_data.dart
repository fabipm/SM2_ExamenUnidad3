class TransactionReportData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIngresos;
  final double totalEgresos;
  final double balance;
  final Map<String, double> ingresosPorCategoria;
  final Map<String, double> egresosPorCategoria;
  final List<TransactionItem> transactions;

  TransactionReportData({
    required this.startDate,
    required this.endDate,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.balance,
    required this.ingresosPorCategoria,
    required this.egresosPorCategoria,
    required this.transactions,
  });
}

class TransactionItem {
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final double monto;
  final bool isIngreso;

  TransactionItem({
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.isIngreso,
  });
}

class PlanComplianceReportData {
  final String planName;
  final int year;
  final int month;
  final double totalBudget;
  final double totalSpent;
  final double compliancePercentage;
  final List<CategoryCompliance> categoryCompliances;

  PlanComplianceReportData({
    required this.planName,
    required this.year,
    required this.month,
    required this.totalBudget,
    required this.totalSpent,
    required this.compliancePercentage,
    required this.categoryCompliances,
  });
}

class CategoryCompliance {
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double compliancePercentage;

  CategoryCompliance({
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.compliancePercentage,
  });

  bool get isOverBudget => spentAmount > budgetAmount;
}
