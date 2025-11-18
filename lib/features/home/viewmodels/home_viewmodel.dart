import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../transactions/models/registro_ingreso_model.dart';
import '../../transactions/models/register_bill_model.dart';

class TransaccionResumen {
  final String id;
  final String categoria;
  final DateTime fecha;
  final double monto;
  final String tipo; // 'ingreso' o 'gasto'
  final String descripcion;
  final IconData icono;

  TransaccionResumen({
    required this.id,
    required this.categoria,
    required this.fecha,
    required this.monto,
    required this.tipo,
    required this.descripcion,
    required this.icono,
  });
}

class HomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransaccionResumen> _transaccionesRecientes = [];
  bool _isLoading = false;
  String? _error;

  List<TransaccionResumen> get transaccionesRecientes => _transaccionesRecientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener el usuario actual
  String? get _currentUserId => _auth.currentUser?.uid;

  // Calcular totales
  double get totalIngresos => _transaccionesRecientes
      .where((t) => t.tipo == 'ingreso')
      .fold(0.0, (sum, item) => sum + item.monto);

  double get totalGastos => _transaccionesRecientes
      .where((t) => t.tipo == 'gasto')
      .fold(0.0, (sum, item) => sum + item.monto);

  double get balance => totalIngresos - totalGastos;

  Future<void> cargarDatosHome() async {
    if (_currentUserId == null) {
      _error = 'Usuario no autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<TransaccionResumen> todasLasTransacciones = [];

      // Cargar ingresos
      await _cargarIngresos(todasLasTransacciones);

      // Cargar gastos (facturas)
      await _cargarGastos(todasLasTransacciones);

      // Ordenar por fecha (más recientes primero)
      todasLasTransacciones.sort((a, b) => b.fecha.compareTo(a.fecha));

      // Tomar solo las 5 más recientes
      _transaccionesRecientes = todasLasTransacciones.take(5).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarIngresos(List<TransaccionResumen> transacciones) async {
    try {
      QuerySnapshot ingresoSnapshot = await _firestore
          .collection('ingresos')
          .where('idUsuario', isEqualTo: _currentUserId)
          .get();

      for (QueryDocumentSnapshot doc in ingresoSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Ingreso ingreso = Ingreso.fromMap(data);
          // Solo añadir ingresos cuya fecha sea el día de hoy
          if (_esMismaFechaHoy(ingreso.fecha)) {
            transacciones.add(TransaccionResumen(
              id: doc.id,
              categoria: ingreso.categoria,
              fecha: ingreso.fecha,
              monto: ingreso.monto,
              tipo: 'ingreso',
              descripcion: ingreso.descripcion,
              icono: _obtenerIconoPorCategoria(ingreso.categoria, 'ingreso'),
            ));
          }
        } catch (e) {
          print('Error al procesar ingreso ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error al cargar ingresos: $e');
    }
  }

  Future<void> _cargarGastos(List<TransaccionResumen> transacciones) async {
    try {
      QuerySnapshot gastoSnapshot = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: _currentUserId)
          .get();

      for (QueryDocumentSnapshot doc in gastoSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          Factura factura = Factura.fromMap(data);
          // Solo añadir gastos cuya fecha sea el día de hoy
          if (_esMismaFechaHoy(factura.invoiceDate)) {
            transacciones.add(TransaccionResumen(
              id: doc.id,
              categoria: factura.categoria,
              fecha: factura.invoiceDate,
              monto: factura.totalAmount,
              tipo: 'gasto',
              descripcion: factura.description,
              icono: _obtenerIconoPorCategoria(factura.categoria, 'gasto'),
            ));
          }
        } catch (e) {
          print('Error al procesar gasto ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('Error al cargar gastos: $e');
    }
  }

  bool _esMismaFechaHoy(DateTime fecha) {
    final ahora = DateTime.now();
    return fecha.year == ahora.year && fecha.month == ahora.month && fecha.day == ahora.day;
  }

  IconData _obtenerIconoPorCategoria(String categoria, String tipo) {
    final categoriaLower = categoria.toLowerCase();
    
    if (tipo == 'ingreso') {
      if (categoriaLower.contains('salario') || categoriaLower.contains('sueldo')) {
        return Icons.work;
      } else if (categoriaLower.contains('freelance') || categoriaLower.contains('independiente')) {
        return Icons.laptop;
      } else if (categoriaLower.contains('inversión') || categoriaLower.contains('inversion')) {
        return Icons.trending_up;
      } else if (categoriaLower.contains('venta')) {
        return Icons.sell;
      } else {
        return Icons.account_balance_wallet;
      }
    } else {
      // Gastos
      if (categoriaLower.contains('alimento') || categoriaLower.contains('comida') || 
          categoriaLower.contains('supermercado') || categoriaLower.contains('restaurante')) {
        return Icons.restaurant;
      } else if (categoriaLower.contains('transporte') || categoriaLower.contains('combustible') ||
                 categoriaLower.contains('gasolina')) {
        return Icons.directions_car;
      } else if (categoriaLower.contains('entretenimiento') || categoriaLower.contains('ocio')) {
        return Icons.movie;
      } else if (categoriaLower.contains('salud') || categoriaLower.contains('médico') ||
                 categoriaLower.contains('medico') || categoriaLower.contains('farmacia')) {
        return Icons.medical_services;
      } else if (categoriaLower.contains('educación') || categoriaLower.contains('educacion')) {
        return Icons.school;
      } else if (categoriaLower.contains('servicio') || categoriaLower.contains('luz') ||
                 categoriaLower.contains('agua') || categoriaLower.contains('internet')) {
        return Icons.receipt_long;
      } else if (categoriaLower.contains('ropa') || categoriaLower.contains('vestimenta')) {
        return Icons.checkroom;
      } else {
        return Icons.shopping_bag;
      }
    }
  }

  String obtenerTextoRelativoFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return 'Hoy';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();
      return 'Hace ${semanas} ${semanas == 1 ? 'semana' : 'semanas'}';
    } else if (diferencia.inDays < 365) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace ${meses} ${meses == 1 ? 'mes' : 'meses'}';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  Future<void> refrescar() async {
    await cargarDatosHome();
  }
}
