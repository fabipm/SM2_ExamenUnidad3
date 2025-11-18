class Ingreso {
  final String id;
  final String idUsuario;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final String categoria;
  final String metodoPago;
  final String origen;

  Ingreso({
    required this.id,
    required this.idUsuario,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    required this.categoria,
    required this.metodoPago,
    required this.origen,
  });

  // Para guardar en Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idUsuario': idUsuario,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'categoria': categoria,
      'metodoPago': metodoPago,
      'origen': origen,
    };
  }

  // Para leer desde Firebase
  factory Ingreso.fromMap(Map<String, dynamic> map) {
    return Ingreso(
      id: map['id'] ?? '',
      idUsuario: map['idUsuario'] ?? '',
      monto: (map['monto'] ?? 0).toDouble(),
      fecha: DateTime.parse(map['fecha']),
      descripcion: map['descripcion'] ?? '',
      categoria: map['categoria'] ?? '',
      metodoPago: map['metodoPago'] ?? '',
      origen: map['origen'] ?? '',
    );
  }
}