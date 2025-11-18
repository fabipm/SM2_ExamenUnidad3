import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/models/registro_ingreso_model.dart';
import '../../transactions/models/register_bill_model.dart';
import '../services/validaciones.dart';

class EditTransactionViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Controllers para los campos del formulario
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();

  // Campos específicos para ingresos
  final TextEditingController metodoPagoController = TextEditingController();
  final TextEditingController origenController = TextEditingController();

  // Campos específicos para gastos
  final TextEditingController proveedorController = TextEditingController();
  final TextEditingController lugarController = TextEditingController();
  // Campos adicionales para factura/gasto
  final TextEditingController invoiceNumberController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime get invoiceDate => _invoiceDate;
  final TextEditingController supplierTaxIdController = TextEditingController();
  final TextEditingController taxAmountController = TextEditingController();
  final TextEditingController scanImagePathController = TextEditingController();
  final TextEditingController entryMethodController = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();
  DateTime get fechaSeleccionada => _fechaSeleccionada;

  String? _transaccionId;
  String? _tipoTransaccion;
  String? _idUsuario;
  Factura? _facturaOriginal; // Para mantener los campos que no se editan

  @override
  void dispose() {
    montoController.dispose();
    descripcionController.dispose();
    categoriaController.dispose();
    metodoPagoController.dispose();
    origenController.dispose();
    proveedorController.dispose();
    lugarController.dispose();
    // Disponer nuevos controllers
    invoiceNumberController.dispose();
    supplierTaxIdController.dispose();
    taxAmountController.dispose();
    scanImagePathController.dispose();
    entryMethodController.dispose();
    super.dispose();
  }

  /// Carga los datos de una transacción para editarla
  Future<void> cargarTransaccion(String id, String tipo) async {
    _isLoading = true;
    _error = null;
    _transaccionId = id;
    _tipoTransaccion = tipo;
    notifyListeners();

    try {
      if (tipo == 'ingreso') {
        await _cargarIngreso(id);
      } else if (tipo == 'gasto') {
        await _cargarGasto(id);
      } else {
        throw Exception('Tipo de transacción no válido');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar la transacción: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarIngreso(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('ingresos')
          .doc(id)
          .get();

      if (!doc.exists) {
        throw Exception('Ingreso no encontrado');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Ingreso ingreso = Ingreso.fromMap(data);

      // Llenar los controllers con los datos existentes
      montoController.text = ingreso.monto.toString();
      descripcionController.text = ingreso.descripcion;
      categoriaController.text = ingreso.categoria;
      metodoPagoController.text = ingreso.metodoPago;
      origenController.text = ingreso.origen;
      _fechaSeleccionada = ingreso.fecha;
      _idUsuario = ingreso.idUsuario;
    } catch (e) {
      throw Exception('Error al cargar ingreso: $e');
    }
  }

  Future<void> _cargarGasto(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('facturas')
          .doc(id)
          .get();

      if (!doc.exists) {
        throw Exception('Gasto no encontrado');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Factura factura = Factura.fromMap(data);

      // Guardar la factura original para mantener los campos que no se editan
      _facturaOriginal = factura;

      // Llenar los controllers con los datos existentes (usando campos nuevos)
      montoController.text = factura.totalAmount.toString();
      descripcionController.text = factura.description;
      categoriaController.text = factura.categoria;
      proveedorController.text = factura.supplierName;
      lugarController.text = factura.lugarLocal;
      // Campos adicionales de factura
      invoiceNumberController.text = factura.invoiceNumber;
      _invoiceDate = factura.invoiceDate;
      supplierTaxIdController.text = factura.supplierTaxId;
      taxAmountController.text = factura.taxAmount.toString();
      scanImagePathController.text = factura.scanImagePath ?? '';
      entryMethodController.text = factura.entryMethod;
      _idUsuario = factura.idUsuario;
    } catch (e) {
      throw Exception('Error al cargar gasto: $e');
    }
  }

  /// Actualiza la fecha seleccionada
  void actualizarFecha(DateTime nuevaFecha) {
    _fechaSeleccionada = nuevaFecha;
    notifyListeners();
  }

  /// Actualiza la fecha de la factura (invoice date)
  void actualizarInvoiceDate(DateTime nuevaFecha) {
    _invoiceDate = nuevaFecha;
    notifyListeners();
  }

  /// Valida los campos del formulario
  String? validarFormulario() {
    if (_tipoTransaccion == null) {
      return 'Tipo de transacción no válido';
    }

    // Usar el servicio de validaciones
    return ValidacionesTransacciones.validarFormulario(
      tipo: _tipoTransaccion!,
      montoController: montoController,
      categoriaController: categoriaController,
      descripcionController: descripcionController,
      metodoPagoController: metodoPagoController,
      origenController: origenController,
      proveedorController: proveedorController,
      lugarController: lugarController,
      invoiceNumberController: invoiceNumberController,
      supplierTaxIdController: supplierTaxIdController,
      taxAmountController: taxAmountController,
      invoiceDate: _invoiceDate,
      entryMethodController: entryMethodController,
    );
  }

  /// Guarda los cambios de la transacción
  Future<bool> guardarCambios() async {
    _error = null;

    // Validar formulario
    final errorValidacion = validarFormulario();
    if (errorValidacion != null) {
      _error = errorValidacion;
      notifyListeners();
      return false;
    }

    if (_transaccionId == null || _tipoTransaccion == null) {
      _error = 'No se puede guardar: información de transacción incompleta';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      if (_tipoTransaccion == 'ingreso') {
        await _actualizarIngreso();
      } else if (_tipoTransaccion == 'gasto') {
        await _actualizarGasto();
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al guardar cambios: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _actualizarIngreso() async {
    final monto = double.parse(montoController.text);

    final ingresoActualizado = Ingreso(
      id: _transaccionId!,
      idUsuario: _idUsuario!,
      monto: monto,
      fecha: _fechaSeleccionada,
      descripcion: descripcionController.text,
      categoria: categoriaController.text,
      metodoPago: metodoPagoController.text,
      origen: origenController.text,
    );

    await _firestore
        .collection('ingresos')
        .doc(_transaccionId)
        .update(ingresoActualizado.toMap());
  }

  Future<void> _actualizarGasto() async {
    final monto = double.parse(montoController.text);

    // Crear factura actualizada manteniendo los campos originales que no se editan
    final gastoActualizado = Factura(
      idUsuario: _idUsuario!,
    invoiceNumber: invoiceNumberController.text.isNotEmpty
      ? invoiceNumberController.text
      : (_facturaOriginal?.invoiceNumber ?? ''),
  invoiceDate: _invoiceDate,
    totalAmount: monto, // actualizado
    supplierName: proveedorController.text, // actualizado
    supplierTaxId: supplierTaxIdController.text.isNotEmpty
      ? supplierTaxIdController.text
      : (_facturaOriginal?.supplierTaxId ?? ''),
    description: descripcionController.text, // actualizado
    taxAmount: (taxAmountController.text.isNotEmpty)
      ? double.tryParse(taxAmountController.text) ?? (_facturaOriginal?.taxAmount ?? 0.0)
      : (_facturaOriginal?.taxAmount ?? 0.0),
    lugarLocal: lugarController.text, // actualizado
    categoria: categoriaController.text, // actualizado
    scanImagePath: scanImagePathController.text.isNotEmpty
      ? scanImagePathController.text
      : _facturaOriginal?.scanImagePath,
    entryMethod: entryMethodController.text.isNotEmpty
      ? entryMethodController.text
      : (_facturaOriginal?.entryMethod ?? 'Editado'),
    createdAt: _facturaOriginal?.createdAt, // mantener original
    );

    await _firestore
        .collection('facturas')
        .doc(_transaccionId)
        .update(gastoActualizado.toMap());
  }

  /// Limpia el error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  /// Limpia todos los campos
  void limpiar() {
    montoController.clear();
    descripcionController.clear();
    categoriaController.clear();
    metodoPagoController.clear();
    origenController.clear();
    proveedorController.clear();
    lugarController.clear();
    // Limpiar campos adicionales de factura
    invoiceNumberController.clear();
    _invoiceDate = DateTime.now();
    supplierTaxIdController.clear();
    taxAmountController.clear();
    scanImagePathController.clear();
    entryMethodController.clear();
    _fechaSeleccionada = DateTime.now();
    _error = null;
    _transaccionId = null;
    _tipoTransaccion = null;
    _idUsuario = null;
    _facturaOriginal = null; // Limpiar factura original
    notifyListeners();
  }
}
