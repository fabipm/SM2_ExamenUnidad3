import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/register_bill_model.dart';

class RegisterBillViewModel extends ChangeNotifier {
  // Identificación
  final TextEditingController invoiceNumberController = TextEditingController();
  DateTime? invoiceDate;
  final TextEditingController totalAmountController = TextEditingController();
  
  // Proveedor (emisor)
  final TextEditingController supplierNameController = TextEditingController();
  final TextEditingController supplierTaxIdController = TextEditingController();
  
  // Contenido básico
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController taxAmountController = TextEditingController();
  
  // Campos adicionales
  final TextEditingController lugarLocalController = TextEditingController();
  
  // Control / sistema
  String? scanImagePath;
  String entryMethod = 'Manual';
  
  String? categoriaSeleccionada;

  void setInvoiceDate(DateTime? date) {
    invoiceDate = date;
    notifyListeners();
  }

  void setCategoria(String? nuevaCategoria) {
    categoriaSeleccionada = nuevaCategoria;
    notifyListeners();
  }

  void setScanImagePath(String? path) {
    scanImagePath = path;
    notifyListeners();
  }

  void setEntryMethod(String method) {
    entryMethod = method;
    notifyListeners();
  }

  void limpiarFormulario() {
    invoiceNumberController.clear();
    invoiceDate = null;
    totalAmountController.clear();
    supplierNameController.clear();
    supplierTaxIdController.clear();
    descripcionController.clear();
    taxAmountController.clear();
    lugarLocalController.clear();
    categoriaSeleccionada = null;
    scanImagePath = null;
    entryMethod = 'Manual';
    notifyListeners();
  }

  Factura crearFactura(String idUsuario) {
    return Factura(
      idUsuario: idUsuario,
      invoiceNumber: invoiceNumberController.text,
      invoiceDate: invoiceDate ?? DateTime.now(),
      totalAmount: double.tryParse(totalAmountController.text) ?? 0.0,
      supplierName: supplierNameController.text,
      supplierTaxId: supplierTaxIdController.text,
      description: descripcionController.text,
      taxAmount: double.tryParse(taxAmountController.text) ?? 0.0,
      lugarLocal: lugarLocalController.text,
      categoria: categoriaSeleccionada ?? '',
      scanImagePath: scanImagePath,
      entryMethod: entryMethod,
    );
  }

  Future<void> guardarFacturaEnFirebase(String idUsuario) async {
    final factura = crearFactura(idUsuario);
    await FirebaseFirestore.instance
        .collection('facturas')
        .add(factura.toMap());
    limpiarFormulario();
  }
}
