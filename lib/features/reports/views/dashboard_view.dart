import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/dashboard_stats_model.dart';
import 'dart:math' as math;

// Provider para el DashboardViewModel
final dashboardViewModelProvider =
    ChangeNotifierProvider.autoDispose<DashboardViewModel>((ref) {
      final viewModel = DashboardViewModel();
      viewModel.loadDashboardData();
      return viewModel;
    });

/// Vista principal del Dashboard Financiero
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => viewModel.refresh(),
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.error != null
            ? _buildErrorState(context, viewModel.error!)
            : viewModel.dashboardStats == null
            ? _buildEmptyState(context)
            : _buildDashboardContent(context, viewModel),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar datos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(dashboardViewModelProvider).loadDashboardData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay datos disponibles',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra transacciones para ver tu dashboard',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    final stats = viewModel.dashboardStats!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de mes
          _buildMonthSelector(context, viewModel),
          const SizedBox(height: 16),

          // Resumen general del mes
          _buildMonthlySummary(context, stats.monthlyStats),
          const SizedBox(height: 24),

          // Gráfico de distribución de gastos
          if (stats.gastosPorCategoria.isNotEmpty) ...[
            _buildSectionTitle(context, 'Distribución de Gastos'),
            const SizedBox(height: 12),
            _buildExpensesChart(context, stats),
            const SizedBox(height: 24),
          ],

          // Lista de categorías de gastos
          if (stats.gastosPorCategoria.isNotEmpty) ...[
            _buildSectionTitle(context, 'Gastos por Categoría'),
            const SizedBox(height: 12),
            _buildCategoryList(
              context,
              stats.gastosPorCategoria,
              stats.monthlyStats.totalGastos,
            ),
            const SizedBox(height: 24),
          ],

          // Mensaje cuando no hay gastos registrados
          if (stats.gastosPorCategoria.isEmpty &&
              stats.monthlyStats.totalGastos == 0) ...[
            _buildNoExpensesMessage(context),
            const SizedBox(height: 24),
          ],

          // Estado de planes financieros
          if (stats.planesActivos.isNotEmpty) ...[
            _buildSectionTitle(context, 'Planes Financieros'),
            const SizedBox(height: 12),
            _buildFinancialPlansList(context, stats.planesActivos),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: viewModel.previousMonth,
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
            Text(
              '${viewModel.getMonthName(viewModel.selectedMonth)} ${viewModel.selectedYear}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            IconButton(
              onPressed: viewModel.nextMonth,
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildNoExpensesMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin gastos registrados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra tus gastos para ver gráficos y estadísticas detalladas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(BuildContext context, MonthlyStats stats) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance del Mes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stats.isPositive
                        ? theme.colorScheme.tertiary.withOpacity(0.12)
                        : theme.colorScheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    stats.isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: stats.isPositive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'S/ ${_formatCurrency(stats.balance)}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: stats.isPositive
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.onSurface.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ingresos y Gastos
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Ingresos',
                    stats.totalIngresos,
                    theme.colorScheme.tertiary,
                    Icons.arrow_downward_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.onSurface.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    'Gastos',
                    stats.totalGastos,
                    theme.colorScheme.error,
                    Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.08),
                    theme.colorScheme.primary.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    context,
                    '${stats.cantidadTransacciones}',
                    'Transacciones',
                    Icons.receipt_long_rounded,
                  ),
                  _buildInfoChip(
                    context,
                    '${stats.savingsPercentage.toStringAsFixed(1)}%',
                    'Ahorro',
                    Icons.savings_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'S/ ${_formatCurrency(amount)}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensesChart(BuildContext context, DashboardStatsModel stats) {
    final totalGastos = stats.monthlyStats.totalGastos;
    if (totalGastos <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: PieChartPainter(
                  categories: stats.gastosPorCategoria,
                  total: totalGastos,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/ ${_formatCurrency(totalGastos)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: stats.gastosPorCategoria.take(5).map((cat) {
                final color = _getCategoryColor(
                  stats.gastosPorCategoria.indexOf(cat),
                );
                return _buildLegendItem(context, cat.categoryName, color);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<CategoryStats> categories,
    double total,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.onSurface.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final percentage = category.calculatePercentage(total);
          final color = _getCategoryColor(index);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.categoryName),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${category.transactionCount} ${category.transactionCount == 1 ? 'transacción' : 'transacciones'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'S/ ${_formatCurrency(category.amount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialPlansList(
    BuildContext context,
    List<PlanSummary> plans,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: plans.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.onSurface.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final plan = plans[index];
          final statusColor = _getPlanStatusColor(plan.status);

          return Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withOpacity(0.15),
                      statusColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getPlanStatusIcon(plan.status),
                  color: statusColor,
                  size: 24,
                ),
              ),
              title: Text(
                plan.planName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              subtitle: Text(
                '${plan.categoriesCount} ${plan.categoriesCount == 1 ? 'categoría' : 'categorías'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              children: [
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.06),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (plan.usagePercentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Información detallada
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPlanDetail(
                      context,
                      'Presupuesto',
                      'S/ ${_formatCurrency(plan.totalBudget)}',
                      theme.colorScheme.primary,
                    ),
                    _buildPlanDetail(
                      context,
                      'Gastado',
                      'S/ ${_formatCurrency(plan.totalSpent)}',
                      statusColor,
                    ),
                    _buildPlanDetail(
                      context,
                      'Restante',
                      'S/ ${_formatCurrency(plan.remainingAmount)}',
                      theme.colorScheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Porcentaje
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Usado: ${plan.usagePercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanDetail(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF0A4D8C), // Navy blue (primary)
      const Color(0xFFDC3545), // Sophisticated red (error)
      const Color(0xFF10A37F), // Emerald green (tertiary)
      const Color(0xFFFF8C42), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF16A085), // Teal
      const Color(0xFFE74C3C), // Coral
      const Color(0xFF3498DB), // Sky blue
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('alimento') || name.contains('comida')) {
      return Icons.restaurant_rounded;
    } else if (name.contains('transporte')) {
      return Icons.directions_car_rounded;
    } else if (name.contains('salud')) {
      return Icons.medical_services_rounded;
    } else if (name.contains('educación') || name.contains('educacion')) {
      return Icons.school_rounded;
    } else if (name.contains('entretenimiento')) {
      return Icons.movie_rounded;
    } else if (name.contains('vivienda')) {
      return Icons.home_rounded;
    } else if (name.contains('ropa')) {
      return Icons.checkroom_rounded;
    }
    return Icons.category_rounded;
  }

  Color _getPlanStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.healthy:
        return Colors.green;
      case PlanStatus.caution:
        return Colors.orange;
      case PlanStatus.warning:
        return Colors.deepOrange;
      case PlanStatus.exceeded:
        return Colors.red;
    }
  }

  IconData _getPlanStatusIcon(PlanStatus status) {
    switch (status) {
      case PlanStatus.healthy:
        return Icons.check_circle_rounded;
      case PlanStatus.caution:
        return Icons.warning_amber_rounded;
      case PlanStatus.warning:
        return Icons.error_outline_rounded;
      case PlanStatus.exceeded:
        return Icons.dangerous_rounded;
    }
  }
}

/// Custom Painter para el gráfico circular (pie chart)
class PieChartPainter extends CustomPainter {
  final List<CategoryStats> categories;
  final double total;

  PieChartPainter({required this.categories, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    double startAngle = -math.pi / 2;

    final colors = [
      const Color(0xFF0A4D8C), // Navy blue (primary)
      const Color(0xFFDC3545), // Sophisticated red (error)
      const Color(0xFF10A37F), // Emerald green (tertiary)
      const Color(0xFFFF8C42), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF16A085), // Teal
      const Color(0xFFE74C3C), // Coral
      const Color(0xFF3498DB), // Sky blue
    ];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final sweepAngle = (category.amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Dibujar círculo blanco en el centro para efecto "donut"
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.6, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
