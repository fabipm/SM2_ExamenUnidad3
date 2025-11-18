import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/edit_transactions_viwmodel.dart';
import '../../../core/theme/app_colors.dart';

class EditTransactionView extends StatefulWidget {
  final String transaccionId;
  final String tipo; // 'ingreso' o 'gasto'

  const EditTransactionView({
    Key? key,
    required this.transaccionId,
    required this.tipo,
  }) : super(key: key);

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  final _formKey = GlobalKey<FormState>();
  late final EditTransactionViewModel _cachedViewModel;

  @override
  void initState() {
    super.initState();
    // Cargar los datos de la transacción
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cachedViewModel = context.read<EditTransactionViewModel>();
      _cachedViewModel.cargarTransaccion(
        widget.transaccionId,
        widget.tipo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = widget.tipo == 'ingreso';

    return Scaffold(
      appBar: AppBar(
        title: Text(esIngreso ? 'Editar Ingreso' : 'Editar Gasto', style: Theme.of(context).appBarTheme.titleTextStyle),
        // AppBar en blanco
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).colorScheme.onSurface),
            onPressed: _guardarCambios,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Consumer<EditTransactionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text('Cargando datos...', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          if (viewModel.error != null && !viewModel.isSaving) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error.withOpacity(0.8)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      viewModel.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.cargarTransaccion(
                        widget.transaccionId,
                        widget.tipo,
                      );
                    },
                    child: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de tipo
                    _buildTipoIndicador(esIngreso),
                    const SizedBox(height: 24),

                    // Campo Monto
                    _buildMontoField(viewModel),
                    const SizedBox(height: 16),

                    // Campo Categoría
                    _buildCategoriaField(viewModel),
                    const SizedBox(height: 16),

                    // Campo Descripción
                    _buildDescripcionField(viewModel),
                    const SizedBox(height: 16),

                    // Campos específicos según el tipo
                    if (esIngreso) ...[
                      // Fecha (solo para ingresos)
                      _buildFechaField(viewModel),
                      const SizedBox(height: 16),

                      // Método de pago
                      _buildMetodoPagoField(viewModel),
                      const SizedBox(height: 16),

                      // Origen
                      _buildOrigenField(viewModel),
                    ] else ...[
                      // Proveedor
                      _buildProveedorField(viewModel),
                      const SizedBox(height: 16),

                      // Lugar
                      _buildLugarField(viewModel),
                      const SizedBox(height: 16),

                      // Número de factura
                      _buildInvoiceNumberField(viewModel),
                      const SizedBox(height: 16),

                      // Fecha de factura
                      _buildInvoiceDateField(viewModel),
                      const SizedBox(height: 16),

                      // NIF / RUC proveedor
                      _buildSupplierTaxIdField(viewModel),
                      const SizedBox(height: 16),

                      // Monto del impuesto
                      _buildTaxAmountField(viewModel),
                      const SizedBox(height: 16),

                      // Ruta de escaneo / imagen (opcional)
                      _buildScanPathField(viewModel),
                      const SizedBox(height: 16),

                      // Método de entrada (entry method)
                      _buildEntryMethodField(viewModel),
                    ],

                    const SizedBox(height: 24),

                    // Mostrar error si existe
                    if (viewModel.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  viewModel.error!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isSaving ? null : _guardarCambios,
                        icon: viewModel.isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                ),
                              )
                            : Icon(Icons.save, color: Theme.of(context).colorScheme.onPrimary),
                        label: Text(
                          viewModel.isSaving ? 'Guardando...' : 'Guardar Cambios',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: esIngreso ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
          );
        },
      ),
    );
  }

  Widget _buildTipoIndicador(bool esIngreso) {
    final color = esIngreso ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(esIngreso ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 32),
          const SizedBox(width: 12),
          Text(
            'Editando ${esIngreso ? 'Ingreso' : 'Gasto'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.montoController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Monto',
        prefixText: '\$ ',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? AppColors.greyLight,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El monto es requerido';
        }
        final monto = double.tryParse(value);
        if (monto == null || monto <= 0) {
          return 'Ingrese un monto válido';
        }
        return null;
      },
    );
  }

  Widget _buildCategoriaField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.categoriaController,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? AppColors.greyLight,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La categoría es requerida';
        }
        return null;
      },
    );
  }

  Widget _buildDescripcionField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.descripcionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Descripción',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? AppColors.greyLight,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildFechaField(EditTransactionViewModel viewModel) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      onTap: () => _seleccionarFecha(viewModel),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Text(
          formatoFecha.format(viewModel.fechaSeleccionada),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMetodoPagoField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.metodoPagoController,
      decoration: InputDecoration(
        labelText: 'Método de Pago',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El método de pago es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildOrigenField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.origenController,
      decoration: InputDecoration(
        labelText: 'Origen',
        prefixIcon: const Icon(Icons.source),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El origen es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildProveedorField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.proveedorController,
      decoration: InputDecoration(
        labelText: 'Proveedor',
        prefixIcon: const Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El proveedor es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildLugarField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.lugarController,
      decoration: InputDecoration(
        labelText: 'Lugar',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El lugar es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildInvoiceNumberField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.invoiceNumberController,
      decoration: InputDecoration(
        labelText: 'Número de factura (opcional)',
        prefixIcon: const Icon(Icons.receipt_long),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildInvoiceDateField(EditTransactionViewModel viewModel) {
    final formato = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () => _seleccionarInvoiceDate(viewModel),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de factura (opcional)',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Text(
          formato.format(viewModel.invoiceDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSupplierTaxIdField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.supplierTaxIdController,
      decoration: InputDecoration(
        labelText: 'NIF / RUC del proveedor (opcional)',
        prefixIcon: const Icon(Icons.badge_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && value.length > 50) {
          return 'El NIF/RUC es demasiado largo';
        }
        return null;
      },
    );
  }

  Widget _buildTaxAmountField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.taxAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Impuesto (opcional)',
        prefixIcon: const Icon(Icons.percent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final numero = double.tryParse(value);
        if (numero == null) return 'Ingrese un número válido';
        if (numero < 0) return 'El impuesto no puede ser negativo';
        return null;
      },
    );
  }

  Widget _buildScanPathField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.scanImagePathController,
      decoration: InputDecoration(
        labelText: 'Ruta de escaneo / imagen (opcional)',
        prefixIcon: const Icon(Icons.camera_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildEntryMethodField(EditTransactionViewModel viewModel) {
    return TextFormField(
      controller: viewModel.entryMethodController,
      decoration: InputDecoration(
        labelText: 'Método de ingreso (opcional)',
        prefixIcon: const Icon(Icons.input),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Future<void> _seleccionarFecha(EditTransactionViewModel viewModel) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: viewModel.fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      // Ahora seleccionar la hora
      final TimeOfDay? horaSeleccionada = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(viewModel.fechaSeleccionada),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.green,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (horaSeleccionada != null) {
        final nuevaFecha = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month,
          fechaSeleccionada.day,
          horaSeleccionada.hour,
          horaSeleccionada.minute,
        );
        viewModel.actualizarFecha(nuevaFecha);
      }
    }
  }

  Future<void> _seleccionarInvoiceDate(EditTransactionViewModel viewModel) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: viewModel.invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      viewModel.actualizarInvoiceDate(fechaSeleccionada);
    }
  }

  Future<void> _guardarCambios() async {
    // Validar formulario
    if (_formKey.currentState?.validate() ?? false) {
      final viewModel = context.read<EditTransactionViewModel>();

      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Confirmar cambios'),
            content: const Text(
              '¿Estás seguro de que deseas guardar estos cambios?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );

      if (confirmar == true) {
        final exitoso = await viewModel.guardarCambios();

        if (exitoso && mounted) {
          // Mostrar mensaje de éxito y regresar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Cambios guardados exitosamente')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Regresar a la pantalla anterior con true para indicar que se editó
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  void dispose() {
    // Use cached reference to avoid unsafe ancestor lookup during dispose
    try {
      _cachedViewModel.limpiar();
    } catch (_) {
      // ignore: avoid_print
      // if cached viewModel isn't available for any reason, ignore cleanup
    }
    super.dispose();
  }
}
