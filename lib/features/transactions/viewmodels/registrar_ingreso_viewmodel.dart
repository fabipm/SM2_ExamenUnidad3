import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_ingreso_model.dart';

class RegistrarIngresoViewModel extends ChangeNotifier {
  final TextEditingController montoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController metodoPagoController = TextEditingController();
  final TextEditingController origenController = TextEditingController();

  DateTime? fecha;
  String? categoriaSeleccionada;

  void setFecha(DateTime? nuevaFecha) {
    fecha = nuevaFecha;
    notifyListeners();
  }

  void setCategoria(String? nuevaCategoria) {
    categoriaSeleccionada = nuevaCategoria;
    notifyListeners();
  }

  void limpiarFormulario() {
    montoController.clear();
    descripcionController.clear();
    metodoPagoController.clear();
    origenController.clear();
    fecha = null;
    categoriaSeleccionada = null;
    notifyListeners();
  }

  Ingreso crearIngreso(String idUsuario) {
    return Ingreso(
      id: UniqueKey().toString(),
      idUsuario: idUsuario,
      monto: double.tryParse(montoController.text) ?? 0.0,
      fecha: fecha ?? DateTime.now(),
      descripcion: descripcionController.text,
      categoria: categoriaSeleccionada ?? '',
      metodoPago: metodoPagoController.text,
      origen: origenController.text,
    );
  }

  Future<void> guardarIngresoEnFirebase(String idUsuario) async {
    final ingreso = crearIngreso(idUsuario);
    await FirebaseFirestore.instance
        .collection('ingresos')
        .add(ingreso.toMap());
    limpiarFormulario();
  }
}
