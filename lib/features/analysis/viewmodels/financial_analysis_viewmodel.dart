import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_analysis_model.dart';
import '../services/financial_analysis_service.dart';

/// Estado del análisis financiero
class FinancialAnalysisState {
  final FinancialAnalysisModel? currentAnalysis;
  final List<FinancialAnalysisModel> history;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final AnalysisPeriod selectedPeriod;

  FinancialAnalysisState({
    this.currentAnalysis,
    this.history = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    AnalysisPeriod? selectedPeriod,
  }) : selectedPeriod =
           selectedPeriod ??
           AnalysisPeriod.monthly(DateTime.now().year, DateTime.now().month);

  FinancialAnalysisState copyWith({
    FinancialAnalysisModel? currentAnalysis,
    List<FinancialAnalysisModel>? history,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    AnalysisPeriod? selectedPeriod,
    bool clearError = false,
    bool clearAnalysis = false,
  }) {
    return FinancialAnalysisState(
      currentAnalysis: clearAnalysis
          ? null
          : (currentAnalysis ?? this.currentAnalysis),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

/// ViewModel para el análisis financiero
class FinancialAnalysisViewModel extends StateNotifier<FinancialAnalysisState> {
  final FinancialAnalysisService _service;
  final String userId;

  FinancialAnalysisViewModel({
    required FinancialAnalysisService service,
    required this.userId,
  }) : _service = service,
       super(FinancialAnalysisState()) {
    _loadHistory();
  }

  /// Cargar historial de análisis
  Future<void> _loadHistory() async {
    try {
      final history = await _service.getAnalysisHistory(userId);
      state = state.copyWith(history: history);

      // Si no hay un análisis cargado actualmente para el período seleccionado,
      // intentar cargar uno desde el historial; si no existe, ejecutar análisis automáticamente.
      FinancialAnalysisModel? existing;
      for (final a in history) {
        if (a.period.type == state.selectedPeriod.type &&
            a.period.startDate == state.selectedPeriod.startDate &&
            a.period.endDate == state.selectedPeriod.endDate) {
          existing = a;
          break;
        }
      }

      if (existing != null) {
        // Cargar análisis existente en el estado
        state = state.copyWith(currentAnalysis: existing);
      } else {
        // No hay análisis guardado para el período actual: ejecutar análisis automáticamente
        // Ejecutar en un microtask para evitar reentrancias en el constructor
        Future.microtask(() async {
          try {
            await runAnalysis();
          } catch (_) {
            // Silenciar errores aquí; runAnalysis maneja sus propios errores
          }
        });
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  /// Ejecutar análisis financiero
  Future<void> runAnalysis() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final analysis = await _service.analyzeFinances(
        userId: userId,
        period: state.selectedPeriod,
      );

      state = state.copyWith(currentAnalysis: analysis, isLoading: false);

      // Guardar automáticamente después de ejecutar el análisis
      try {
        await saveCurrentAnalysis();
      } catch (e) {
        // Si falla el guardado automático, sólo registrar el error pero no bloquear
        print('Error guardando análisis automáticamente: $e');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al ejecutar análisis: ${e.toString()}',
      );
    }
  }

  /// Guardar análisis actual
  Future<void> saveCurrentAnalysis() async {
    if (state.currentAnalysis == null) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await _service.saveAnalysis(state.currentAnalysis!);

      // Recargar historial
      await _loadHistory();

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar análisis: ${e.toString()}',
      );
    }
  }

  /// Cambiar período de análisis
  void changePeriod(AnalysisPeriod period) {
    // Al cambiar el período, intentar cargar un análisis guardado para ese período
    FinancialAnalysisModel? existing;
    for (final a in state.history) {
      if (a.period.type == period.type &&
          a.period.startDate == period.startDate &&
          a.period.endDate == period.endDate) {
        existing = a;
        break;
      }
    }

    if (existing != null) {
      // Cargar análisis guardado y establecer período
      state = state.copyWith(selectedPeriod: period, clearError: true);
      loadAnalysis(existing);
    } else {
      // No hay análisis guardado para este periodo: limpiar análisis actual pero no ejecutar automáticamente
      state = state.copyWith(selectedPeriod: period, clearAnalysis: true, clearError: true);
      // Ejecutar análisis automáticamente cuando no existe uno guardado para el período seleccionado
      Future.microtask(() async {
        try {
          await runAnalysis();
        } catch (_) {}
      });
    }
  }

  /// Establecer período mensual
  void setMonthlyPeriod(int year, int month) {
    changePeriod(AnalysisPeriod.monthly(year, month));
  }

  /// Establecer período trimestral
  void setQuarterlyPeriod(int year, int quarter) {
    changePeriod(AnalysisPeriod.quarterly(year, quarter));
  }

  /// Establecer período anual
  void setYearlyPeriod(int year) {
    changePeriod(AnalysisPeriod.yearly(year));
  }

  /// Establecer período personalizado
  void setCustomPeriod(DateTime start, DateTime end) {
    changePeriod(
      AnalysisPeriod(startDate: start, endDate: end, type: PeriodType.custom),
    );
  }

  /// Navegar al mes anterior
  void previousMonth() {
    if (state.selectedPeriod.type != PeriodType.monthly) return;

    final currentDate = state.selectedPeriod.startDate;
    final previousMonth = DateTime(
      currentDate.month == 1 ? currentDate.year - 1 : currentDate.year,
      currentDate.month == 1 ? 12 : currentDate.month - 1,
    );

    setMonthlyPeriod(previousMonth.year, previousMonth.month);
  }

  /// Navegar al mes siguiente
  void nextMonth() {
    if (state.selectedPeriod.type != PeriodType.monthly) return;

    final currentDate = state.selectedPeriod.startDate;
    final nextMonth = DateTime(
      currentDate.month == 12 ? currentDate.year + 1 : currentDate.year,
      currentDate.month == 12 ? 1 : currentDate.month + 1,
    );

    // No permitir análisis de meses futuros
    final now = DateTime.now();
    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year && nextMonth.month > now.month)) {
      return;
    }

    setMonthlyPeriod(nextMonth.year, nextMonth.month);
  }

