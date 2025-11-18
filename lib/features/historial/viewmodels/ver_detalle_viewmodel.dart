import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/models/registro_ingreso_model.dart';
import '../../transactions/models/register_bill_model.dart';

class DetalleTransaccion {
  final String id;
  final String tipo; // 'ingreso' o 'gasto'
  final String categoria;
  final double monto;
  final DateTime fecha;
  final String descripcion;

  // Campos específicos de ingresos
  final String? metodoPago;
  final String? origen;

  // Campos específicos de gastos/facturas - NUEVOS CAMPOS
  final String? invoiceNumber;
  final String? supplierName;
  final String? supplierTaxId;
  final double? taxAmount;
  final String? lugarLocal;
  final String? scanImagePath;
  final String? entryMethod;
  final DateTime? createdAt;

  DetalleTransaccion({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    // Campos de ingreso
    this.metodoPago,
    this.origen,
    // Campos de factura
    this.invoiceNumber,
    this.supplierName,
    this.supplierTaxId,
    this.taxAmount,
    this.lugarLocal,
    this.scanImagePath,
    this.entryMethod,
    this.createdAt,
  });

  // Constructor desde un Ingreso
  factory DetalleTransaccion.fromIngreso(Ingreso ingreso, String docId) {
    return DetalleTransaccion(
      id: docId,
      tipo: 'ingreso',
      categoria: ingreso.categoria,
      monto: ingreso.monto,
      fecha: ingreso.fecha,
      descripcion: ingreso.descripcion,
      metodoPago: ingreso.metodoPago,
      origen: ingreso.origen,
    );
  }

  // Constructor desde una Factura
  factory DetalleTransaccion.fromFactura(Factura factura, String docId) {
    return DetalleTransaccion(
      id: docId,
      tipo: 'gasto',
      categoria: factura.categoria,
      monto: factura.totalAmount,
      fecha: factura.invoiceDate,
      descripcion: factura.description,
      invoiceNumber: factura.invoiceNumber,
      supplierName: factura.supplierName,
      supplierTaxId: factura.supplierTaxId,
      taxAmount: factura.taxAmount,
      lugarLocal: factura.lugarLocal,
      scanImagePath: factura.scanImagePath,
      entryMethod: factura.entryMethod,
      createdAt: factura.createdAt,
    );
  }
}

class VerDetalleViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DetalleTransaccion? _detalleTransaccion;
  bool _isLoading = false;
  String? _error;

  DetalleTransaccion? get detalleTransaccion => _detalleTransaccion;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga los detalles de una transacción desde Firebase
  /// [id] - ID del documento en Firebase
  /// [tipo] - 'ingreso' o 'gasto'
  Future<void> cargarDetalle(String id, String tipo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (tipo == 'ingreso') {
        await _cargarDetalleIngreso(id);
      } else if (tipo == 'gasto') {
        await _cargarDetalleGasto(id);
      } else {
        throw Exception('Tipo de transacción no válido: $tipo');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar el detalle: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarDetalleIngreso(String id) async {
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

      _detalleTransaccion = DetalleTransaccion.fromIngreso(ingreso, doc.id);
    } catch (e) {
      throw Exception('Error al cargar ingreso: $e');
    }
  }

  Future<void> _cargarDetalleGasto(String id) async {
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

      _detalleTransaccion = DetalleTransaccion.fromFactura(factura, doc.id);
    } catch (e) {
      throw Exception('Error al cargar gasto: $e');
    }
  }

  /// Elimina una transacción
  Future<bool> eliminarTransaccion() async {
    if (_detalleTransaccion == null) {
      _error = 'No hay transacción para eliminar';
      notifyListeners();
      return false;
    }

    try {
      String coleccion = _detalleTransaccion!.tipo == 'ingreso'
          ? 'ingresos'
          : 'facturas';

      await _firestore
          .collection(coleccion)
          .doc(_detalleTransaccion!.id)
          .delete();

      return true;
    } catch (e) {
      _error = 'Error al eliminar transacción: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpia el estado actual
  void limpiar() {
    _detalleTransaccion = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Limpia solo el error
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Getters de utilidad
  String get tipoFormateado {
    if (_detalleTransaccion == null) return '';
    return _detalleTransaccion!.tipo == 'ingreso' ? 'Ingreso' : 'Gasto';
  }

  Color get colorTipo {
    if (_detalleTransaccion == null) return Colors.grey;
    return _detalleTransaccion!.tipo == 'ingreso' ? Colors.green : Colors.red;
  }

  IconData get iconoTipo {
    if (_detalleTransaccion == null) return Icons.help_outline;
    return _detalleTransaccion!.tipo == 'ingreso'
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }
}
