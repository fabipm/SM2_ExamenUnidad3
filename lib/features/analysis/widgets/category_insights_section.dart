import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/financial_analysis_model.dart';

/// Sección de insights por categoría
class CategoryInsightsSection extends StatelessWidget {
  final List<CategoryInsight> insights;

  const CategoryInsightsSection({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return _buildCategoryCard(context, insight, index);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.greyDark.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin datos de categorías',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.greyDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryInsight insight,
    int index,
  ) {
    final categoryColor = AppColors.getCategoryColor(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetailsDialog(context, insight),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono de categoría
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(insight.categoryName),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nombre y monto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.categoryName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${insight.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Porcentaje
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${insight.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: insight.percentage / 100,
                  backgroundColor: AppColors.greyLight,
                  color: categoryColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              // Estadísticas adicionales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    context,
                    Icons.receipt_long,
                    '${insight.transactionCount} transacciones',
                  ),
                  _buildStat(
                    context,
                    Icons.calculate,
                    'Prom: \$${insight.averageTransaction.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.greyDark),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.greyDark),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('comida') || name.contains('alimento')) {
      return Icons.restaurant;
    } else if (name.contains('transporte') || name.contains('gasolina')) {
      return Icons.directions_car;
    } else if (name.contains('salud') || name.contains('médico')) {
      return Icons.local_hospital;
    } else if (name.contains('entretenimiento') || name.contains('ocio')) {
      return Icons.movie;
    } else if (name.contains('servicios') ||
        name.contains('luz') ||
        name.contains('agua')) {
      return Icons.build;
    } else if (name.contains('educación') || name.contains('libros')) {
      return Icons.school;
    } else if (name.contains('ropa') || name.contains('vestuario')) {
      return Icons.shopping_bag;
    }
    return Icons.category;
  }

  void _showDetailsDialog(BuildContext context, CategoryInsight insight) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(insight.categoryName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Total gastado',
              '\$${insight.totalAmount.toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Porcentaje',
              '${insight.percentage.toStringAsFixed(1)}%',
            ),
            _buildDetailRow('Transacciones', '${insight.transactionCount}'),
            _buildDetailRow(
              'Promedio',
              '\$${insight.averageTransaction.toStringAsFixed(2)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
