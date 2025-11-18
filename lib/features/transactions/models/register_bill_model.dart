
class Factura {
  // Identificación
  final String idUsuario;
  final String invoiceNumber; // Número único de factura
  final DateTime invoiceDate; // Fecha de emisión
  final double totalAmount; // Total a pagar (con impuestos)
  
  // Proveedor (emisor)
  final String supplierName; // Nombre o razón social
  final String supplierTaxId; // NIF / RFC / RUT
  
  // Contenido básico
  final String description; // Descripción general
  final double taxAmount; // Total de impuestos
  
  // Campos anteriores (compatibilidad)
  final String lugarLocal; // Dirección o ubicación
  final String categoria; // Categoría del gasto
  
  // Control / sistema
  final String? scanImagePath; // Ruta o enlace del archivo escaneado
  final String entryMethod; // OCR / Manual / IA
  final DateTime createdAt; // Fecha de registro

  Factura({
    required this.idUsuario,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.totalAmount,
    required this.supplierName,
    this.supplierTaxId = '',
    required this.description,
    this.taxAmount = 0.0,
    this.lugarLocal = '',
    required this.categoria,
    this.scanImagePath,
    this.entryMethod = 'Manual',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Para guardar en Firebase
  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'totalAmount': totalAmount,
      'supplierName': supplierName,
      'supplierTaxId': supplierTaxId,
      'description': description,
      'taxAmount': taxAmount,
      'lugarLocal': lugarLocal,
      'categoria': categoria,
      'scanImagePath': scanImagePath,
      'entryMethod': entryMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Para leer desde Firebase
  factory Factura.fromMap(Map<String, dynamic> map) {
    return Factura(
      idUsuario: map['idUsuario'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      invoiceDate: map['invoiceDate'] != null 
          ? DateTime.parse(map['invoiceDate']) 
          : DateTime.now(),
      totalAmount: (map['totalAmount'] ?? map['monto'] ?? 0).toDouble(),
      supplierName: map['supplierName'] ?? map['proveedor'] ?? '',
      supplierTaxId: map['supplierTaxId'] ?? '',
      description: map['description'] ?? map['descripcion'] ?? '',
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      lugarLocal: map['lugarLocal'] ?? '',
      categoria: map['categoria'] ?? '',
      scanImagePath: map['scanImagePath'],
      entryMethod: map['entryMethod'] ?? 'Manual',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}