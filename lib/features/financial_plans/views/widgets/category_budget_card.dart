import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/financial_plan_model.dart';

class CategoryBudgetCard extends StatefulWidget {
  final CategoryBudget categoryBudget;
  final Function(double)? onUpdateSpent;

  const CategoryBudgetCard({
    super.key,
    required this.categoryBudget,
    this.onUpdateSpent,
  });

  @override
  State<CategoryBudgetCard> createState() => _CategoryBudgetCardState();
}

class _CategoryBudgetCardState extends State<CategoryBudgetCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.categoryBudget.spentAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.categoryBudget.isOverBudget
              ? theme.colorScheme.error.withOpacity(0.3)
              : theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y botón editar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.categoryBudget.categoryName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onUpdateSpent != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _saveChanges();
                        }
                      });
                    },
                    icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                      size: 22,
                      color: _isEditing
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isEditing
                          ? theme.colorScheme.tertiary.withOpacity(0.1)
                          : theme.colorScheme.onSurface.withOpacity(0.05),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Información de presupuesto y gasto
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gastado',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isEditing)
                        SizedBox(
                          width: 120,
                          height: 44,
                          child: TextField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              prefixText: 'S/ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Text(
                          'S/ ${widget.categoryBudget.spentAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.categoryBudget.isOverBudget
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'S/ ${widget.categoryBudget.budgetAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getProgressColor().withOpacity(0.15),
                        _getProgressColor().withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.categoryBudget.usagePercentage.toInt()}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _getProgressColor(),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de progreso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.categoryBudget.isOverBudget
                          ? 'Sobre: S/ ${(widget.categoryBudget.spentAmount - widget.categoryBudget.budgetAmount).toStringAsFixed(2)}'
                          : 'Restante: S/ ${widget.categoryBudget.remainingAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.categoryBudget.isOverBudget
                            ? theme.colorScheme.error
                            : theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (widget.categoryBudget.usagePercentage / 100)
                        .clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getProgressColor(),
                            _getProgressColor().withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Mensaje de advertencia si está sobre presupuesto
            if (widget.categoryBudget.isOverBudget) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.error.withOpacity(0.1),
                      theme.colorScheme.error.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Has superado el presupuesto!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    // Generar color basado en el nombre de la categoría para consistencia
    final hash = widget.categoryBudget.categoryName.hashCode;
    final colors = [
      const Color(0xFF0A4D8C), // Navy blue (primary)
      const Color(0xFF10A37F), // Emerald green (tertiary)
      const Color(0xFFDC3545), // Sophisticated red (error)
      const Color(0xFFFF8C42), // Orange
      const Color(0xFF9B59B6), // Purple
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getProgressColor() {
    final theme = Theme.of(context);
    if (widget.categoryBudget.isOverBudget) {
      return theme.colorScheme.error;
    } else if (widget.categoryBudget.usagePercentage > 80) {
      return const Color(0xFFFF8C42); // Orange for warning
    } else {
      return theme.colorScheme.tertiary;
    }
  }

  void _saveChanges() {
    final newAmount =
        double.tryParse(_controller.text) ?? widget.categoryBudget.spentAmount;
    if (newAmount != widget.categoryBudget.spentAmount &&
        widget.onUpdateSpent != null) {
      widget.onUpdateSpent!(newAmount);
    }
  }
}
