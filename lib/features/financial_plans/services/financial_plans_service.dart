import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/financial_plan_model.dart';
import '../../transactions/models/categoria_model.dart';

/// Servicio para manejar operaciones CRUD de planes financieros
class FinancialPlansService {
  static const String _collection = 'financial_plans';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _aiModel = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash-exp',
  );

  /// Obtener todos los planes financieros de un usuario
  Future<List<FinancialPlanModel>> getUserFinancialPlans(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => FinancialPlanModel.fromMap({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error al obtener planes financieros: $e');
      return [];
    }
  }

  /// Obtener plan financiero específico por mes y año
  Future<FinancialPlanModel?> getPlanByMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return FinancialPlanModel.fromMap({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error al obtener plan del mes: $e');
      return null;
    }
  }

  /// Crear un nuevo plan financiero
  Future<String?> createFinancialPlan(FinancialPlanModel plan) async {
    try {
      // Verificar que no exista un plan para el mismo mes/año
      final existingPlan = await getPlanByMonth(
        userId: plan.userId,
        year: plan.year,
        month: plan.month,
      );

      if (existingPlan != null) {
        throw Exception(
          'Ya existe un plan para ${plan.monthName} ${plan.year}',
        );
      }

      final docRef = await _firestore.collection(_collection).add(plan.toMap());

      // Actualizar con el ID generado
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error al crear plan financiero: $e');
      rethrow;
    }
  }

  /// Actualizar un plan financiero existente
  Future<bool> updateFinancialPlan(FinancialPlanModel plan) async {
    try {
      if (plan.id.isEmpty) {
        throw Exception('El plan debe tener un ID válido');
      }

      final updatedPlan = plan.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(plan.id)
          .update(updatedPlan.toMap());

      return true;
    } catch (e) {
      print('Error al actualizar plan financiero: $e');
      return false;
    }
  }

  /// Actualizar gasto en una categoría específica
  Future<bool> updateCategorySpent({
    required String planId,
    required String categoryId,
    required double newSpentAmount,
  }) async {
    try {
      final planDoc = await _firestore
          .collection(_collection)
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Plan no encontrado');
      }

      final plan = FinancialPlanModel.fromMap({
        ...planDoc.data()!,
        'id': planDoc.id,
      });

      // Actualizar la categoría específica
      final updatedCategoryBudgets = plan.categoryBudgets.map((cb) {
        if (cb.categoryId == categoryId) {
          return cb.copyWith(spentAmount: newSpentAmount);
        }
        return cb;
      }).toList();

      final updatedPlan = plan.copyWith(
        categoryBudgets: updatedCategoryBudgets,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(planId)
          .update(updatedPlan.toMap());

      return true;
    } catch (e) {
      print('Error al actualizar gasto de categoría: $e');
      return false;
    }
  }

  /// Eliminar (desactivar) un plan financiero
  Future<bool> deleteFinancialPlan(String planId) async {
    try {
      await _firestore.collection(_collection).doc(planId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error al eliminar plan financiero: $e');
      return false;
    }
  }

  /// Obtener planes por año
  Future<List<FinancialPlanModel>> getPlansByYear({
    required String userId,
    required int year,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('year', isEqualTo: year)
          .where('isActive', isEqualTo: true)
          .orderBy('month', descending: false)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => FinancialPlanModel.fromMap({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      print('Error al obtener planes del año: $e');
      return [];
    }
  }

  /// Duplicar plan del mes anterior
  Future<String?> duplicatePreviousMonth({
    required String userId,
    required int targetYear,
    required int targetMonth,
  }) async {
    try {
      // Calcular mes/año anterior
      int prevMonth = targetMonth - 1;
      int prevYear = targetYear;

      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear = targetYear - 1;
      }

      // Obtener el plan del mes anterior
      final previousPlan = await getPlanByMonth(
        userId: userId,
        year: prevYear,
        month: prevMonth,
      );

      if (previousPlan == null) {
        throw Exception('No existe plan del mes anterior para duplicar');
      }

      // Crear nuevo plan basado en el anterior (reseteando gastos)
      final newCategoryBudgets = previousPlan.categoryBudgets
          .map((cb) => cb.copyWith(spentAmount: 0.0))
          .toList();

      final newPlan = previousPlan.copyWith(
        id: '',
        year: targetYear,
        month: targetMonth,
        categoryBudgets: newCategoryBudgets,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createFinancialPlan(newPlan);
    } catch (e) {
      print('Error al duplicar plan del mes anterior: $e');
      rethrow;
    }
  }

  /// Calcular estadísticas del plan
  Future<Map<String, dynamic>> getPlanStatistics(String planId) async {
    try {
      final planDoc = await _firestore
          .collection(_collection)
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Plan no encontrado');
      }

      final plan = FinancialPlanModel.fromMap({
        ...planDoc.data()!,
        'id': planDoc.id,
      });

      return {
        'totalBudget': plan.totalBudget,
        'totalSpent': plan.totalSpent,
        'remainingBudget': plan.remainingBudget,
        'usagePercentage': plan.totalUsagePercentage,
        'isOverBudget': plan.isOverBudget,
        'categoriesCount': plan.categoryBudgets.length,
        'overBudgetCategories': plan.categoryBudgets
            .where((cb) => cb.isOverBudget)
            .length,
      };
    } catch (e) {
      print('Error al calcular estadísticas: $e');
      return {};
    }
  }

  /// Obtener un plan financiero por ID
  Future<FinancialPlanModel?> getPlanById(String planId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(planId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return FinancialPlanModel.fromMap({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      print('Error al obtener plan por ID: $e');
      return null;
    }
  }

  /// Sincronizar gastos reales desde las facturas registradas
  Future<bool> syncRealExpenses({
    required String planId,
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      // Obtener el plan
      final plan = await getPlanById(planId);
      if (plan == null) return false;

      // Calcular inicio y fin del mes
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      // Obtener todas las facturas del mes
      final facturasSnapshot = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: userId)
          .get();

      // Mapear gastos por categoría
      final Map<String, double> gastosPorCategoria = {};

      for (final doc in facturasSnapshot.docs) {
        final data = doc.data();
        
        // Parsear fecha
        DateTime invoiceDate;
        try {
          final raw = data['invoiceDate'];
          if (raw == null) continue;
          if (raw is Timestamp) {
            invoiceDate = raw.toDate();
          } else if (raw is String) {
            invoiceDate = DateTime.tryParse(raw) ?? DateTime.now();
          } else {
            continue;
          }
        } catch (e) {
          continue;
        }

        // Filtrar por rango de fechas
        if (invoiceDate.isBefore(startDate) || invoiceDate.isAfter(endDate)) {
          continue;
        }

        final categoria = data['categoria'] ?? 'Otros';
        final monto = _parseDouble(data['totalAmount'] ?? data['monto']);

        gastosPorCategoria[categoria] = 
            (gastosPorCategoria[categoria] ?? 0.0) + monto;
      }

      // Actualizar los gastos en el plan
      final updatedBudgets = plan.categoryBudgets.map((cb) {
        final spent = gastosPorCategoria[cb.categoryName] ?? 0.0;
        return cb.copyWith(spentAmount: spent);
      }).toList();

      final updatedPlan = plan.copyWith(
        categoryBudgets: updatedBudgets,
        updatedAt: DateTime.now(),
      );

      await updateFinancialPlan(updatedPlan);
      return true;
    } catch (e) {
      print('Error al sincronizar gastos reales: $e');
      return false;
    }
  }

  /// Crear plan automático con IA basado en gastos del mes anterior
  Future<FinancialPlanModel?> createAIPlan({
    required String userId,
    required int targetYear,
    required int targetMonth,
    required double totalBudget,
    required List<CategoriaModel> categories,
  }) async {
    try {
      // Calcular mes anterior
      int prevMonth = targetMonth - 1;
      int prevYear = targetYear;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear = targetYear - 1;
      }

      // Obtener gastos del mes anterior
      final prevStartDate = DateTime(prevYear, prevMonth, 1);
      final prevEndDate = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59, 999);

      final facturasSnapshot = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: userId)
          .get();

      final Map<String, double> gastosPrevios = {};
      double totalGastosPrevios = 0.0;

      for (final doc in facturasSnapshot.docs) {
        final data = doc.data();
        
        DateTime? invoiceDate;
        try {
          final raw = data['invoiceDate'];
          if (raw == null) continue;
          if (raw is Timestamp) {
            invoiceDate = raw.toDate();
          } else if (raw is String) {
            invoiceDate = DateTime.tryParse(raw);
            if (invoiceDate == null) continue;
          } else {
            continue;
          }
        } catch (e) {
          continue;
        }

        if (invoiceDate.isBefore(prevStartDate) || invoiceDate.isAfter(prevEndDate)) {
          continue;
        }

        final categoria = data['categoria'] ?? 'Otros';
        final monto = _parseDouble(data['totalAmount'] ?? data['monto']);

        gastosPrevios[categoria] = (gastosPrevios[categoria] ?? 0.0) + monto;
        totalGastosPrevios += monto;
      }

      if (totalGastosPrevios == 0) {
        throw Exception('No hay datos del mes anterior para generar el plan con IA');
      }

      // Crear prompt para la IA
      final prompt = _buildAIPlanPrompt(
        gastosPrevios: gastosPrevios,
        totalGastosPrevios: totalGastosPrevios,
        categories: categories,
      );

      // Llamar a la IA
      final content = [Content.multi([TextPart(prompt)])];
      final response = await _aiModel.generateContent(content);
      final aiText = response.text ?? '';

      // Parsear respuesta de IA y crear presupuestos
      final categoryBudgets = _parseAIResponse(
        aiText: aiText,
        gastosPrevios: gastosPrevios,
        categories: categories,
        totalBudget: totalBudget,
      );

      final now = DateTime.now();
      return FinancialPlanModel(
        id: '',
        userId: userId,
        planName: 'Plan IA ${_getMonthName(targetMonth)} $targetYear',
        year: targetYear,
        month: targetMonth,
        totalBudget: totalBudget,
        categoryBudgets: categoryBudgets,
        planType: PlanType.ai,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );
    } catch (e) {
      print('Error al crear plan con IA: $e');
      rethrow;
    }
  }

  String _buildAIPlanPrompt({
    required Map<String, double> gastosPrevios,
    required double totalGastosPrevios,
    required List<CategoriaModel> categories,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Eres un asesor financiero experto. Analiza estos gastos del mes anterior y sugiere un presupuesto optimizado para el próximo mes.');
    buffer.writeln();
    buffer.writeln('GASTOS DEL MES ANTERIOR:');
    buffer.writeln('Total gastado: \$${totalGastosPrevios.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('Detalle por categoría:');
    
    gastosPrevios.forEach((cat, monto) {
      final porcentaje = (monto / totalGastosPrevios * 100);
      buffer.writeln('- $cat: \$${monto.toStringAsFixed(2)} (${porcentaje.toStringAsFixed(1)}%)');
    });

    buffer.writeln();
    buffer.writeln('CATEGORÍAS DISPONIBLES:');
    for (final cat in categories) {
      buffer.writeln('- ${cat.nombre}');
    }

    buffer.writeln();
    buffer.writeln('INSTRUCCIONES:');
    buffer.writeln('1. Analiza los patrones de gasto');
    buffer.writeln('2. Sugiere un presupuesto optimizado (puede ser 5-10% mayor para contingencias)');
    buffer.writeln('3. Distribuye el presupuesto entre las categorías de forma inteligente');
    buffer.writeln('4. Responde SOLO con un JSON en este formato:');
    buffer.writeln('{');
    buffer.writeln('  "totalSugerido": 1000.0,');
    buffer.writeln('  "distribucion": [');
    buffer.writeln('    {"categoria": "Nombre", "monto": 500.0, "razon": "Justificación breve"}');
    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  List<CategoryBudget> _parseAIResponse({
    required String aiText,
    required Map<String, double> gastosPrevios,
    required List<CategoriaModel> categories,
    required double totalBudget,
  }) {
    try {
      // Intentar extraer JSON
      final jsonStart = aiText.indexOf('{');
      final jsonEnd = aiText.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw FormatException('No se encontró JSON en la respuesta');
      }

      // Distribuir el presupuesto total proporcionado basándose en proporciones de gastos previos
      final categoryBudgets = <CategoryBudget>[];
      final totalGastosPrevios = gastosPrevios.values.fold(0.0, (sum, val) => sum + val);

      if (totalGastosPrevios == 0) {
        // Si no hay gastos previos, distribuir equitativamente
        final budgetPerCategory = totalBudget / categories.length;
        for (final cat in categories) {
          categoryBudgets.add(CategoryBudget(
            categoryId: cat.id,
            categoryName: cat.nombre,
            budgetAmount: budgetPerCategory,
            spentAmount: 0.0,
            categoryType: cat.tipo,
          ));
        }
      } else {
        // Distribuir proporcionalmente según gastos previos
        for (final cat in categories) {
          final gastoAnterior = gastosPrevios[cat.nombre] ?? 0.0;
          final proporcion = gastoAnterior / totalGastosPrevios;
          final presupuestoSugerido = totalBudget * proporcion;

          categoryBudgets.add(CategoryBudget(
            categoryId: cat.id,
            categoryName: cat.nombre,
            budgetAmount: presupuestoSugerido > 0 ? presupuestoSugerido : totalBudget * 0.05,
            spentAmount: 0.0,
            categoryType: cat.tipo,
          ));
        }

        // Ajustar para que sume exactamente el presupuesto total
        final totalAsignado = categoryBudgets.fold(0.0, (sum, cb) => sum + cb.budgetAmount);
        if ((totalAsignado - totalBudget).abs() > 0.01) {
          final factor = totalBudget / totalAsignado;
          final adjustedBudgets = categoryBudgets.map((cb) {
            return cb.copyWith(budgetAmount: cb.budgetAmount * factor);
          }).toList();
          return adjustedBudgets;
        }
      }

      return categoryBudgets;
    } catch (e) {
      print('Error parseando respuesta IA, usando fallback: $e');
      rethrow;
    }
  }

  String _getMonthName(int month) {
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

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Generar resumen con IA sobre el resultado de un plan
  Future<bool> generateAISummary({
    required String planId,
    required String userId,
  }) async {
    try {
      final plan = await getPlanById(planId);
      if (plan == null) return false;

      // Calcular totales y porcentajes
      final totalSpent = plan.categoryBudgets.fold(
        0.0,
        (sum, budget) => sum + budget.spentAmount,
      );
      final usagePercentage = plan.totalBudget > 0
          ? (totalSpent / plan.totalBudget * 100)
          : 0.0;

      // Construir prompt para IA
      final prompt = _buildSummaryPrompt(
        plan: plan,
        totalSpent: totalSpent,
        usagePercentage: usagePercentage,
      );

      // Llamar a IA
      final content = [Content.multi([TextPart(prompt)])];
      final response = await _aiModel.generateContent(content);
      final summary = response.text ?? 'No se pudo generar resumen';

      // Actualizar plan con el resumen
      final updatedPlan = plan.copyWith(aiSummary: summary);
      await updateFinancialPlan(updatedPlan);

      return true;
    } catch (e) {
      print('Error al generar resumen IA: $e');
      return false;
    }
  }

  String _buildSummaryPrompt({
    required FinancialPlanModel plan,
    required double totalSpent,
    required double usagePercentage,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Analiza este plan financiero y genera un resumen de MÁXIMO 30 PALABRAS.');
    buffer.writeln();
    buffer.writeln('PLAN: ${plan.planName}');
    buffer.writeln('Presupuesto: S/ ${plan.totalBudget.toStringAsFixed(2)}');
    buffer.writeln('Gastado: S/ ${totalSpent.toStringAsFixed(2)} (${usagePercentage.toStringAsFixed(1)}%)');
    buffer.writeln();
    buffer.writeln('GASTOS POR CATEGORÍA:');
    
    for (final budget in plan.categoryBudgets) {
      final catPercentage = budget.budgetAmount > 0
          ? (budget.spentAmount / budget.budgetAmount * 100)
          : 0.0;
      buffer.writeln('- ${budget.categoryName}: S/ ${budget.spentAmount.toStringAsFixed(2)} de S/ ${budget.budgetAmount.toStringAsFixed(2)} (${catPercentage.toStringAsFixed(0)}%)');
    }

    buffer.writeln();
    buffer.writeln('INSTRUCCIONES:');
    buffer.writeln('1. Resume el resultado del plan');
    buffer.writeln('2. Menciona si cumplió o excedió el presupuesto');
    buffer.writeln('3. Da UNA sugerencia breve de mejora');
    buffer.writeln('4. MÁXIMO 30 PALABRAS EN TOTAL');
    buffer.writeln('5. Responde SOLO el resumen, sin formato adicional');

    return buffer.toString();
  }
}
