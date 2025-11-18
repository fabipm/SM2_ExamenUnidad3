import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/financial_plans_service.dart';

export '../viewmodels/financial_plans_viewmodel.dart'
    show
        financialPlansViewModelProvider,
        currentMonthPlanProvider,
        availableCategoriesProvider;

/// Provider principal para el servicio de financial plans
final financialPlansServiceProvider = Provider<FinancialPlansService>((ref) {
  return FinancialPlansService();
});
