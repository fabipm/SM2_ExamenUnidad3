import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/financial_analysis_model.dart';

/// Sección de patrones de gasto detectados
class PatternsSection extends StatelessWidget {
  final List<SpendingPattern> patterns;

  const PatternsSection({super.key, required this.patterns});

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patterns.length,
      itemBuilder: (context, index) {
        final pattern = patterns[index];
        return _buildPatternCard(context, pattern);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.greenJade.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Excelente!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.greenJade,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'No se detectaron patrones inusuales en tus gastos',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.greyDark),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(BuildContext context, SpendingPattern pattern) {
    final severityColor = _getSeverityColor(pattern.severity);
    final typeIcon = _getPatternIcon(pattern.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: severityColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono de patrón
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: severityColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Título
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSeverityLabel(pattern.severity),
                          style: TextStyle(
                            color: severityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              pattern.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: AppColors.blackGrey,
              ),
            ),
            const SizedBox(height: 12),

            // Categoría e impacto
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greyLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 16,
                        color: AppColors.greyDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pattern.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: AppColors.greyDark,
                      ),
                      Text(
                        '\$${pattern.impact.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return AppColors.greenJade;
      case SeverityLevel.medium:
        return AppColors.yellowPastel;
      case SeverityLevel.high:
        return Colors.orange;
      case SeverityLevel.critical:
        return AppColors.redCoral;
    }
  }

  String _getSeverityLabel(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return 'Bajo';
      case SeverityLevel.medium:
        return 'Medio';
      case SeverityLevel.high:
        return 'Alto';
      case SeverityLevel.critical:
        return 'Crítico';
    }
  }

  IconData _getPatternIcon(PatternType type) {
    switch (type) {
      case PatternType.recurring:
        return Icons.repeat;
      case PatternType.seasonal:
        return Icons.calendar_today;
      case PatternType.unusual:
        return Icons.warning_amber;
      case PatternType.increasing:
        return Icons.trending_up;
      case PatternType.decreasing:
        return Icons.trending_down;
    }
  }
}
