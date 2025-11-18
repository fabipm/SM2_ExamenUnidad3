import 'package:cloud_firestore/cloud_firestore.dart';
import '../financial_plans/models/financial_plan_model.dart';

/// Servicio ligero para realizar análisis sobre transacciones y planes.
class PlanAnalyzer {
  final FirebaseFirestore _firestore;

  PlanAnalyzer({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Analiza el resumen financiero del usuario: totales, gasto por categoría y top categories.
  Future<Map<String, dynamic>> analyzeUserOverview(String userId) async {
    try {
      // Cargar ingresos
      final ingresosSnap = await _firestore
          .collection('ingresos')
          .where('idUsuario', isEqualTo: userId)
          .get();

      // Cargar facturas/gastos
      final facturasSnap = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: userId)
          .get();

      double totalIngresos = 0.0;
      double totalGastos = 0.0;

      final Map<String, double> gastosPorCategoria = {};
      final List<Map<String, dynamic>> gastosList = [];

      for (final doc in ingresosSnap.docs) {
        final data = doc.data();
        final monto = _parseDouble(data['monto']);
        totalIngresos += monto;
      }

      for (final doc in facturasSnap.docs) {
        final data = doc.data();
        final monto = _parseDouble(data['totalAmount'] ?? data['monto'] ?? 0);
        totalGastos += monto;

        final categoria = (data['categoria'] ?? 'otros').toString();
        gastosPorCategoria[categoria] = (gastosPorCategoria[categoria] ?? 0.0) + monto;

        gastosList.add({
          'id': doc.id,
          'categoria': categoria,
          'monto': monto,
          'raw': data,
        });
      }

      // Top categorias
      final topCategories = gastosPorCategoria.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      final top = topCategories.take(6).map((e) => {'category': e.key, 'amount': e.value}).toList();

      // Detectar anomalías simples: transacciones mayores que 3x la mediana global
      final List<double> amounts = gastosList.map((e) => e['monto'] as double).toList();
      double median = _median(amounts);
      final anomalyThreshold = median * 3.0;
      final anomalies = gastosList.where((g) => (g['monto'] as double) > anomalyThreshold).take(10).toList();

      return {
        'totalIngresos': totalIngresos,
        'totalGastos': totalGastos,
        'balance': totalIngresos - totalGastos,
        'topCategories': top,
        'anomalies': anomalies,
        'snapshotDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Guarda un resultado de análisis (run) en Firestore bajo `analysis/{userId}/runs/{autoId}`
  Future<String?> saveAnalysisRun(String userId, Map<String, dynamic> runData) async {
    try {
      final ref = await _firestore.collection('analysis').doc(userId).collection('runs').add({
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'data': runData,
      });
      return ref.id;
    } catch (e) {
      print('Error saving analysis run: $e');
      return null;
    }
  }

  /// Analiza un plan financiero: compara presupuestos por categoría con gasto real y da causas/sugerencias.
  Future<Map<String, dynamic>> analyzePlan(FinancialPlanModel plan) async {
    try {
      final userId = plan.userId;
      // Obtener facturas del mes del plan
      final facturasSnap = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: userId)
          .get();

      // Filtrar por mes/año del plan
      final year = plan.year;
      final month = plan.month;

      final Map<String, double> spentByCategory = {};

      for (final doc in facturasSnap.docs) {
        final data = doc.data();
        DateTime invoiceDate;
        if (data['invoiceDate'] is String) {
          try {
            invoiceDate = DateTime.parse(data['invoiceDate']);
          } catch (_) {
            invoiceDate = DateTime.now();
          }
        } else if (data['invoiceDate'] is Timestamp) {
          invoiceDate = (data['invoiceDate'] as Timestamp).toDate();
        } else {
          invoiceDate = DateTime.now();
        }

        if (invoiceDate.year == year && invoiceDate.month == month) {
          final categoria = (data['categoria'] ?? 'otros').toString();
          final monto = _parseDouble(data['totalAmount'] ?? data['monto'] ?? 0);
          spentByCategory[categoria] = (spentByCategory[categoria] ?? 0.0) + monto;
        }
      }

      final List<Map<String, dynamic>> categoryAnalysis = [];

      for (final cb in plan.categoryBudgets) {
        final spent = spentByCategory[cb.categoryName] ?? spentByCategory[cb.categoryId] ?? 0.0;
        final over = spent > cb.budgetAmount;
        final suggestion = over
            ? 'Reducir gasto en ${cb.categoryName} en ${ (spent - cb.budgetAmount).toStringAsFixed(2) } o ajustar presupuesto.'
            : 'Cumpliendo presupuesto para ${cb.categoryName}.';

        categoryAnalysis.add({
          'categoryId': cb.categoryId,
          'categoryName': cb.categoryName,
          'budget': cb.budgetAmount,
          'spent': spent,
          'isOverBudget': over,
          'suggestion': suggestion,
        });
      }

      final totalBudget = plan.totalBudget;
      final totalSpent = categoryAnalysis.fold(0.0, (s, e) => s + (e['spent'] as double));

      // Top causes: categorias que más contribuyen al gasto o que estén sobre el presupuesto
      final topCauses = categoryAnalysis
          .where((c) => (c['spent'] as double) > 0)
          .toList()
        ..sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));

      return {
        'planId': plan.id,
        'planName': plan.planName,
        'year': year,
        'month': month,
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'usagePercentage': totalBudget > 0 ? ((totalSpent / totalBudget) * 100).clamp(0.0, 200.0) : 0.0,
        'categories': categoryAnalysis,
        'topCauses': topCauses.take(6).toList(),
      };
    } catch (e) {
      rethrow;
    }
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}
