/// Modelo para representar un análisis financiero completo
class FinancialAnalysisModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final AnalysisPeriod period;
  final FinancialSummary summary;
  final List<CategoryInsight> categoryInsights;
  final List<SpendingPattern> patterns;
  final List<AIRecommendation> recommendations;
  final String? aiGeneratedText; // Texto completo generado por IA

  FinancialAnalysisModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.period,
    required this.summary,
    required this.categoryInsights,
    required this.patterns,
    required this.recommendations,
    this.aiGeneratedText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'period': period.toMap(),
      'summary': summary.toMap(),
      'categoryInsights': categoryInsights.map((x) => x.toMap()).toList(),
      'patterns': patterns.map((x) => x.toMap()).toList(),
      'recommendations': recommendations.map((x) => x.toMap()).toList(),
      'aiGeneratedText': aiGeneratedText,
    };
  }

  factory FinancialAnalysisModel.fromMap(Map<String, dynamic> map) {
    return FinancialAnalysisModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      period: AnalysisPeriod.fromMap(map['period']),
      summary: FinancialSummary.fromMap(map['summary']),
      categoryInsights: List<CategoryInsight>.from(
        map['categoryInsights']?.map((x) => CategoryInsight.fromMap(x)) ?? [],
      ),
      patterns: List<SpendingPattern>.from(
        map['patterns']?.map((x) => SpendingPattern.fromMap(x)) ?? [],
      ),
      recommendations: List<AIRecommendation>.from(
        map['recommendations']?.map((x) => AIRecommendation.fromMap(x)) ?? [],
      ),
      aiGeneratedText: map['aiGeneratedText'],
    );
  }
}

/// Período del análisis
class AnalysisPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final PeriodType type; // mensual, trimestral, anual, personalizado

  AnalysisPeriod({
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  String get label {
    switch (type) {
      case PeriodType.monthly:
        return 'Mensual - ${_monthName(startDate.month)} ${startDate.year}';
      case PeriodType.quarterly:
        return 'Trimestral - Q${(startDate.month - 1) ~/ 3 + 1} ${startDate.year}';
      case PeriodType.yearly:
        return 'Anual - ${startDate.year}';
      case PeriodType.custom:
        return 'Personalizado - ${_formatDate(startDate)} a ${_formatDate(endDate)}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.toString(),
    };
  }

  factory AnalysisPeriod.fromMap(Map<String, dynamic> map) {
    return AnalysisPeriod(
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      type: PeriodType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => PeriodType.monthly,
      ),
    );
  }

  /// Crear período mensual
  factory AnalysisPeriod.monthly(int year, int month) {
    final start = DateTime(year, month, 1);
    // incluir hasta el último milisegundo del último día
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return AnalysisPeriod(
      startDate: start,
      endDate: end,
      type: PeriodType.monthly,
    );
  }

  /// Crear período trimestral
  factory AnalysisPeriod.quarterly(int year, int quarter) {
    final startMonth = (quarter - 1) * 3 + 1;
    final start = DateTime(year, startMonth, 1);
    final end = DateTime(year, startMonth + 3, 0, 23, 59, 59, 999);
    return AnalysisPeriod(
      startDate: start,
      endDate: end,
      type: PeriodType.quarterly,
    );
  }

  /// Crear período anual
  factory AnalysisPeriod.yearly(int year) {
    return AnalysisPeriod(
      startDate: DateTime(year, 1, 1),
      endDate: DateTime(year, 12, 31, 23, 59, 59, 999),
      type: PeriodType.yearly,
    );
  }
}

enum PeriodType { monthly, quarterly, yearly, custom }

