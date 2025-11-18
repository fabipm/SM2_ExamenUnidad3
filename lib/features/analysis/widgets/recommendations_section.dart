import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/financial_analysis_model.dart';

/// Sección de recomendaciones generadas por IA
class RecommendationsSection extends StatelessWidget {
  final List<AIRecommendation> recommendations;

  const RecommendationsSection({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return _buildRecommendationCard(context, recommendation);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: AppColors.yellowPastel.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin recomendaciones',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.greyDark),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    AIRecommendation recommendation,
  ) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    final typeIcon = _getTypeIcon(recommendation.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon, color: priorityColor, size: 28),
        ),
        title: Text(
          recommendation.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBadge(
                  context,
                  _getPriorityLabel(recommendation.priority),
                  priorityColor,
                ),
                const SizedBox(width: 8),
                if (recommendation.potentialSavings > 0)
                  _buildBadge(
                    context,
                    'Ahorro: \$${recommendation.potentialSavings.toStringAsFixed(0)}',
                    AppColors.greenJade,
                  ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // Descripción
          Text(
            recommendation.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.blackGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Categoría afectada
          if (recommendation.category.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greyLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category,
                    size: 18,
                    color: AppColors.greyDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Categoría: ${recommendation.category}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Pasos de acción
          if (recommendation.actionSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '📋 Pasos de acción:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...recommendation.actionSteps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Botón de acción
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showImplementDialog(context, recommendation);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como implementada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: priorityColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return AppColors.greenJade;
      case PriorityLevel.medium:
        return AppColors.yellowPastel;
      case PriorityLevel.high:
        return Colors.orange;
      case PriorityLevel.urgent:
        return AppColors.redCoral;
    }
  }

  String _getPriorityLabel(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return 'Prioridad Baja';
      case PriorityLevel.medium:
        return 'Prioridad Media';
      case PriorityLevel.high:
        return 'Prioridad Alta';
      case PriorityLevel.urgent:
        return 'Urgente';
    }
  }

  IconData _getTypeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.reduce:
        return Icons.trending_down;
      case RecommendationType.optimize:
        return Icons.tune;
      case RecommendationType.budget:
        return Icons.account_balance_wallet;
      case RecommendationType.save:
        return Icons.savings;
      case RecommendationType.alert:
        return Icons.warning_amber;
    }
  }

  void _showImplementDialog(
    BuildContext context,
    AIRecommendation recommendation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.greenJade),
            SizedBox(width: 12),
            Text('¡Excelente decisión!'),
          ],
        ),
        content: Text(
          '¿Has implementado esta recomendación?\n\n"${recommendation.title}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Recomendación marcada como implementada'),
                  backgroundColor: AppColors.greenJade,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
