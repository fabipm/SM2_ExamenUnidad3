import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/financial_plans_viewmodel.dart';
import '../models/financial_plan_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../transactions/views/gestionar_categorias_view.dart';
import '../../transactions/models/categoria_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../reports/services/report_service.dart';
import 'create_plan_page.dart';
import 'plans_history_page.dart';
import 'widgets/plan_card.dart';
import 'widgets/category_budget_card.dart';

class FinancialPlansPage extends ConsumerStatefulWidget {
  const FinancialPlansPage({super.key});

  @override
  ConsumerState<FinancialPlansPage> createState() => _FinancialPlansPageState();
}

class _FinancialPlansPageState extends ConsumerState<FinancialPlansPage> {
  bool _showCurrentPlan = true;

  @override
  void initState() {
    super.initState();
    // Cargar planes al iniciar
    Future.microtask(
      () => ref
          .read(financialPlansViewModelProvider.notifier)
          .loadFinancialPlans(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financialPlansState = ref.watch(financialPlansViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: financialPlansState.when(
        data: (state) => _buildContent(context, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Planes Financieros',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: theme.colorScheme.onPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            switch (value) {
              case 'toggle_view':
                setState(() {
                  _showCurrentPlan = !_showCurrentPlan;
                });
                break;
              case 'categories':
                _navigateToCategories(context);
                break;
              case 'history':
                _navigateToHistory(context);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text('Historial de Planes'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_view',
              child: Row(
                children: [
                  Icon(
                    _showCurrentPlan
                        ? Icons.list_rounded
                        : Icons.calendar_today_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _showCurrentPlan
                        ? 'Ver todos los planes'
                        : 'Ver plan actual',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'categories',
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gestionar Categorías',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, FinancialPlansState state) {
    switch (state) {
      case FinancialPlansInitial():
        return _buildEmptyState(context);
      case FinancialPlansLoading():
        return const Center(child: CircularProgressIndicator());
      case FinancialPlansLoaded():
        return _showCurrentPlan
            ? _buildCurrentPlanView(context, state)
            : _buildAllPlansView(context, state);
      case FinancialPlansError():
        return _buildErrorState(context, state.message);
    }
  }

  Widget _buildCurrentPlanView(
    BuildContext context,
    FinancialPlansLoaded state,
  ) {
    final currentPlan = state.currentPlan;

    if (currentPlan == null) {
      return _buildNoCurrentPlanState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con resumen del plan
          _buildPlanSummaryCard(context, currentPlan),

          const SizedBox(height: 20),

          // Botón para ver categorías
          _buildSectionButton(
            context,
            title: 'Ver Categorías',
            icon: Icons.category_outlined,
            color: AppColors.yellowPastel,
            onPressed: () => _navigateToCategories(context),
          ),

          const SizedBox(height: 20),

          // Lista de categorías con presupuesto
          _buildCategoriesList(context, currentPlan),

          const SizedBox(height: 20),

          // Gráfico de gastos por mes (placeholder)
          _buildMonthlyChart(context, currentPlan),
        ],
      ),
    );
  }

  Widget _buildAllPlansView(BuildContext context, FinancialPlansLoaded state) {
    final plans = state.plans;

    if (plans.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlanCard(
            plan: plan,
            onTap: () => _showPlanDetails(context, plan),
            onEdit: () => _editPlan(context, plan),
            onDelete: () => _deletePlan(context, plan),
            onGenerateReport: () => _generatePlanReport(context, plan),
          ),
        );
      },
    );
  }

  Widget _buildPlanSummaryCard(BuildContext context, FinancialPlanModel plan) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.planName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${plan.monthName} ${plan.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progreso general
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gasto Actual',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/ ${plan.totalSpent.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${plan.totalUsagePercentage.toInt()}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Límite: S/ ${plan.totalBudget.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            // Indicador de sincronización automática
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sincronización automática activa',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de progreso premium
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (plan.totalUsagePercentage / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: plan.isOverBudget
                          ? [
                              theme.colorScheme.error,
                              theme.colorScheme.error.withOpacity(0.8),
                            ]
                          : [
                              theme.colorScheme.tertiary,
                              theme.colorScheme.tertiary.withOpacity(0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, FinancialPlanModel plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presupuesto por Categoría',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blackGrey,
          ),
        ),
        const SizedBox(height: 12),

        ...plan.categoryBudgets.map(
          (categoryBudget) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CategoryBudgetCard(
              categoryBudget: categoryBudget,
              onUpdateSpent: (newAmount) => _updateCategorySpent(
                context,
                plan.id,
                categoryBudget.categoryId,
                newAmount,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(BuildContext context, FinancialPlanModel plan) {
    // Por ahora, placeholder para el gráfico
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progreso Mensual',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.blackGrey,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: AppColors.greyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gráfico próximamente',
                      style: TextStyle(
                        color: AppColors.greyMedium,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(100 - plan.totalUsagePercentage).toStringAsFixed(1)}% menos que el mes pasado',
                      style: TextStyle(
                        color: AppColors.greyMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCurrentPlanState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.blueClassic.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 64,
                color: AppColors.blueClassic,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No tienes plan para este mes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blackGrey,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Crea tu primer plan financiero para ${DateTime.now().month == 1
                  ? 'Enero'
                  : DateTime.now().month == 2
                  ? 'Febrero'
                  : DateTime.now().month == 3
                  ? 'Marzo'
                  : DateTime.now().month == 4
                  ? 'Abril'
                  : DateTime.now().month == 5
                  ? 'Mayo'
                  : DateTime.now().month == 6
                  ? 'Junio'
                  : DateTime.now().month == 7
                  ? 'Julio'
                  : DateTime.now().month == 8
                  ? 'Agosto'
                  : DateTime.now().month == 9
                  ? 'Septiembre'
                  : DateTime.now().month == 10
                  ? 'Octubre'
                  : DateTime.now().month == 11
                  ? 'Noviembre'
                  : 'Diciembre'} y toma el control de tus gastos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.greyMedium),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => _showCreatePlanDialog(context),
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text(
                'Crear Plan del Mes',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueClassic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.greenJade.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings,
                size: 64,
                color: AppColors.greenJade,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '¡Comienza a planificar!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.blackGrey,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Crea tu primer plan financiero y organiza tus gastos de manera inteligente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.greyMedium),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => _showCreatePlanDialog(context),
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text(
                'Crear Primer Plan',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenJade,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.redCoral,
            ),

            const SizedBox(height: 16),

            const Text(
              'Error al cargar planes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blackGrey,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.greyMedium),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => ref
                  .read(financialPlansViewModelProvider.notifier)
                  .loadFinancialPlans(),
              icon: const Icon(Icons.refresh, color: AppColors.white),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueClassic,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showCreatePlanDialog(context),
      backgroundColor: AppColors.blueClassic,
      child: const Icon(Icons.add, color: AppColors.white),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePlanPage(
          onPlanCreated: () {
            ref
                .read(financialPlansViewModelProvider.notifier)
                .loadFinancialPlans();
          },
        ),
      ),
    );
  }

  void _navigateToCategories(BuildContext context) {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GestionarCategoriasView(
            idUsuario: user.id,
            tipo: TipoCategoria.egreso,
          ),
        ),
      );
    }
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlansHistoryPage(),
      ),
    );
  }

  void _showPlanDetails(BuildContext context, FinancialPlanModel plan) {
    // TODO: Implementar página de detalles del plan
  }

  void _editPlan(BuildContext context, FinancialPlanModel plan) {
    // TODO: Implementar edición del plan
  }

  void _deletePlan(BuildContext context, FinancialPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el plan "${plan.planName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(financialPlansViewModelProvider.notifier)
                  .deleteFinancialPlan(plan.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plan eliminado exitosamente')),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.redCoral),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCategorySpent(
    BuildContext context,
    String planId,
    String categoryId,
    double newAmount,
  ) async {
    final success = await ref
        .read(financialPlansViewModelProvider.notifier)
        .updateCategorySpent(
          planId: planId,
          categoryId: categoryId,
          newSpentAmount: newAmount,
        );

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gasto actualizado')));
    }
  }

  Future<void> _generatePlanReport(
    BuildContext context,
    FinancialPlanModel plan,
  ) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.pinkPastel),
                SizedBox(height: 16),
                Text('Generando reporte...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final reportService = ReportService();

      final authState = ref.read(authStateProvider);
      String? userId;

      authState.whenData((user) {
        if (user != null) {
          userId = user.id;
        }
      });

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final reportData = await reportService.getPlanComplianceData(
        userId: userId!,
        planId: plan.id,
      );

      if (reportData == null) {
        throw Exception('No se pudo obtener los datos del plan');
      }

      final pdfFile = await reportService.generatePlanCompliancePDF(reportData);

      if (context.mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga

        // Mostrar opciones para compartir/guardar
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reporte generado exitosamente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.share, color: AppColors.pinkPastel),
                  title: const Text('Compartir PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    await reportService.sharePDF(pdfFile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.print, color: AppColors.blueLavender),
                  title: const Text('Imprimir PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    await reportService.printPDF(pdfFile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.greenJade),
                  title: const Text('Guardado en Documentos'),
                  subtitle: Text(
                    pdfFile.path,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: AppColors.redCoral,
          ),
        );
      }
    }
  }
}