/// Resumen financiero del período
class FinancialSummary {
  final double totalIncome; // Total de ingresos
  final double totalExpenses; // Total de gastos
  final double balance; // Balance (ingresos - gastos)
  final double savingsRate; // Tasa de ahorro (%)
  final int transactionCount; // Número de transacciones
  final double averageExpense; // Gasto promedio
  final double largestExpense; // Gasto más grande
  final String largestExpenseCategory; // Categoría del gasto más grande

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.savingsRate,
    required this.transactionCount,
    required this.averageExpense,
    required this.largestExpense,
    required this.largestExpenseCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': balance,
      'savingsRate': savingsRate,
      'transactionCount': transactionCount,
      'averageExpense': averageExpense,
      'largestExpense': largestExpense,
      'largestExpenseCategory': largestExpenseCategory,
    };
  }

  factory FinancialSummary.fromMap(Map<String, dynamic> map) {
    return FinancialSummary(
      totalIncome: (map['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (map['totalExpenses'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      savingsRate: (map['savingsRate'] ?? 0).toDouble(),
      transactionCount: map['transactionCount'] ?? 0,
      averageExpense: (map['averageExpense'] ?? 0).toDouble(),
      largestExpense: (map['largestExpense'] ?? 0).toDouble(),
      largestExpenseCategory: map['largestExpenseCategory'] ?? '',
    );
  }
}

/// Insight de una categoría específica
class CategoryInsight {
  final String categoryId;
  final String categoryName;
  final double totalAmount;
  final double percentage; // Porcentaje del total de gastos
  final int transactionCount;
  final double averageTransaction;
  final TrendType trend; // subiendo, bajando, estable
  final double changePercentage; // Cambio vs período anterior

  CategoryInsight({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
    required this.averageTransaction,
    required this.trend,
    required this.changePercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'totalAmount': totalAmount,
      'percentage': percentage,
      'transactionCount': transactionCount,
      'averageTransaction': averageTransaction,
      'trend': trend.toString(),
      'changePercentage': changePercentage,
    };
  }

  factory CategoryInsight.fromMap(Map<String, dynamic> map) {
    return CategoryInsight(
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      transactionCount: map['transactionCount'] ?? 0,
      averageTransaction: (map['averageTransaction'] ?? 0).toDouble(),
      trend: TrendType.values.firstWhere(
        (e) => e.toString() == map['trend'],
        orElse: () => TrendType.stable,
      ),
      changePercentage: (map['changePercentage'] ?? 0).toDouble(),
    );
  }
}

enum TrendType { increasing, decreasing, stable }

/// Patrón de gasto detectado
class SpendingPattern {
  final String id;
  final PatternType type;
  final String title;
  final String description;
  final String category;
  final double impact; // Impacto económico
  final SeverityLevel severity;

  SpendingPattern({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.impact,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'description': description,
      'category': category,
      'impact': impact,
      'severity': severity.toString(),
    };
  }

  factory SpendingPattern.fromMap(Map<String, dynamic> map) {
    return SpendingPattern(
      id: map['id'] ?? '',
      type: PatternType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => PatternType.unusual,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      impact: (map['impact'] ?? 0).toDouble(),
      severity: SeverityLevel.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => SeverityLevel.low,
      ),
    );
  }
}

enum PatternType {
  recurring, // Gastos recurrentes
  seasonal, // Gastos estacionales
  unusual, // Gastos inusuales/atípicos
  increasing, // Tendencia creciente
  decreasing, // Tendencia decreciente
}

enum SeverityLevel { low, medium, high, critical }

/// Recomendación generada por IA
class AIRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final String category; // Categoría afectada
  final double potentialSavings; // Ahorro potencial
  final PriorityLevel priority;
  final List<String> actionSteps; // Pasos de acción

  AIRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.potentialSavings,
    required this.priority,
    required this.actionSteps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'category': category,
      'potentialSavings': potentialSavings,
      'priority': priority.toString(),
      'actionSteps': actionSteps,
    };
  }

  factory AIRecommendation.fromMap(Map<String, dynamic> map) {
    return AIRecommendation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => RecommendationType.reduce,
      ),
      category: map['category'] ?? '',
      potentialSavings: (map['potentialSavings'] ?? 0).toDouble(),
      priority: PriorityLevel.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => PriorityLevel.medium,
      ),
      actionSteps: List<String>.from(map['actionSteps'] ?? []),
    );
  }
}

enum RecommendationType {
  reduce, // Reducir gasto
  optimize, // Optimizar gasto
  budget, // Crear presupuesto
  save, // Aumentar ahorro
  alert, // Alerta de gasto
}

enum PriorityLevel { low, medium, high, urgent }
