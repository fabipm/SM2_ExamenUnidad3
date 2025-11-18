import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/financial_analysis_viewmodel.dart';
import '../models/financial_analysis_model.dart';

/// Selector de período de análisis
class PeriodSelector extends ConsumerWidget {
  final String userId;
  final VoidCallback? onPeriodChanged;

  const PeriodSelector({super.key, required this.userId, this.onPeriodChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider(userId));
    final viewModel = ref.read(
      financialAnalysisViewModelProvider(userId).notifier,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Período de análisis',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.greyDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Selector de tipo de período
          Row(
            children: [
              _buildPeriodTypeButton(
                context,
                ref,
                'Mes',
                PeriodType.monthly,
                Icons.calendar_month,
              ),
              const SizedBox(width: 8),
              _buildPeriodTypeButton(
                context,
                ref,
                'Trimestre',
                PeriodType.quarterly,
                Icons.calendar_view_month,
              ),
              const SizedBox(width: 8),
              _buildPeriodTypeButton(
                context,
                ref,
                'Año',
                PeriodType.yearly,
                Icons.calendar_today,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Navegación de período (solo para mensual)
          if (period.type == PeriodType.monthly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    viewModel.previousMonth();
                    onPeriodChanged?.call();
                  },
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.blueClassic,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      period.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackGrey,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    viewModel.nextMonth();
                    onPeriodChanged?.call();
                  },
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.blueClassic,
                ),
              ],
            )
          else
            Center(
              child: Text(
                period.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodTypeButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    PeriodType type,
    IconData icon,
  ) {
    final currentPeriod = ref.watch(selectedPeriodProvider(userId));
    final isSelected = currentPeriod.type == type;
    final viewModel = ref.read(
      financialAnalysisViewModelProvider(userId).notifier,
    );

    return Expanded(
      child: InkWell(
        onTap: () {
          final now = DateTime.now();
          switch (type) {
            case PeriodType.monthly:
              viewModel.setMonthlyPeriod(now.year, now.month);
              break;
            case PeriodType.quarterly:
              final quarter = ((now.month - 1) ~/ 3) + 1;
              viewModel.setQuarterlyPeriod(now.year, quarter);
              break;
            case PeriodType.yearly:
              viewModel.setYearlyPeriod(now.year);
              break;
            case PeriodType.custom:
              break;
          }
          onPeriodChanged?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blueClassic : AppColors.greyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.greyDark,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.greyDark,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
