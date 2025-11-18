import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/financial_plan_model.dart';
import '../viewmodels/financial_plans_viewmodel.dart';
import 'widgets/custom_distribution_dialog.dart';

class CreatePlanPage extends ConsumerStatefulWidget {
  final VoidCallback? onPlanCreated;

  const CreatePlanPage({super.key, this.onPlanCreated});

  @override
  ConsumerState<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends ConsumerState<CreatePlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _totalBudgetController = TextEditingController();

  late int _selectedMonth;
  late int _selectedYear;
  PlanType _selectedPlanType = PlanType.standard;
  bool _isLoading = false;
  bool _showingPreview = false;
  FinancialPlanModel? _aiPlanPreview;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    
    // Auto-rellenar nombre del plan
    _updatePlanName();
  }

  void _updatePlanName() {
    _planNameController.text = 'Plan ${_getMonthName(_selectedMonth)} $_selectedYear';
  }

  String _getMonthName(int month) {
    const monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return monthNames[month];
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _totalBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.blackGrey),
        ),
        title: Text(
          _showingPreview ? 'Vista Previa del Plan' : 'Crear Nuevo Plan',
          style: const TextStyle(
            color: AppColors.blackGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _showingPreview && _aiPlanPreview != null
          ? _buildPreviewView()
          : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono y título
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.blueClassic.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_chart,
                      color: AppColors.blueClassic,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configura tu Plan Financiero',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define tu presupuesto y deja que la IA te ayude',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Nombre del plan
            const Text(
              'Nombre del Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.blackGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _planNameController,
              decoration: InputDecoration(
                hintText: 'Ej: Plan Enero 2024',
                prefixIcon: const Icon(Icons.drive_file_rename_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre para el plan';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Período (solo mes actual)
            const Text(
              'Período',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.blackGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blueClassic.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.blueClassic.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.blueClassic,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes Actual',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blackGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMonthName(_selectedMonth) + ' $_selectedYear',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.blueClassic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.blueClassic,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Presupuesto total
            const Text(
              'Presupuesto Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.blackGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _totalBudgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'S/ ',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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

            const SizedBox(height: 24),

            // Tipo de plan
            const Text(
              'Tipo de Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.blackGrey,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlanTypeCard(
              type: PlanType.standard,
              icon: Icons.grid_view,
              title: 'Estándar',
              description: 'Distribución automática entre todas las categorías',
            ),
            const SizedBox(height: 12),
            _buildPlanTypeCard(
              type: PlanType.ai,
              icon: Icons.auto_awesome,
              title: 'Inteligente (IA)',
              description: 'La IA distribuye basándose en tu historial de gastos',
              badge: 'Recomendado',
            ),
            const SizedBox(height: 12),
            _buildPlanTypeCard(
              type: PlanType.custom,
              icon: Icons.tune,
              title: 'Personalizado',
              description: 'Tú decides cuánto asignar a cada categoría',
            ),

            const SizedBox(height: 32),

            // Botón de crear
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueClassic,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedPlanType == PlanType.ai
                            ? 'Generar Plan con IA'
                            : 'Crear Plan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTypeCard({
    required PlanType type,
    required IconData icon,
    required String title,
    required String description,
    String? badge,
  }) {
    final isSelected = _selectedPlanType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlanType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blueClassic.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppColors.blueClassic : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blueClassic : Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.blueClassic : AppColors.blackGrey,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blueClassic,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<PlanType>(
              value: type,
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
    );
  }

  Widget _buildPreviewView() {
    final plan = _aiPlanPreview!;
    
    return Column(
      children: [
        // Header con información del plan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.blueClassic, AppColors.blueClassic.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Plan Generado con IA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.planName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Presupuesto Total: S/ ${plan.totalBudget.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Distribución por categorías
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plan.categoryBudgets.length,
            itemBuilder: (context, index) {
              final budget = plan.categoryBudgets[index];
              final percentage = (budget.budgetAmount / plan.totalBudget * 100);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                                color: AppColors.blackGrey,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blueClassic.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'S/ ${budget.budgetAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blueClassic,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 10,
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
                              fontWeight: FontWeight.w600,
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showingPreview = false;
                        _aiPlanPreview = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Rechazar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _acceptAIPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueClassic,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
        ),
      ],
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

        if (aiPlan != null) {
          setState(() {
            _aiPlanPreview = aiPlan;
            _showingPreview = true;
          });
        } else {
          if (context.mounted) {
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
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomDistributionDialog(
                planName: _planNameController.text,
                year: _selectedYear,
                month: _selectedMonth,
                totalBudget: totalBudget,
                onPlanCreated: () {
                  widget.onPlanCreated?.call();
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
          
          // Si se creó el plan exitosamente, cerrar esta pantalla también
          if (result == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
        return;
      }

      // Crear plan estándar
      final success = await ref
          .read(financialPlansViewModelProvider.notifier)
          .createFinancialPlan(
            planName: _planNameController.text,
            year: _selectedYear,
            month: _selectedMonth,
            totalBudget: totalBudget,
            planType: _selectedPlanType,
          );

      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        if (success) {
          widget.onPlanCreated?.call();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan creado exitosamente'),
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptAIPlan() async {
    if (_aiPlanPreview == null) return;

    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(financialPlansViewModelProvider.notifier)
        .createAIPlanFromPreview(_aiPlanPreview!);

    setState(() {
      _isLoading = false;
    });

    if (context.mounted) {
      if (success) {
        widget.onPlanCreated?.call();
        Navigator.of(context).pop();
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

  void _showPlanExistsDialog(FinancialPlanModel existingPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan Existente'),
        content: Text(
          'Ya existe un plan para este período: "${existingPlan.planName}". ¿Deseas reemplazarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar reemplazo de plan
            },
            child: const Text(
              'Reemplazar',
              style: TextStyle(color: AppColors.redCoral),
            ),
          ),
        ],
      ),
    );
  }
}