  /// Cargar análisis guardado
  void loadAnalysis(FinancialAnalysisModel analysis) {
    state = state.copyWith(
      currentAnalysis: analysis,
      selectedPeriod: analysis.period,
    );
  }

  /// Limpiar errores
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Limpiar análisis actual
  void clearAnalysis() {
    state = state.copyWith(clearAnalysis: true);
  }
}

/// Provider del ViewModel
final financialAnalysisViewModelProvider =
    StateNotifierProvider.family<
      FinancialAnalysisViewModel,
      FinancialAnalysisState,
      String
    >((ref, userId) {
      final service = ref.watch(financialAnalysisServiceProvider);
      return FinancialAnalysisViewModel(service: service, userId: userId);
    });

/// Provider del servicio
final financialAnalysisServiceProvider = Provider<FinancialAnalysisService>((
  ref,
) {
  return FinancialAnalysisService();
});

/// Providers de conveniencia
final isAnalysisLoadingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(financialAnalysisViewModelProvider(userId)).isLoading;
});

final currentAnalysisProvider =
    Provider.family<FinancialAnalysisModel?, String>((ref, userId) {
      return ref
          .watch(financialAnalysisViewModelProvider(userId))
          .currentAnalysis;
    });

final analysisHistoryProvider =
    Provider.family<List<FinancialAnalysisModel>, String>((ref, userId) {
      return ref.watch(financialAnalysisViewModelProvider(userId)).history;
    });

final selectedPeriodProvider = Provider.family<AnalysisPeriod, String>((
  ref,
  userId,
) {
  return ref.watch(financialAnalysisViewModelProvider(userId)).selectedPeriod;
});
