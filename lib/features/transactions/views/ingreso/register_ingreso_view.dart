import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/registrar_ingreso_viewmodel.dart';
import '../../viewmodels/categoria_viewmodel.dart';
import '../../models/categoria_model.dart';
import '../../services/validaciones.dart';
import '../gestionar_categorias_view.dart';

// Provider para el ViewModel
final registrarIngresoViewModelProvider =
    ChangeNotifierProvider<RegistrarIngresoViewModel>(
      (ref) => RegistrarIngresoViewModel(),
    );

// Provider para el ViewModel de categorías
final categoriaIngresoViewModelProvider =
    ChangeNotifierProvider<CategoriaViewModel>((ref) => CategoriaViewModel());

class RegisterIngresoView extends ConsumerStatefulWidget {
  final String idUsuario;
  final Map<String, dynamic>? datosIniciales;

  const RegisterIngresoView({
    Key? key,
    required this.idUsuario,
    this.datosIniciales,
  }) : super(key: key);

  @override
  ConsumerState<RegisterIngresoView> createState() =>
      _RegisterIngresoViewState();
}

class _RegisterIngresoViewState extends ConsumerState<RegisterIngresoView> {
  @override
  void initState() {
    super.initState();
    // Cargar categorías al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(categoriaIngresoViewModelProvider)
          .cargarCategorias(widget.idUsuario, TipoCategoria.ingreso);

      // Si vienen datos iniciales desde la IA, prellenar el formulario
      if (widget.datosIniciales != null) {
        final viewModel = ref.read(registrarIngresoViewModelProvider);
        final datos = widget.datosIniciales!;

        viewModel.montoController.text = datos['monto']?.toString() ?? '';
        viewModel.descripcionController.text =
            datos['descripcion']?.toString() ?? '';
        viewModel.metodoPagoController.text =
            datos['metodoPago']?.toString() ?? '';
        viewModel.origenController.text = datos['origen']?.toString() ?? '';

        if (datos['fecha'] != null && datos['fecha'].toString().isNotEmpty) {
          try {
            viewModel.setFecha(DateTime.parse(datos['fecha'].toString()));
          } catch (e) {
            viewModel.setFecha(DateTime.now());
          }
        }

        final categoria = datos['categoria']?.toString();
        if (categoria != null && categoria.isNotEmpty) {
          viewModel.setCategoria(categoria);
        }
      }
      else {
        // Registro manual: establecer fecha por defecto al día de hoy
        final viewModel = ref.read(registrarIngresoViewModelProvider);
        viewModel.setFecha(DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(registrarIngresoViewModelProvider);
    final categoriaViewModel = ref.watch(categoriaIngresoViewModelProvider);
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ingreso'),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 4,
      ),
      body: Center(
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Datos del Ingreso',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: viewModel.montoController,
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: validarMonto,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      // Seleccionar fecha
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: viewModel.fecha ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        // Seleccionar hora inmediatamente después
                        final initialTime = viewModel.fecha != null
                            ? TimeOfDay.fromDateTime(viewModel.fecha!)
                            : TimeOfDay.fromDateTime(DateTime.now());
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        final combined = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime?.hour ?? initialTime.hour,
                          pickedTime?.minute ?? initialTime.minute,
                        );

                        viewModel.setFecha(combined);
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Fecha y hora',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        controller: TextEditingController(
                          text: viewModel.fecha != null
                              ? "${viewModel.fecha!.day.toString().padLeft(2, '0')}/${viewModel.fecha!.month.toString().padLeft(2, '0')}/${viewModel.fecha!.year} ${viewModel.fecha!.hour.toString().padLeft(2, '0')}:${viewModel.fecha!.minute.toString().padLeft(2, '0')}"
                              : '',
                        ),
                        validator: (_) => validarFecha(viewModel.fecha),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.descripcionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: validarDescripcion,
                  ),
                  const SizedBox(height: 16),
                  // Sección de categorías con botón para gestionar
                  Row(
                    children: [
                      Expanded(
                        child: categoriaViewModel.isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Cargando categorías...'),
                                  ],
                                ),
                              )
                            : DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Categoría',
                                  prefixIcon: const Icon(Icons.category),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  helperText: categoriaViewModel.obtenerNombresCategorias(TipoCategoria.ingreso).isEmpty
                                      ? 'No hay categorías disponibles'
                                      : null,
                                ),
                                value: viewModel.categoriaSeleccionada,
                                items: categoriaViewModel
                                    .obtenerNombresCategorias(TipoCategoria.ingreso)
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    )
                                    .toList(),
                                onChanged: viewModel.setCategoria,
                                validator: validarCategoria,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GestionarCategoriasView(
                                  idUsuario: widget.idUsuario,
                                  tipo: TipoCategoria.ingreso,
                                ),
                              ),
                            );
                            // Recargar categorías después de volver
                            categoriaViewModel.cargarCategorias(
                              widget.idUsuario,
                              TipoCategoria.ingreso,
                            );
                          },
                          icon: const Icon(Icons.settings, color: Colors.green),
                          tooltip: 'Gestionar categorías',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.metodoPagoController,
                    decoration: InputDecoration(
                      labelText: 'Método de Pago',
                      prefixIcon: const Icon(Icons.payment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: validarMetodoPago,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.origenController,
                    decoration: InputDecoration(
                      labelText: 'Origen',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: validarOrigen,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Registrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await viewModel.guardarIngresoEnFirebase(
                            widget.idUsuario,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingreso registrado correctamente',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
