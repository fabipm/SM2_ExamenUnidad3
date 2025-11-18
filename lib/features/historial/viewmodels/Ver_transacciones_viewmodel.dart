import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../transactions/models/registro_ingreso_model.dart';
import '../../transactions/models/register_bill_model.dart';

class TransaccionItem {
  final String id;
  final String categoria;
  final DateTime fecha;
  final double monto;
  final String tipo; // 'ingreso' o 'gasto'
  final String descripcion;

  TransaccionItem({
    required this.id,
    required this.categoria,
    required this.fecha,
    required this.monto,
    required this.tipo,
    required this.descripcion,
  });
}

class VerTransaccionesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransaccionItem> _transacciones = [];
  bool _isLoading = false;
  String? _error;

  List<TransaccionItem> get transacciones => _transacciones;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener el usuario actual
  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> cargarTransacciones() async {
    if (_currentUserId == null) {
      _error = 'Usuario no autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<TransaccionItem> todasLasTransacciones = [];

      // Cargar ingresos
      await _cargarIngresos(todasLasTransacciones);

      // Cargar gastos (facturas)
      await _cargarGastos(todasLasTransacciones);

      // Ordenar por fecha (más recientes primero)
      todasLasTransacciones.sort((a, b) => b.fecha.compareTo(a.fecha));

      _transacciones = todasLasTransacciones;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar transacciones: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarIngresos(List<TransaccionItem> transacciones) async {
    try {
      QuerySnapshot ingresoSnapshot = await _firestore
          .collection('ingresos')
          .where('idUsuario', isEqualTo: _currentUserId)
          .get();

      for (QueryDocumentSnapshot doc in ingresoSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Ingreso ingreso = Ingreso.fromMap(data);
          
          transacciones.add(TransaccionItem(
            id: doc.id,
            categoria: ingreso.categoria,
            fecha: ingreso.fecha,
            monto: ingreso.monto,
            tipo: 'ingreso',
            descripcion: ingreso.descripcion,
          ));
        } catch (e) {
          print('Error al procesar ingreso ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error al cargar ingresos: $e');
    }
  }

  Future<void> _cargarGastos(List<TransaccionItem> transacciones) async {
    try {
      QuerySnapshot gastoSnapshot = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: _currentUserId)
          .get();

      for (QueryDocumentSnapshot doc in gastoSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Factura factura = Factura.fromMap(data);
          
          transacciones.add(TransaccionItem(
            id: doc.id,
            categoria: factura.categoria,
            fecha: factura.invoiceDate, // Ahora usamos la fecha de la factura
            monto: factura.totalAmount, // Usamos totalAmount en lugar de monto
            tipo: 'gasto',
            descripcion: factura.description, // Usamos description en lugar de descripcion
          ));
        } catch (e) {
          print('Error al procesar gasto ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error al cargar gastos: $e');
    }
  }

  // Métodos de filtrado que puedes usar más adelante
  List<TransaccionItem> get ingresos => 
      _transacciones.where((t) => t.tipo == 'ingreso').toList();

  List<TransaccionItem> get gastos => 
      _transacciones.where((t) => t.tipo == 'gasto').toList();

  double get totalIngresos => 
      ingresos.fold(0.0, (sum, item) => sum + item.monto);

  double get totalGastos => 
      gastos.fold(0.0, (sum, item) => sum + item.monto);

  double get balance => totalIngresos - totalGastos;

  // Filtrar por categoría
  List<TransaccionItem> filtrarPorCategoria(String categoria) {
    return _transacciones
        .where((t) => t.categoria.toLowerCase().contains(categoria.toLowerCase()))
        .toList();
  }

  // Filtrar por rango de fechas
  List<TransaccionItem> filtrarPorFechas(DateTime inicio, DateTime fin) {
    return _transacciones
        .where((t) => 
            t.fecha.isAfter(inicio.subtract(Duration(days: 1))) &&
            t.fecha.isBefore(fin.add(Duration(days: 1))))
        .toList();
  }

  // Limpiar errores
  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  // Refrescar datos
  Future<void> refrescar() async {
    await cargarTransacciones();
  }
}
