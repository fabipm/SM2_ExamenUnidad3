import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_analysis_model.dart';
import '../services/financial_analysis_service.dart';

/// Provider del servicio de análisis financiero
final financialAnalysisServiceProvider = Provider<FinancialAnalysisService>((
  ref,
) {
  return FinancialAnalysisService();
});

/// Provider del período de análisis seleccionado
final selectedPeriodProvider = StateProvider<AnalysisPeriod>((ref) {
  final now = DateTime.now();
  return AnalysisPeriod.monthly(now.year, now.month);
});

/// Provider para el tipo de período seleccionado
final selectedPeriodTypeProvider = StateProvider<PeriodType>((ref) {
  return PeriodType.monthly;
});

/// Provider para obtener el análisis actual
final currentAnalysisProvider =
    FutureProvider.family<FinancialAnalysisModel, String>((ref, userId) async {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final service = ref.read(financialAnalysisServiceProvider);
      final period = ref.watch(selectedPeriodProvider);

      return await service.analyzeFinances(userId: userId, period: period);
    });

/// Provider para el historial de análisis
final analysisHistoryProvider =
    FutureProvider.family<List<FinancialAnalysisModel>, String>((
      ref,
      userId,
    ) async {
      if (userId.isEmpty) {
        return [];
      }

      final service = ref.read(financialAnalysisServiceProvider);
      return await service.getAnalysisHistory(userId, limit: 10);
    });

/// Provider para estadísticas rápidas (cache del último análisis)
final quickStatsProvider = Provider.family<Map<String, dynamic>?, String>((
  ref,
  userId,
) {
  final analysisAsync = ref.watch(currentAnalysisProvider(userId));

  return analysisAsync.when(
    data: (analysis) => {
      'totalIncome': analysis.summary.totalIncome,
      'totalExpenses': analysis.summary.totalExpenses,
      'balance': analysis.summary.balance,
      'savingsRate': analysis.summary.savingsRate,
      'transactionCount': analysis.summary.transactionCount,
      'averageExpense': analysis.summary.averageExpense,
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
