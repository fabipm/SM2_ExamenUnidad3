import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dashboard_stats_model.dart';
import '../../transactions/models/register_bill_model.dart';
import '../../transactions/models/registro_ingreso_model.dart';
import '../../financial_plans/models/financial_plan_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DashboardStatsModel? _dashboardStats;
  bool _isLoading = false;
  String? _error;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  DashboardStatsModel? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Cargar datos del dashboard para el mes seleccionado
  Future<void> loadDashboardData() async {
    if (_currentUserId == null) {
      _error = 'Usuario no autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Calcular rango de fechas para el mes seleccionado
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

      // Cargar datos en paralelo
      final results = await Future.wait([
        _loadExpenses(startDate, endDate),
        _loadIncomes(startDate, endDate),
        _loadFinancialPlans(),
      ]);

      final expenses = results[0] as Map<String, CategoryStats>;
      final incomes = results[1] as Map<String, CategoryStats>;
      final plans = results[2] as List<PlanSummary>;

      // Calcular totales
      final totalIngresos = incomes.values.fold(0.0, (sum, cat) => sum + cat.amount);
      final totalGastos = expenses.values.fold(0.0, (sum, cat) => sum + cat.amount);
      final cantidadTransacciones = 
          incomes.values.fold(0, (sum, cat) => sum + cat.transactionCount) +
          expenses.values.fold(0, (sum, cat) => sum + cat.transactionCount);

      // Crear estadísticas mensuales
      final monthlyStats = MonthlyStats(
        year: _selectedYear,
        month: _selectedMonth,
        totalIngresos: totalIngresos,
        totalGastos: totalGastos,
        balance: totalIngresos - totalGastos,
        cantidadTransacciones: cantidadTransacciones.toInt(),
      );

      // Ordenar categorías por monto (mayor a menor)
      final gastosList = expenses.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final ingresosList = incomes.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      _dashboardStats = DashboardStatsModel(
        monthlyStats: monthlyStats,
        gastosPorCategoria: gastosList,
        ingresosPorCategoria: ingresosList,
        planesActivos: plans,
        lastUpdated: DateTime.now(),
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar datos del dashboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar gastos del mes y agrupar por categoría
  Future<Map<String, CategoryStats>> _loadExpenses(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Map<String, CategoryStats> categoryMap = {};

    try {
      final snapshot = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: _currentUserId)
          .where('invoiceDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('invoiceDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      for (var doc in snapshot.docs) {
        try {
          final factura = Factura.fromMap(doc.data());
          final categoria = factura.categoria.isEmpty ? 'Sin categoría' : factura.categoria;

          if (categoryMap.containsKey(categoria)) {
            final existing = categoryMap[categoria]!;
            categoryMap[categoria] = CategoryStats(
              categoryId: existing.categoryId,
              categoryName: categoria,
              amount: existing.amount + factura.totalAmount,
              transactionCount: existing.transactionCount + 1,
              tipo: 'gasto',
            );
          } else {
            categoryMap[categoria] = CategoryStats(
              categoryId: categoria.toLowerCase().replaceAll(' ', '_'),
              categoryName: categoria,
              amount: factura.totalAmount,
              transactionCount: 1,
              tipo: 'gasto',
            );
          }
        } catch (e) {
          print('Error procesando factura ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error cargando gastos: $e');
    }

    return categoryMap;
  }

  /// Cargar ingresos del mes y agrupar por categoría
  Future<Map<String, CategoryStats>> _loadIncomes(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final Map<String, CategoryStats> categoryMap = {};

    try {
      final snapshot = await _firestore
          .collection('ingresos')
          .where('idUsuario', isEqualTo: _currentUserId)
          .where('fecha', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('fecha', isLessThanOrEqualTo: endDate.toIso8601String())
          .get();

      for (var doc in snapshot.docs) {
        try {
          final ingreso = Ingreso.fromMap(doc.data());
          final categoria = ingreso.categoria.isEmpty ? 'Sin categoría' : ingreso.categoria;

          if (categoryMap.containsKey(categoria)) {
            final existing = categoryMap[categoria]!;
            categoryMap[categoria] = CategoryStats(
              categoryId: existing.categoryId,
              categoryName: categoria,
              amount: existing.amount + ingreso.monto,
              transactionCount: existing.transactionCount + 1,
              tipo: 'ingreso',
            );
          } else {
            categoryMap[categoria] = CategoryStats(
              categoryId: categoria.toLowerCase().replaceAll(' ', '_'),
              categoryName: categoria,
              amount: ingreso.monto,
              transactionCount: 1,
              tipo: 'ingreso',
            );
          }
        } catch (e) {
          print('Error procesando ingreso ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error cargando ingresos: $e');
    }

    return categoryMap;
  }

  /// Cargar planes financieros del mes actual
  Future<List<PlanSummary>> _loadFinancialPlans() async {
    final List<PlanSummary> plans = [];

    try {
      final snapshot = await _firestore
          .collection('financial_plans')
          .where('userId', isEqualTo: _currentUserId)
          .where('year', isEqualTo: _selectedYear)
          .where('month', isEqualTo: _selectedMonth)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final plan = FinancialPlanModel.fromMap(data);
          
          // Calcular gasto total del plan
          final totalSpent = plan.categoryBudgets.fold(
            0.0,
            (sum, budget) => sum + budget.spentAmount,
          );

          plans.add(PlanSummary(
            planId: plan.id,
            planName: plan.planName,
            totalBudget: plan.totalBudget,
            totalSpent: totalSpent,
            month: plan.month,
            year: plan.year,
            isActive: plan.isActive,
            categoriesCount: plan.categoryBudgets.length,
          ));
        } catch (e) {
          print('Error procesando plan ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error cargando planes: $e');
    }

    return plans;
  }

  /// Cambiar mes seleccionado
  void setMonth(int month, int year) {
    if (_selectedMonth != month || _selectedYear != year) {
      _selectedMonth = month;
      _selectedYear = year;
      loadDashboardData();
    }
  }

  /// Refrescar datos
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Ir al mes anterior
  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    loadDashboardData();
  }

  /// Ir al mes siguiente
  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    loadDashboardData();
  }

  /// Obtener nombre del mes en español
  String getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}
