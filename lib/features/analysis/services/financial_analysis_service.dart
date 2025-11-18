import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/financial_analysis_model.dart';

/// Servicio para realizar análisis financiero usando Firebase AI (Gemini)
class FinancialAnalysisService {
  final FirebaseFirestore _firestore;
  final GenerativeModel _aiModel;

  FinancialAnalysisService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _aiModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash-exp',
      );

  // 🆕 Obtener perfil del usuario con datos demográficos
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error obteniendo perfil de usuario: $e');
      return null;
    }
  }

  /// Obtener datos financieros del período especificado
  Future<Map<String, dynamic>> _getFinancialData(
    String userId,
    AnalysisPeriod period,
  ) async {
    // Obtener ingresos del usuario (filtraremos por rango en cliente para soportar
    // fecha guardada como String o Timestamp de forma robusta)
    final ingresosSnapshot = await _firestore
        .collection('ingresos')
        .where('idUsuario', isEqualTo: userId)
        .get();

    // Obtener gastos/facturas del usuario (filtraremos por rango en cliente para soportar
    // invoiceDate guardado como String o Timestamp de forma robusta)
    final facturasSnapshot = await _firestore
        .collection('facturas')
        .where('idUsuario', isEqualTo: userId)
        .get();

    // Procesar ingresos
    final List<Map<String, dynamic>> ingresos = [];
    double totalIngresos = 0.0;

    for (var doc in ingresosSnapshot.docs) {
      final data = doc.data();

      // Parse fecha which might be stored as a Timestamp or as an ISO string
      DateTime ingresoDate;
      try {
        final raw = data['fecha'];
        if (raw == null) {
          ingresoDate = DateTime.now();
        } else if (raw is Timestamp) {
          ingresoDate = raw.toDate();
        } else if (raw is String) {
          ingresoDate = DateTime.tryParse(raw) ?? DateTime.now();
        } else {
          ingresoDate = DateTime.now();
        }
      } catch (e) {
        ingresoDate = DateTime.now();
      }

      // Filtrar por el período solicitado
      if (ingresoDate.isBefore(period.startDate) || ingresoDate.isAfter(period.endDate)) {
        continue; // fuera del rango
      }

      final monto = _parseDouble(data['monto']);
      totalIngresos += monto;
      ingresos.add({
        'id': doc.id,
        'monto': monto,
        'fecha': ingresoDate,
        'categoria': data['categoria'] ?? 'Sin categoría',
        'descripcion': data['descripcion'] ?? '',
        'metodoPago': data['metodoPago'] ?? '',
        'origen': data['origen'] ?? '',
      });
    }

    // Procesar gastos
    final List<Map<String, dynamic>> gastos = [];
    double totalGastos = 0.0;
    final Map<String, double> gastosPorCategoria = {};
    final Map<String, int> transaccionesPorCategoria = {};

    for (var doc in facturasSnapshot.docs) {
      final data = doc.data();

      // Parse invoiceDate which might be stored as a Timestamp or as an ISO string
      DateTime invoiceDate;
      try {
        final raw = data['invoiceDate'];
        if (raw == null) {
          invoiceDate = DateTime.now();
        } else if (raw is Timestamp) {
          invoiceDate = raw.toDate();
        } else if (raw is String) {
          invoiceDate = DateTime.tryParse(raw) ?? DateTime.now();
        } else {
          invoiceDate = DateTime.now();
        }
      } catch (e) {
        invoiceDate = DateTime.now();
      }

      // Filtrar por el período solicitado
      if (invoiceDate.isBefore(period.startDate) || invoiceDate.isAfter(period.endDate)) {
        continue; // fuera del rango
      }

      final monto = _parseDouble(data['totalAmount'] ?? data['monto']);
      final categoria = data['categoria'] ?? 'Sin categoría';

      totalGastos += monto;
      gastosPorCategoria[categoria] = (gastosPorCategoria[categoria] ?? 0.0) + monto;
      transaccionesPorCategoria[categoria] = (transaccionesPorCategoria[categoria] ?? 0) + 1;

      gastos.add({
        'id': doc.id,
        'monto': monto,
        'fecha': invoiceDate,
        'categoria': categoria,
        'descripcion': data['description'] ?? '',
        'proveedor': data['supplierName'] ?? '',
        'lugar': data['lugarLocal'] ?? '',
      });
    }

    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'totalIngresos': totalIngresos,
      'totalGastos': totalGastos,
      'gastosPorCategoria': gastosPorCategoria,
      'transaccionesPorCategoria': transaccionesPorCategoria,
    };
  }

  /// Calcular resumen financiero
  FinancialSummary _calculateSummary(Map<String, dynamic> data) {
    final totalIncome = data['totalIngresos'] as double;
    final totalExpenses = data['totalGastos'] as double;
    final balance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? ((balance / totalIncome) * 100) : 0.0;

    final gastos = data['gastos'] as List<Map<String, dynamic>>;
    final transactionCount = gastos.length;
    final averageExpense = transactionCount > 0
        ? totalExpenses / transactionCount
        : 0.0;

    // Encontrar gasto más grande
    double largestExpense = 0.0;
    String largestExpenseCategory = 'Sin categoría';

    for (var gasto in gastos) {
      final monto = gasto['monto'] as double;
      if (monto > largestExpense) {
        largestExpense = monto;
        largestExpenseCategory = gasto['categoria'] as String;
      }
    }

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
      savingsRate: savingsRate,
      transactionCount: transactionCount,
      averageExpense: averageExpense,
      largestExpense: largestExpense,
      largestExpenseCategory: largestExpenseCategory,
    );
  }

  /// Calcular insights por categoría
  List<CategoryInsight> _calculateCategoryInsights(Map<String, dynamic> data) {
    final gastosPorCategoria =
        data['gastosPorCategoria'] as Map<String, double>;
    final transaccionesPorCategoria =
        data['transaccionesPorCategoria'] as Map<String, int>;
    final totalGastos = data['totalGastos'] as double;

    final insights = <CategoryInsight>[];

    gastosPorCategoria.forEach((categoria, monto) {
      final count = transaccionesPorCategoria[categoria] ?? 1;
      final percentage = totalGastos > 0 ? (monto / totalGastos) * 100 : 0.0;
      final average = monto / count;

      // Por ahora, trend y changePercentage son dummy
      // En una implementación real, compararíamos con el período anterior
      insights.add(
        CategoryInsight(
          categoryId: categoria.toLowerCase().replaceAll(' ', '_'),
          categoryName: categoria,
          totalAmount: monto,
          percentage: percentage,
          transactionCount: count,
          averageTransaction: average,
          trend: TrendType.stable,
          changePercentage: 0.0,
        ),
      );
    });

    // Ordenar por monto descendente
    insights.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return insights;
  }

  /// Detectar patrones de gasto usando IA
  Future<List<SpendingPattern>> _detectPatterns(
    Map<String, dynamic> data,
    FinancialSummary summary,
  ) async {
    final patterns = <SpendingPattern>[];

    // Patrón 1: Gastos inusuales (más de 3x el promedio)
    final gastos = data['gastos'] as List<Map<String, dynamic>>;
    final threshold = summary.averageExpense * 3;

    for (var gasto in gastos) {
      final monto = gasto['monto'] as double;
      if (monto > threshold) {
        patterns.add(
          SpendingPattern(
            id: 'unusual_${gasto['id']}',
            type: PatternType.unusual,
            title: 'Gasto inusual detectado',
            description:
                'Gasto de \$${monto.toStringAsFixed(2)} en ${gasto['categoria']} (${(monto / summary.averageExpense).toStringAsFixed(1)}x mayor que el promedio)',
            category: gasto['categoria'],
            impact: monto - summary.averageExpense,
            severity: monto > threshold * 2
                ? SeverityLevel.high
                : SeverityLevel.medium,
          ),
        );
      }
    }

    // Patrón 2: Categoría dominante (más del 40% del total)
    final categoryInsights = _calculateCategoryInsights(data);
    for (var insight in categoryInsights) {
      if (insight.percentage > 40) {
        patterns.add(
          SpendingPattern(
            id: 'dominant_${insight.categoryId}',
            type: PatternType.increasing,
            title: 'Categoría dominante',
            description:
                '${insight.categoryName} representa el ${insight.percentage.toStringAsFixed(1)}% de tus gastos totales',
            category: insight.categoryName,
            impact: insight.totalAmount,
            severity: insight.percentage > 60
                ? SeverityLevel.critical
                : SeverityLevel.high,
          ),
        );
      }
    }

    return patterns;
  }

  /// Generar recomendaciones usando IA
  Future<List<AIRecommendation>> _generateRecommendations(
    Map<String, dynamic> data,
    FinancialSummary summary,
    List<CategoryInsight> insights,
    List<SpendingPattern> patterns,
    Map<String, dynamic>? userProfile, // 🆕 Perfil del usuario
  ) async {
    try {
      // Preparar prompt para Gemini (ahora con contexto de perfil)
      final prompt = _buildRecommendationPrompt(
        data,
        summary,
        insights,
        patterns,
        userProfile, // 🆕 Pasar perfil al prompt
      );

      final content = [
        Content.multi([TextPart(prompt)]),
      ];

      final response = await _aiModel.generateContent(content);
      final aiText = response.text ?? '';

      // Parsear recomendaciones del texto de IA
      return _parseRecommendationsFromAI(aiText, insights);
    } catch (e) {
      print('Error generating AI recommendations: $e');
      // Fallback: generar recomendaciones básicas
      return _generateBasicRecommendations(summary, insights, patterns);
    }
  }

  /// Construir prompt para Gemini
  String _buildRecommendationPrompt(
    Map<String, dynamic> data,
    FinancialSummary summary,
    List<CategoryInsight> insights,
    List<SpendingPattern> patterns,
    Map<String, dynamic>? userProfile, // 🆕 Perfil del usuario
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
      'Eres un asesor financiero personal experto. Analiza estos datos financieros y genera exactamente 5 recomendaciones específicas y accionables:',
    );
    buffer.writeln();

    // 🆕 CONTEXTO DEMOGRÁFICO DEL USUARIO
    if (userProfile != null) {
      buffer.writeln('� PERFIL DEL USUARIO:');
      if (userProfile['edad'] != null) {
        buffer.writeln('- Edad: ${userProfile['edad']} años');
      }
      if (userProfile['ocupacion'] != null) {
        buffer.writeln('- Ocupación: ${userProfile['ocupacion']}');
      }
      if (userProfile['estadoCivil'] != null) {
        buffer.writeln('- Estado civil: ${userProfile['estadoCivil']}');
      }
      if (userProfile['tieneHijos'] != null) {
        buffer.writeln(
          '- Tiene hijos: ${userProfile['tieneHijos'] ? 'Sí' : 'No'}',
        );
      }
      if (userProfile['numeroDependientes'] != null) {
        buffer.writeln(
          '- Dependientes económicos: ${userProfile['numeroDependientes']}',
        );
      }
      if (userProfile['nivelEducacion'] != null) {
        buffer.writeln('- Nivel educativo: ${userProfile['nivelEducacion']}');
      }
      if (userProfile['ingresoMensualAprox'] != null) {
        buffer.writeln(
          '- Ingreso mensual aprox: \$${userProfile['ingresoMensualAprox']}',
        );
      }
      if (userProfile['objetivosFinancieros'] != null &&
          (userProfile['objetivosFinancieros'] as List).isNotEmpty) {
        buffer.writeln(
          '- Objetivos financieros: ${(userProfile['objetivosFinancieros'] as List).join(', ')}',
        );
      }
      buffer.writeln();
    }

    buffer.writeln('�📊 RESUMEN FINANCIERO:');
    buffer.writeln(
      '- Ingresos totales: \$${summary.totalIncome.toStringAsFixed(2)}',
    );
    buffer.writeln(
      '- Gastos totales: \$${summary.totalExpenses.toStringAsFixed(2)}',
    );
    buffer.writeln('- Balance: \$${summary.balance.toStringAsFixed(2)}');
    buffer.writeln(
      '- Tasa de ahorro: ${summary.savingsRate.toStringAsFixed(1)}%',
    );
    buffer.writeln(
      '- Gasto promedio: \$${summary.averageExpense.toStringAsFixed(2)}',
    );
    buffer.writeln();
    buffer.writeln('📈 TOP 5 CATEGORÍAS DE GASTO:');
    for (var i = 0; i < insights.length && i < 5; i++) {
      final insight = insights[i];
      buffer.writeln(
        '${i + 1}. ${insight.categoryName}: \$${insight.totalAmount.toStringAsFixed(2)} (${insight.percentage.toStringAsFixed(1)}%)',
      );
    }
    buffer.writeln();
    buffer.writeln('🔍 PATRONES DETECTADOS:');
    if (patterns.isEmpty) {
      buffer.writeln('- No se detectaron patrones inusuales');
    } else {
      for (var pattern in patterns.take(3)) {
        buffer.writeln('- ${pattern.title}: ${pattern.description}');
      }
    }
    buffer.writeln();
    buffer.writeln('INSTRUCCIONES:');
    buffer.writeln(
      'Genera EXACTAMENTE 5 recomendaciones PERSONALIZADAS considerando el perfil demográfico del usuario.',
    );
    buffer.writeln('Formato JSON:');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "titulo": "Título corto de la recomendación",');
    buffer.writeln(
      '    "descripcion": "Descripción detallada de la recomendación",',
    );
    buffer.writeln('    "tipo": "reduce|optimize|budget|save|alert",');
    buffer.writeln('    "categoria": "Categoría afectada o General",');
    buffer.writeln('    "ahorroEstimado": 0.0,');
    buffer.writeln('    "prioridad": "low|medium|high|urgent",');
    buffer.writeln('    "pasos": ["Paso 1", "Paso 2", "Paso 3"]');
    buffer.writeln('  }');
    buffer.writeln(']');
    buffer.writeln();
    buffer.writeln(
      'IMPORTANTE: Responde SOLO con el JSON, sin texto adicional.',
    );

    return buffer.toString();
  }

  /// Parsear recomendaciones del texto de IA
  List<AIRecommendation> _parseRecommendationsFromAI(
    String aiText,
    List<CategoryInsight> insights,
  ) {
    try {
      // Intentar extraer JSON del texto
      final jsonStart = aiText.indexOf('[');
      final jsonEnd = aiText.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw FormatException('No JSON found in AI response');
      }

      final jsonText = aiText.substring(jsonStart, jsonEnd);

      // Limpiar el texto JSON (remover markdown code blocks si existen)
      // final cleanJson = jsonText
      //     .replaceAll('```json', '')
      //     .replaceAll('```', '')
      //     .trim();

      // En una implementación real, usarías dart:convert para parsear cleanJson
      // Por ahora, generamos recomendaciones básicas
      print('AI Response: $jsonText');
      return _generateBasicRecommendations(
        FinancialSummary(
          totalIncome: 0,
          totalExpenses: 0,
          balance: 0,
          savingsRate: 0,
          transactionCount: 0,
          averageExpense: 0,
          largestExpense: 0,
          largestExpenseCategory: '',
        ),
        insights,
        [],
      );
    } catch (e) {
      print('Error parsing AI recommendations: $e');
      return [];
    }
  }

  /// Generar recomendaciones básicas (fallback)
  List<AIRecommendation> _generateBasicRecommendations(
    FinancialSummary summary,
    List<CategoryInsight> insights,
    List<SpendingPattern> patterns,
  ) {
    final recommendations = <AIRecommendation>[];

    // Recomendación 1: Reducir categoría más alta
    if (insights.isNotEmpty) {
      final topCategory = insights.first;
      if (topCategory.percentage > 30) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_reduce_top',
            title: 'Reduce gastos en ${topCategory.categoryName}',
            description:
                'Esta categoría representa el ${topCategory.percentage.toStringAsFixed(1)}% de tus gastos. Reducir un 20% podría ahorrarte \$${(topCategory.totalAmount * 0.2).toStringAsFixed(2)}',
            type: RecommendationType.reduce,
            category: topCategory.categoryName,
            potentialSavings: topCategory.totalAmount * 0.2,
            priority: topCategory.percentage > 50
                ? PriorityLevel.high
                : PriorityLevel.medium,
            actionSteps: [
              'Revisa tus transacciones de ${topCategory.categoryName}',
              'Identifica gastos que puedas eliminar o reducir',
              'Establece un límite mensual para esta categoría',
            ],
          ),
        );
      }
    }

    // Recomendación 2: Mejorar tasa de ahorro
    if (summary.savingsRate < 20) {
      recommendations.add(
        AIRecommendation(
          id: 'rec_savings_rate',
          title: 'Aumenta tu tasa de ahorro',
          description:
              'Tu tasa de ahorro actual es ${summary.savingsRate.toStringAsFixed(1)}%. El objetivo recomendado es al menos 20%.',
          type: RecommendationType.save,
          category: 'General',
          potentialSavings: summary.totalIncome * 0.2 - summary.balance,
          priority: summary.savingsRate < 10
              ? PriorityLevel.urgent
              : PriorityLevel.high,
          actionSteps: [
            'Automatiza transferencias a una cuenta de ahorros',
            'Aplica la regla 50/30/20 (necesidades/deseos/ahorros)',
            'Revisa gastos recurrentes que puedas reducir',
          ],
        ),
      );
    }

    // Recomendación 3: Crear presupuesto si no hay control
    if (insights.length > 5 && insights.any((i) => i.percentage > 40)) {
      recommendations.add(
        AIRecommendation(
          id: 'rec_budget',
          title: 'Crea un presupuesto mensual',
          description:
              'Establecer límites por categoría te ayudará a controlar mejor tus finanzas y evitar gastos excesivos.',
          type: RecommendationType.budget,
          category: 'General',
          potentialSavings: summary.totalExpenses * 0.15,
          priority: PriorityLevel.high,
          actionSteps: [
            'Define límites mensuales para cada categoría',
            'Usa la función de Planes Financieros de la app',
            'Revisa tu progreso semanalmente',
          ],
        ),
      );
    }

    // Recomendación 4: Optimizar gastos recurrentes
    recommendations.add(
      AIRecommendation(
        id: 'rec_optimize',
        title: 'Optimiza tus gastos recurrentes',
        description:
            'Revisa suscripciones, servicios y gastos fijos para identificar oportunidades de ahorro.',
        type: RecommendationType.optimize,
        category: 'Servicios',
        potentialSavings: summary.totalExpenses * 0.1,
        priority: PriorityLevel.medium,
        actionSteps: [
          'Lista todas tus suscripciones activas',
          'Cancela las que no uses regularmente',
          'Busca alternativas más económicas para servicios esenciales',
        ],
      ),
    );

    // Recomendación 5: Alerta de gastos inusuales
    if (patterns.any((p) => p.type == PatternType.unusual)) {
      final unusualPattern = patterns.firstWhere(
        (p) => p.type == PatternType.unusual,
      );
      recommendations.add(
        AIRecommendation(
          id: 'rec_alert_unusual',
          title: 'Controla gastos inusuales',
          description: unusualPattern.description,
          type: RecommendationType.alert,
          category: unusualPattern.category,
          potentialSavings: unusualPattern.impact * 0.5,
          priority: PriorityLevel.medium,
          actionSteps: [
            'Verifica si este gasto era realmente necesario',
            'Planifica mejor para gastos grandes futuros',
            'Considera crear un fondo de emergencia',
          ],
        ),
      );
    }

    return recommendations;
  }

  /// Realizar análisis financiero completo
  Future<FinancialAnalysisModel> analyzeFinances({
    required String userId,
    required AnalysisPeriod period,
  }) async {
    try {
      // 🆕 0. Obtener perfil del usuario con datos demográficos
      final userProfile = await _getUserProfile(userId);

      // 1. Obtener datos financieros
      final data = await _getFinancialData(userId, period);

      // 2. Calcular resumen
      final summary = _calculateSummary(data);

      // 3. Calcular insights por categoría
      final categoryInsights = _calculateCategoryInsights(data);

      // 4. Detectar patrones
      final patterns = await _detectPatterns(data, summary);

      // 5. Generar recomendaciones con IA (ahora con contexto de perfil)
      final recommendations = await _generateRecommendations(
        data,
        summary,
        categoryInsights,
        patterns,
        userProfile, // 🆕 Pasar perfil del usuario
      );

      // 6. Generar texto explicativo con IA (ahora con contexto de perfil)
      final aiText = await _generateExplanationText(
        summary,
        categoryInsights,
        patterns,
        recommendations,
        userProfile, // 🆕 Pasar perfil del usuario
      );

      // 7. Crear modelo de análisis
      final analysis = FinancialAnalysisModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        createdAt: DateTime.now(),
        period: period,
        summary: summary,
        categoryInsights: categoryInsights,
        patterns: patterns,
        recommendations: recommendations,
        aiGeneratedText: aiText,
      );

      return analysis;
    } catch (e) {
      print('Error in analyzeFinances: $e');
      rethrow;
    }
  }

  /// Generar texto explicativo con IA
  Future<String> _generateExplanationText(
    FinancialSummary summary,
    List<CategoryInsight> insights,
    List<SpendingPattern> patterns,
    List<AIRecommendation> recommendations,
    Map<String, dynamic>? userProfile, // 🆕 Perfil del usuario
  ) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(
        'Eres un asesor financiero personal. Genera un análisis narrativo breve (máximo 200 palabras) sobre esta situación financiera:',
      );
      buffer.writeln();

      // 🆕 CONTEXTO DEMOGRÁFICO
      if (userProfile != null) {
        buffer.writeln('PERFIL:');
        if (userProfile['edad'] != null) {
          buffer.writeln('- ${userProfile['edad']} años');
        }
        if (userProfile['estadoCivil'] != null) {
          buffer.writeln('- ${userProfile['estadoCivil']}');
        }
        if (userProfile['numeroDependientes'] != null &&
            userProfile['numeroDependientes'] > 0) {
          buffer.writeln('- ${userProfile['numeroDependientes']} dependientes');
        }
        if (userProfile['objetivosFinancieros'] != null &&
            (userProfile['objetivosFinancieros'] as List).isNotEmpty) {
          buffer.writeln(
            '- Objetivos: ${(userProfile['objetivosFinancieros'] as List).join(', ')}',
          );
        }
        buffer.writeln();
      }

      buffer.writeln('RESUMEN:');
      buffer.writeln('- Balance: \$${summary.balance.toStringAsFixed(2)}');
      buffer.writeln(
        '- Tasa de ahorro: ${summary.savingsRate.toStringAsFixed(1)}%',
      );
      buffer.writeln(
        '- Gastos totales: \$${summary.totalExpenses.toStringAsFixed(2)}',
      );
      buffer.writeln();
      buffer.writeln('TOP CATEGORÍAS:');
      buffer.writeln(
        insights
            .take(3)
            .map(
              (i) => '- ${i.categoryName}: ${i.percentage.toStringAsFixed(1)}%',
            )
            .join('\n'),
      );
      buffer.writeln();
      buffer.writeln('Escribe un análisis amigable y motivador que:');
      buffer.writeln('1. Resuma la situación actual considerando su perfil');
      buffer.writeln('2. Destaque lo positivo');
      buffer.writeln('3. Señale áreas de oportunidad');
      buffer.writeln('4. Motive a la acción');
      buffer.writeln();
      buffer.writeln(
        'Responde en español, de forma conversacional y positiva.',
      );

      final prompt = buffer.toString();

      final content = [
        Content.multi([TextPart(prompt)]),
      ];
      final response = await _aiModel.generateContent(content);
      return response.text ?? 'Análisis financiero completado.';
    } catch (e) {
      print('Error generating explanation text: $e');
      return 'Tu análisis financiero está listo. Revisa los insights y recomendaciones personalizadas para mejorar tu situación financiera.';
    }
  }

  /// Guardar análisis en Firestore
  Future<void> saveAnalysis(FinancialAnalysisModel analysis) async {
    try {
      await _firestore
          .collection('financial_analysis')
          .doc(analysis.userId)
          .collection('analyses')
          .doc(analysis.id)
          .set(analysis.toMap());
    } catch (e) {
      print('Error saving analysis: $e');
      rethrow;
    }
  }

  /// Obtener historial de análisis
  Future<List<FinancialAnalysisModel>> getAnalysisHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('financial_analysis')
          .doc(userId)
          .collection('analyses')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FinancialAnalysisModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting analysis history: $e');
      return [];
    }
  }

  /// Utilidad para parsear double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
