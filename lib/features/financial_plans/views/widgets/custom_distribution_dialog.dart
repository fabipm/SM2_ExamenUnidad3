import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/financial_plan_model.dart';
import '../../../transactions/models/categoria_model.dart';
import '../../../transactions/services/categoria_service.dart';
import '../../viewmodels/financial_plans_viewmodel.dart';
import '../../../auth/providers/auth_providers.dart';

class CustomDistributionDialog extends ConsumerStatefulWidget {
  final String planName;
  final int year;
  final int month;
  final double totalBudget;
  final VoidCallback? onPlanCreated;

  const CustomDistributionDialog({
    super.key,
    required this.planName,
    required this.year,
    required this.month,
    required this.totalBudget,
    this.onPlanCreated,
  });

  @override
  ConsumerState<CustomDistributionDialog> createState() =>
      _CustomDistributionDialogState();
}

class _CustomDistributionDialogState
    extends ConsumerState<CustomDistributionDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _budgetDistribution = {};
  final CategoriaService _categoriaService = CategoriaService();
  List<CategoriaModel> _allCategories = [];
  List<CategoriaModel> _selectedCategories = [];
  bool _isLoading = false;
  bool _loadingCategories = true;

  double get _totalAssigned =>
      _budgetDistribution.values.fold(0.0, (a, b) => a + b);
  double get _remaining => widget.totalBudget - _totalAssigned;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Obtener el ID del usuario autenticado
      final authState = ref.read(authStateProvider);
      List<CategoriaModel> allCategories = [];
      
      await authState.when(
        data: (user) async {
          if (user != null) {
            // Cargar todas las categorías de egreso del usuario (incluye las por defecto)
            allCategories = await _categoriaService.obtenerCategorias(
              user.id,
              TipoCategoria.egreso,
            );
          }
        },
        loading: () async {},
        error: (error, stack) async {},
      );

      if (allCategories.isEmpty) {
        // Fallback: si no hay categorías, algo salió mal
        print('No se encontraron categorías de egreso');
        setState(() {
          _loadingCategories = false;
        });
        return;
      }

      _allCategories = allCategories;

      // Inicialmente seleccionar las más comunes
      _selectedCategories = [
        allCategories.firstWhere(
          (cat) => cat.nombre.toLowerCase() == 'alimentación',
          orElse: () => allCategories.first,
        ),
        allCategories.firstWhere(
          (cat) => cat.nombre.toLowerCase() == 'transporte',
          orElse: () => allCategories.length > 1 ? allCategories[1] : allCategories.first,
        ),
      ];

      setState(() {
        _loadingCategories = false;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
      setState(() {
        _loadingCategories = false;
      });
    }
  }

  void _addCategory(CategoriaModel category) {
    if (!_selectedCategories.any((cat) => cat.id == category.id)) {
      setState(() {
        _selectedCategories.add(category);
        _controllers[category.id] = TextEditingController();
        _budgetDistribution[category.id] = 0.0;
      });
    }
  }

  void _removeCategory(String categoryId) {
    setState(() {
      _selectedCategories.removeWhere((cat) => cat.id == categoryId);
      _controllers[categoryId]?.dispose();
      _controllers.remove(categoryId);
      _budgetDistribution.remove(categoryId);
    });
  }

  void _showAddCategoryDialog() {
    final availableCategories = _allCategories
        .where(
          (cat) =>
              !_selectedCategories.any((selected) => selected.id == cat.id),
        )
        .toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya has agregado todas las categorías disponibles'),
          backgroundColor: AppColors.yellowPastel,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Categoría'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCategories.length,
            itemBuilder: (context, index) {
              final category = availableCategories[index];
              final isPersonal = category.esPersonalizada;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPersonal
                        ? AppColors.pinkPastel.withOpacity(0.1)
                        : AppColors.blueClassic.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(category.nombre),
                    color: isPersonal
                        ? AppColors.pinkPastel
                        : AppColors.blueClassic,
                    size: 20,
                  ),
                ),
                title: Text(category.nombre),
                subtitle: Text(
                  isPersonal ? 'Categoría personal' : 'Categoría básica',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPersonal
                        ? AppColors.pinkPastel
                        : AppColors.greyDark,
                  ),
                ),
                onTap: () {
                  _addCategory(category);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'vivienda':
        return Icons.home;
      case 'alimentación':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'entretenimiento':
        return Icons.movie;
      case 'salud':
        return Icons.local_hospital;
      case 'educación':
        return Icons.school;
      case 'ropa':
        return Icons.checkroom;
      default:
        return Icons.shopping_cart;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución Personalizada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.blackGrey,
              ),
            ),
            Text(
              widget.planName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.greyDark,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Budget Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Presupuesto Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greyDark,
                      ),
                    ),
                    Text(
                      'S/ ${widget.totalBudget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackGrey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Restante',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greyDark,
                      ),
                    ),
                    Text(
                      'S/ ${_remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _remaining < 0
                            ? AppColors.redCoral
                            : AppColors.greenJade,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de categorías scrollable
          Expanded(
            child: _loadingCategories
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Asignar presupuesto por categoría:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blackGrey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Categorías seleccionadas
                        ..._selectedCategories.map(
                          (category) => _buildCategoryBudgetCard(category),
                        ),

                        const SizedBox(height: 8),

                        // Botón para agregar más categorías
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAddCategoryDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar categoría'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Botones
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
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
                    onPressed: (_isLoading || _remaining.abs() > 0.01)
                        ? null
                        : _createCustomPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pinkPastel,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Crear Plan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetCard(CategoriaModel category) {
    if (!_controllers.containsKey(category.id)) {
      _controllers[category.id] = TextEditingController();
      _budgetDistribution[category.id] = 0.0;
    }

    // Definir iconos y colores por defecto según el nombre de la categoría
    IconData icon = Icons.category;
    Color color = AppColors.greyDark;

    switch (category.nombre.toLowerCase()) {
      case 'vivienda':
        icon = Icons.home;
        color = AppColors.blueClassic;
        break;
      case 'alimentación':
        icon = Icons.restaurant;
        color = AppColors.greenJade;
        break;
      case 'transporte':
        icon = Icons.directions_car;
        color = AppColors.yellowPastel;
        break;
      case 'entretenimiento':
        icon = Icons.movie;
        color = AppColors.pinkPastel;
        break;
      case 'salud':
        icon = Icons.local_hospital;
        color = AppColors.redCoral;
        break;
      case 'educación':
        icon = Icons.school;
        color = AppColors.blueLavender;
        break;
      default:
        icon = Icons.shopping_cart;
        color = AppColors.greyDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          category.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: _selectedCategories.length > 2
            ? GestureDetector(
                onTap: () => _removeCategory(category.id),
                child: const Text(
                  'Tocar para eliminar',
                  style: TextStyle(fontSize: 11, color: AppColors.redCoral),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedCategories.length > 2)
              IconButton(
                onPressed: () => _removeCategory(category.id),
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.redCoral,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _controllers[category.id],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  prefixText: 'S/ ',
                  hintText: '0.00',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _budgetDistribution[category.id] =
                        double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCustomPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customBudgets = <CategoryBudget>[];

      for (var entry in _budgetDistribution.entries) {
        if (entry.value > 0) {
          final category = _selectedCategories.firstWhere(
            (cat) => cat.id == entry.key,
          );
          customBudgets.add(
            CategoryBudget(
              categoryId: category.id,
              categoryName: category.nombre,
              budgetAmount: entry.value,
              categoryType: category.tipo,
            ),
          );
        }
      }

      final success = await ref
          .read(financialPlansViewModelProvider.notifier)
          .createFinancialPlan(
            planName: widget.planName,
            year: widget.year,
            month: widget.month,
            totalBudget: widget.totalBudget,
            planType: PlanType.custom,
            customBudgets: customBudgets,
          );

      if (success && context.mounted) {
        widget.onPlanCreated?.call();
        Navigator.of(context).pop(true); // Retorna true indicando éxito

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan personalizado creado exitosamente'),
            backgroundColor: AppColors.pinkPastel,
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
}
