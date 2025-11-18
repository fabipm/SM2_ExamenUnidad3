import 'package:flutter/material.dart';
import '../../models/financial_plan_model.dart';
import '../../../../core/theme/app_colors.dart';

class PlanCard extends StatelessWidget {
  final FinancialPlanModel plan;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onGenerateReport;

  const PlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onGenerateReport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y mes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.planName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.greyMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${plan.monthName} ${plan.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.greyMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getPlanTypeColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                plan.planType.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getPlanTypeColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null || onGenerateReport != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                          case 'report':
                            onGenerateReport?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onGenerateReport != null)
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 16,
                                  color: AppColors.pinkPastel,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Generar Reporte',
                                  style: TextStyle(color: AppColors.pinkPastel),
                                ),
                              ],
                            ),
                          ),
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: AppColors.redCoral,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: AppColors.redCoral),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Información de presupuesto
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gastado',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.greyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'S/ ${plan.totalSpent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: plan.isOverBudget
                                ? AppColors.redCoral
                                : AppColors.blackGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Presupuesto',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.greyMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'S/ ${plan.totalBudget.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blackGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getProgressColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${plan.totalUsagePercentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greyMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        plan.isOverBudget
                            ? 'Sobre presupuesto'
                            : 'S/ ${plan.remainingBudget.toStringAsFixed(2)} restante',
                        style: TextStyle(
                          fontSize: 12,
                          color: plan.isOverBudget
                              ? AppColors.redCoral
                              : AppColors.greenJade,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (plan.totalUsagePercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.greyLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(),
                    ),
                    minHeight: 6,
                  ),
                ],
              ),

              if (plan.categoryBudgets.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${plan.categoryBudgets.length} categoría${plan.categoryBudgets.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: AppColors.greyMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPlanTypeColor() {
    switch (plan.planType) {
      case PlanType.standard:
        return AppColors.blueClassic;
      case PlanType.custom:
        return AppColors.pinkPastel;
      case PlanType.ai:
        return AppColors.yellowPastel;
    }
  }

  Color _getProgressColor() {
    if (plan.isOverBudget) {
      return AppColors.redCoral;
    } else if (plan.totalUsagePercentage > 80) {
      return AppColors.yellowPastel;
    } else {
      return AppColors.greenJade;
    }
  }
}
