String? validarMonto(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El monto es obligatorio';
  }
  final monto = double.tryParse(value);
  if (monto == null || monto <= 0) {
    return 'Ingrese un monto válido';
  }
  return null;
}

String? validarFecha(DateTime? value) {
  if (value == null) {
    return 'La fecha es obligatoria';
  }
  return null;
}

String? validarDescripcion(String? value) {
  // Descripción ahora es opcional
  return null;
}

String? validarCategoria(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'La categoría es obligatoria';
  }
  return null;
}

String? validarMetodoPago(String? value) {
  // Método de pago ahora es opcional
  return null;
}

String? validarOrigen(String? value) {
  // Origen ahora es opcional (no es campo obligatorio según la nueva regla)
  return null;
}

String? validarProveedor(String? value) {
  // Proveedor ahora es opcional
  return null;
}

String? validarLugarLocal(String? value) {
  // Lugar/Local ahora es opcional
  return null;
}