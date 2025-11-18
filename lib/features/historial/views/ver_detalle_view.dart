import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/ver_detalle_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../edit_transactions/viewmodels/edit_transactions_viwmodel.dart';
import '../../edit_transactions/views/edit_transaction_view.dart';

class VerDetalleView extends StatefulWidget {
  final String transaccionId;
  final String tipo; // 'ingreso' o 'gasto'

  const VerDetalleView({
    Key? key,
    required this.transaccionId,
    required this.tipo,
  }) : super(key: key);

  @override
  State<VerDetalleView> createState() => _VerDetalleViewState();
}

class _VerDetalleViewState extends State<VerDetalleView> {
  bool _transaccionModificada = false; // Flag para saber si se editó o eliminó

  @override
  void initState() {
    super.initState();
    // Cargar los detalles cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VerDetalleViewModel>().cargarDetalle(
        widget.transaccionId,
        widget.tipo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && _transaccionModificada) {
          // Notificar a la pantalla anterior que hubo cambios
          // El resultado ya se maneja en el pop automático
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              // Regresar con el estado de modificación
              Navigator.of(context).pop(_transaccionModificada);
            },
          ),
          title: Text(
            'Detalle de Transacción',
            style: Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          // AppBar en blanco para mayor neutralidad
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? AppColors.white,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.edit_rounded, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).colorScheme.onSurface),
                onPressed: () => _navegarAEditar(context),
                tooltip: 'Editar',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.delete_rounded, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).colorScheme.onSurface),
                onPressed: () => _mostrarDialogoEliminar(context),
                tooltip: 'Eliminar',
              ),
            ),
          ],
        ),
        body: Consumer<VerDetalleViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.error!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        viewModel.cargarDetalle(
                          widget.transaccionId,
                          widget.tipo,
                        );
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final detalle = viewModel.detalleTransaccion;
            if (detalle == null) {
              return const Center(child: Text('No se encontró la transacción'));
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header con el tipo y monto
                  _buildHeader(context, viewModel, detalle),

                  const SizedBox(height: 16),

                  // Información general
                  _buildSeccionInformacion(detalle),

                  const SizedBox(height: 16),

                  // Información específica según el tipo
                  if (detalle.tipo == 'ingreso')
                    _buildSeccionIngreso(detalle)
                  else
                    _buildSeccionGasto(detalle),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VerDetalleViewModel viewModel,
    DetalleTransaccion detalle,
  ) {
    // Símbolo de moneda fijo (dólares)
    String simboloMoneda = '\$';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: widget.tipo == 'ingreso' ? Theme.of(context).incomeGradient : Theme.of(context).expenseGradient,
        boxShadow: [
          BoxShadow(
            color: viewModel.colorTipo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono con efecto
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                viewModel.iconoTipo,
                size: 56,
                color: viewModel.colorTipo,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            viewModel.tipoFormateado,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$simboloMoneda${detalle.monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          // Mostrar número de factura si existe
          if (detalle.tipo == 'gasto' && 
              detalle.invoiceNumber != null && 
              detalle.invoiceNumber!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: viewModel.colorTipo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detalle.invoiceNumber!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: viewModel.colorTipo,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Mostrar badge de método de entrada si es IA
          if (detalle.tipo == 'gasto' && 
              detalle.entryMethod != null && 
              detalle.entryMethod!.toLowerCase() == 'ia') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.purple.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Registrado con IA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionInformacion(DetalleTransaccion detalle) {
    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Información General',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.category_rounded,
              label: 'Categoría',
              value: detalle.categoria,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.event_rounded,
              label: 'Fecha',
              value: formatoFecha.format(detalle.fecha),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.description_rounded,
              label: 'Descripción',
              value: detalle.descripcion.isNotEmpty
                  ? detalle.descripcion
                  : 'Sin descripción',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionIngreso(DetalleTransaccion detalle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Detalles del Ingreso',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (detalle.metodoPago != null && detalle.metodoPago!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.payment_rounded,
                label: 'Método de Pago',
                value: detalle.metodoPago!,
              ),
            if (detalle.metodoPago != null && detalle.metodoPago!.isNotEmpty)
              const SizedBox(height: 16),
            if (detalle.origen != null && detalle.origen!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.source_rounded,
                label: 'Origen',
                value: detalle.origen!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionGasto(DetalleTransaccion detalle) {
    return Column(
      children: [
        // Información de Identificación
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '📋 Identificación de Factura',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (detalle.invoiceNumber != null && detalle.invoiceNumber!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Número de Factura',
                    value: detalle.invoiceNumber!,
                  ),
                if (detalle.invoiceNumber != null && detalle.invoiceNumber!.isNotEmpty)
                  const SizedBox(height: 16),
                if (detalle.taxAmount != null && detalle.taxAmount! > 0)
                  _buildInfoRow(
                    icon: Icons.percent_rounded,
                    label: 'Impuestos',
                    value: '\$${detalle.taxAmount!.toStringAsFixed(2)}',
                  ),
                if (detalle.taxAmount != null && detalle.taxAmount! > 0)
                  const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.calculate_rounded,
                  label: 'Total (con impuestos)',
                  value: '\$${detalle.monto.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Información del Proveedor
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.indigo.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '🏢 Proveedor (Emisor)',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (detalle.supplierName != null && detalle.supplierName!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.store_rounded,
                    label: 'Nombre o Razón Social',
                    value: detalle.supplierName!,
                  ),
                if (detalle.supplierName != null && detalle.supplierName!.isNotEmpty)
                  const SizedBox(height: 16),
                if (detalle.supplierTaxId != null && detalle.supplierTaxId!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.badge_rounded,
                    label: 'NIF / RFC / RUT',
                    value: detalle.supplierTaxId!,
                  ),
                if (detalle.supplierTaxId != null && detalle.supplierTaxId!.isNotEmpty)
                  const SizedBox(height: 16),
                if (detalle.lugarLocal != null && detalle.lugarLocal!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Dirección',
                    value: detalle.lugarLocal!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Información del Sistema
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔧 Información del Sistema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 8),
                if (detalle.entryMethod != null && detalle.entryMethod!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.input_outlined,
                    label: 'Método de Registro',
                    value: detalle.entryMethod!,
                  ),
                if (detalle.entryMethod != null && detalle.entryMethod!.isNotEmpty)
                  const SizedBox(height: 12),
                if (detalle.createdAt != null)
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Fecha de Registro',
                    value: DateFormat('dd/MM/yyyy HH:mm').format(detalle.createdAt!),
                  ),
                if (detalle.createdAt != null)
                  const SizedBox(height: 12),
                if (detalle.scanImagePath != null && detalle.scanImagePath!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.image_outlined,
                    label: 'Imagen Escaneada',
                    value: 'Disponible',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.indigo.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navegarAEditar(BuildContext context) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => EditTransactionViewModel(),
          child: EditTransactionView(
            transaccionId: widget.transaccionId,
            tipo: widget.tipo,
          ),
        ),
      ),
    );

    // Si se editó la transacción, recargar los detalles
    if (resultado == true && mounted) {
      _transaccionModificada = true; // Marcar que se modificó

      final viewModel = context.read<VerDetalleViewModel>();
      await viewModel.cargarDetalle(widget.transaccionId, widget.tipo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Transacción actualizada'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _mostrarDialogoEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Transacción'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta transacción? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _eliminarTransaccion(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarTransaccion(BuildContext context) async {
    final viewModel = context.read<VerDetalleViewModel>();

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    final exitoso = await viewModel.eliminarTransaccion();

    // Cerrar el indicador de carga
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (exitoso) {
      if (context.mounted) {
        _transaccionModificada =
            true; // Marcar que se eliminó (también es una modificación)

        // Volver a la pantalla anterior y retornar true para indicar que se eliminó/modificó
        Navigator.of(context).pop(true);

        // Mostrar mensaje de éxito en la pantalla anterior
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Transacción eliminada. Actualizando lista...'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error ?? 'Error al eliminar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Limpiar el estado cuando se sale de la pantalla
    context.read<VerDetalleViewModel>().limpiar();
    super.dispose();
  }
}
