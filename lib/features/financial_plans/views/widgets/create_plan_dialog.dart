import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/financial_plan_model.dart';
import '../../viewmodels/financial_plans_viewmodel.dart';
import 'custom_distribution_dialog.dart';

class CreatePlanDialog extends ConsumerStatefulWidget {
  final VoidCallback? onPlanCreated;

  const CreatePlanDialog({super.key, this.onPlanCreated});

  @override
  ConsumerState<CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends ConsumerState<CreatePlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _totalBudgetController = TextEditingController();

  late int _selectedMonth;
  late int _selectedYear;
  PlanType _selectedPlanType = PlanType.standard;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _totalBudgetController.dispose();
    super.dispose();
  }

  void _showAIPlanPreviewDialog(FinancialPlanModel aiPlan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.blueClassic,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Plan Generado con IA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presupuesto Total: S/ ${aiPlan.totalBudget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Distribución por categorías
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: aiPlan.categoryBudgets.length,
                  itemBuilder: (context, index) {
                    final budget = aiPlan.categoryBudgets[index];
                    final percentage = (budget.budgetAmount / aiPlan.totalBudget * 100);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    budget.categoryName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'S/ ${budget.budgetAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.blueClassic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.blueClassic,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _acceptAIPlan(aiPlan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blueClassic,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Aceptar Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptAIPlan(FinancialPlanModel aiPlan) async {
    Navigator.of(context).pop(); // Cerrar preview
    
    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(financialPlansViewModelProvider.notifier)
        .createAIPlanFromPreview(aiPlan);

    setState(() {
      _isLoading = false;
    });

    if (context.mounted) {
      if (success) {
        Navigator.of(context).pop(); // Cerrar diálogo de creación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan creado con IA exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el plan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header fijo
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blueClassic.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.blueClassic,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Crear Nuevo Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackGrey,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del plan
                      TextFormField(
                        controller: _planNameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Plan',
                          hintText: 'Ej: Plan Enero 2024',
                          prefixIcon: const Icon(
                            Icons.drive_file_rename_outline,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa un nombre para el plan';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Mes y Año
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _selectedMonth,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Mes',
                                prefixIcon: const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              items: List.generate(12, (index) {
                                final monthNames = [
                                  'Ene',
                                  'Feb',
                                  'Mar',
                                  'Abr',
                                  'May',
                                  'Jun',
                                  'Jul',
                                  'Ago',
                                  'Sep',
                                  'Oct',
                                  'Nov',
                                  'Dic',
                                ];
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(
                                    monthNames[index],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedMonth = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Año',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              items: List.generate(5, (index) {
                                final year = DateTime.now().year + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(
                                    year.toString(),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedYear = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Presupuesto total
                      TextFormField(
                        controller: _totalBudgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: _selectedPlanType == PlanType.ai
                              ? 'Presupuesto Total (IA lo distribuirá)'
                              : 'Presupuesto Total',
                          hintText: '0.00',
                          prefixText: 'S/ ',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          helperText: _selectedPlanType == PlanType.ai
                              ? 'La IA distribuirá este monto basándose en tus gastos anteriores'
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el presupuesto total';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Por favor ingresa un monto válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tipo de plan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blackGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                RadioListTile<PlanType>(
                                  title: const Text('Estándar'),
                                  subtitle: const Text(
                                    'Distribución automática entre todas las categorías disponibles',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: PlanType.standard,
                                  groupValue: _selectedPlanType,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPlanType = value;
                                      });
                                    }
                                  },
                                  activeColor: AppColors.blueClassic,
                                ),
                                const Divider(height: 1),
                                RadioListTile<PlanType>(
                                  title: const Text('Personalizado'),
                                  subtitle: const Text(
                                    'Define tú mismo cuánto asignar a cada categoría',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: PlanType.custom,
                                  groupValue: _selectedPlanType,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPlanType = value;
                                      });
                                    }
                                  },
                                  activeColor: AppColors.blueClassic,
                                ),
                                const Divider(height: 1),
                                RadioListTile<PlanType>(
                                  title: Row(
                                    children: [
                                      const Text('IA '),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Automático',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.blackGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: const Text(
                                    'Plan generado con IA basado en tus gastos del mes anterior',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: PlanType.ai,
                                  groupValue: _selectedPlanType,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPlanType = value;
                                      });
                                    }
                                  },
                                  activeColor: AppColors.blueClassic,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createPlan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blueClassic,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Crear Plan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar si ya existe un plan para el mes/año seleccionado
      final existingPlan = await ref
          .read(financialPlansViewModelProvider.notifier)
          .getPlanByMonth(year: _selectedYear, month: _selectedMonth);

      if (existingPlan != null) {
        setState(() {
          _isLoading = false;
        });

        if (context.mounted) {
          _showPlanExistsDialog(existingPlan);
        }
        return;
      }

      // Si es modo IA, generar preview del plan
      if (_selectedPlanType == PlanType.ai) {
        final totalBudget = double.parse(_totalBudgetController.text);
        
        final aiPlan = await ref
            .read(financialPlansViewModelProvider.notifier)
            .generateAIPlanPreview(
              targetYear: _selectedYear,
              targetMonth: _selectedMonth,
              totalBudget: totalBudget,
            );

        setState(() {
          _isLoading = false;
        });

        if (context.mounted) {
          if (aiPlan != null) {
            // Mostrar diálogo de preview
            _showAIPlanPreviewDialog(aiPlan);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al generar plan con IA. Verifica que tengas gastos del mes anterior.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      final totalBudget = double.parse(_totalBudgetController.text);

      // Si es personalizado, abrir el diálogo de distribución
      if (_selectedPlanType == PlanType.custom) {
        setState(() {
          _isLoading = false;
        });

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CustomDistributionDialog(
              planName: _planNameController.text.trim(),
              year: _selectedYear,
              month: _selectedMonth,
              totalBudget: totalBudget,
              onPlanCreated: widget.onPlanCreated,
            ),
          );
        }
        return;
      }

      // Para estándar, crear directamente
      final success = await ref
          .read(financialPlansViewModelProvider.notifier)
          .createFinancialPlan(
            planName: _planNameController.text.trim(),
            year: _selectedYear,
            month: _selectedMonth,
            totalBudget: totalBudget,
            planType: _selectedPlanType,
          );

      if (success && context.mounted) {
        Navigator.of(context).pop();
        widget.onPlanCreated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getPlanCreatedMessage(_selectedPlanType)),
            backgroundColor: _getPlanColor(_selectedPlanType),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear plan: $e'),
            backgroundColor: AppColors.redCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPlanCreatedMessage(PlanType planType) {
    switch (planType) {
      case PlanType.standard:
        return 'Plan estándar creado con distribución automática';
      case PlanType.custom:
        return 'Plan personalizado creado exitosamente';
      case PlanType.ai:
        return 'Plan con IA creado exitosamente';
    }
  }

  Color _getPlanColor(PlanType planType) {
    switch (planType) {
      case PlanType.standard:
        return AppColors.blueClassic;
      case PlanType.custom:
        return AppColors.pinkPastel;
      case PlanType.ai:
        return AppColors.yellowPastel;
    }
  }

  void _showPlanExistsDialog(FinancialPlanModel existingPlan) {
    final monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.yellowPastel.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppColors.yellowPastel,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Plan ya existe', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ya tienes un plan para ${monthNames[_selectedMonth - 1]} $_selectedYear:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingPlan.planName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Presupuesto: S/ ${existingPlan.totalBudget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Tipo: ${existingPlan.planType.displayName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Qué te gustaría hacer?',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectDifferentMonth();
            },
            child: const Text('Elegir otro mes'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _replaceExistingPlan(existingPlan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redCoral,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Reemplazar'),
          ),
        ],
      ),
    );
  }

  void _selectDifferentMonth() {
    // Cambiar a un mes diferente automáticamente
    setState(() {
      _selectedMonth = _selectedMonth == 12 ? 1 : _selectedMonth + 1;
      if (_selectedMonth == 1) {
        _selectedYear++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cambiado a ${_getMonthName(_selectedMonth)} $_selectedYear',
        ),
        backgroundColor: AppColors.blueClassic,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return monthNames[month - 1];
  }

  void _replaceExistingPlan(FinancialPlanModel existingPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar reemplazo'),
        content: const Text(
          '¿Estás seguro de que deseas reemplazar el plan existente? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAndCreateNew(existingPlan.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redCoral,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Sí, reemplazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAndCreateNew(String existingPlanId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Eliminar el plan existente
      final deleted = await ref
          .read(financialPlansViewModelProvider.notifier)
          .deleteFinancialPlan(existingPlanId);

      if (deleted) {
        // Crear el nuevo plan
        await _proceedWithPlanCreation();
      } else {
        throw Exception('No se pudo eliminar el plan existente');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reemplazar plan: $e'),
            backgroundColor: AppColors.redCoral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _proceedWithPlanCreation() async {
    final totalBudget = double.parse(_totalBudgetController.text);

    // Si es personalizado, abrir el diálogo de distribución
    if (_selectedPlanType == PlanType.custom) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CustomDistributionDialog(
            planName: _planNameController.text.trim(),
            year: _selectedYear,
            month: _selectedMonth,
            totalBudget: totalBudget,
            onPlanCreated: widget.onPlanCreated,
          ),
        );
      }
      return;
    }

    // Para estándar, crear directamente
    final success = await ref
        .read(financialPlansViewModelProvider.notifier)
        .createFinancialPlan(
          planName: _planNameController.text.trim(),
          year: _selectedYear,
          month: _selectedMonth,
          totalBudget: totalBudget,
          planType: _selectedPlanType,
        );

    if (success && context.mounted) {
      Navigator.of(context).pop();
      widget.onPlanCreated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getPlanCreatedMessage(_selectedPlanType)),
          backgroundColor: _getPlanColor(_selectedPlanType),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
