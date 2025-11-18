import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/models/categoria_model.dart';

/// Asignación de presupuesto a una categoría específica
class CategoryBudget {
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final TipoCategoria categoryType;

  const CategoryBudget({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    this.spentAmount = 0.0,
    required this.categoryType,
  });

  /// Factory constructor desde Map
  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      budgetAmount: (map['budgetAmount'] ?? 0).toDouble(),
      spentAmount: (map['spentAmount'] ?? 0).toDouble(),
      categoryType: map['categoryType'] == 'ingreso'
          ? TipoCategoria.ingreso
          : TipoCategoria.egreso,
    );
  }

  /// Convierte a Map
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
      'categoryType': categoryType.toString().split('.').last,
    };
  }

  /// Porcentaje gastado (0-100)
  double get usagePercentage {
    if (budgetAmount <= 0) return 0.0;
    return ((spentAmount / budgetAmount) * 100).clamp(0.0, 100.0);
  }

  /// Monto restante
  double get remainingAmount =>
      (budgetAmount - spentAmount).clamp(0.0, budgetAmount);

  /// Si está sobre el presupuesto
  bool get isOverBudget => spentAmount > budgetAmount;

  CategoryBudget copyWith({
    String? categoryId,
    String? categoryName,
    double? budgetAmount,
    double? spentAmount,
    TipoCategoria? categoryType,
  }) {
    return CategoryBudget(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      categoryType: categoryType ?? this.categoryType,
    );
  }
}

/// Modelo principal para un plan financiero mensual
class FinancialPlanModel {
  final String id;
  final String userId;
  final String planName;
  final int year;
  final int month;
  final double totalBudget;
  final List<CategoryBudget> categoryBudgets;
  final PlanType planType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? aiSummary; // Resumen de IA sobre el resultado del plan

  const FinancialPlanModel({
    required this.id,
    required this.userId,
    required this.planName,
    required this.year,
    required this.month,
    required this.totalBudget,
    required this.categoryBudgets,
    required this.planType,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.aiSummary,
  });

  /// Factory constructor desde Map (Firestore)
  factory FinancialPlanModel.fromMap(Map<String, dynamic> map) {
    return FinancialPlanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      planName: map['planName'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      categoryBudgets:
          (map['categoryBudgets'] as List<dynamic>?)
              ?.map(
                (item) => CategoryBudget.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      planType: PlanType.values.firstWhere(
        (type) => type.name == map['planType'],
        orElse: () => PlanType.custom,
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] ?? true,
      aiSummary: map['aiSummary'],
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planName': planName,
      'year': year,
      'month': month,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets.map((cb) => cb.toMap()).toList(),
      'planType': planType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'aiSummary': aiSummary,
    };
  }

  /// Copia con nuevos valores
  FinancialPlanModel copyWith({
    String? id,
    String? userId,
    String? planName,
    int? year,
    int? month,
    double? totalBudget,
    List<CategoryBudget>? categoryBudgets,
    PlanType? planType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? aiSummary,
  }) {
    return FinancialPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planName: planName ?? this.planName,
      year: year ?? this.year,
      month: month ?? this.month,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      planType: planType ?? this.planType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  /// Nombre del mes en español
  String get monthName {
    const months = [
      '',
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
    return months[month];
  }

  /// Total gastado en todas las categorías
  double get totalSpent {
    return categoryBudgets.fold(0.0, (sum, cb) => sum + cb.spentAmount);
  }

  /// Porcentaje total usado del presupuesto
  double get totalUsagePercentage {
    if (totalBudget <= 0) return 0.0;
    return ((totalSpent / totalBudget) * 100).clamp(0.0, 100.0);
  }

  /// Monto restante del presupuesto total
  double get remainingBudget =>
      (totalBudget - totalSpent).clamp(0.0, totalBudget);

  /// Si está sobre el presupuesto total
  bool get isOverBudget => totalSpent > totalBudget;

  /// Fecha del plan (primer día del mes)
  DateTime get planDate => DateTime(year, month, 1);

  /// Si el plan es del mes actual
  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Crear un plan estándar (distribución equitativa)
  static FinancialPlanModel createStandardPlan({
    required String userId,
    required String planName,
    required int year,
    required int month,
    required double totalBudget,
    required List<CategoriaModel> categories,
  }) {
    final now = DateTime.now();
    final budgetPerCategory = categories.isNotEmpty
        ? totalBudget / categories.length
        : 0.0;

    final categoryBudgets = categories
        .map(
          (category) => CategoryBudget(
            categoryId: category.id,
            categoryName: category.nombre,
            budgetAmount: budgetPerCategory,
            spentAmount: 0.0,
            categoryType: category.tipo,
          ),
        )
        .toList();

    return FinancialPlanModel(
      id: '', // Se asignará al guardar en Firestore
      userId: userId,
      planName: planName,
      year: year,
      month: month,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      planType: PlanType.standard,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  /// Crear un plan básico (categorías esenciales)
  static FinancialPlanModel createBasicPlan({
    required String userId,
    required String planName,
    required int year,
    required int month,
    required double totalBudget,
  }) {
    final now = DateTime.now();

    // Distribución básica: 50% vivienda, 25% alimentación, 15% transporte, 10% otros
    final categoryBudgets = [
      CategoryBudget(
        categoryId: 'vivienda',
        categoryName: 'Vivienda',
        budgetAmount: totalBudget * 0.50,
        categoryType: TipoCategoria.egreso,
      ),
      CategoryBudget(
        categoryId: 'alimentacion',
        categoryName: 'Alimentación',
        budgetAmount: totalBudget * 0.25,
        categoryType: TipoCategoria.egreso,
      ),
      CategoryBudget(
        categoryId: 'transporte',
        categoryName: 'Transporte',
        budgetAmount: totalBudget * 0.15,
        categoryType: TipoCategoria.egreso,
      ),
      CategoryBudget(
        categoryId: 'otros',
        categoryName: 'Otros',
        budgetAmount: totalBudget * 0.10,
        categoryType: TipoCategoria.egreso,
      ),
    ];

    return FinancialPlanModel(
      id: '',
      userId: userId,
      planName: planName,
      year: year,
      month: month,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      planType: PlanType.standard,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialPlanModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FinancialPlanModel(id: $id, planName: $planName, month: $monthName $year, usage: ${totalUsagePercentage.toStringAsFixed(1)}%)';
  }
}

/// Tipos de planes financieros
enum PlanType {
  standard,
  custom,
  ai;

  String get displayName {
    switch (this) {
      case PlanType.standard:
        return 'Estándar';
      case PlanType.custom:
        return 'Personalizado';
      case PlanType.ai:
        return 'IA (Próximamente)';
    }
  }

  String get description {
    switch (this) {
      case PlanType.standard:
        return 'Distribución automática entre todas las categorías disponibles';
      case PlanType.custom:
        return 'Distribución personalizada por categoría';
      case PlanType.ai:
        return 'Recomendaciones inteligentes basadas en IA';
    }
  }
}
