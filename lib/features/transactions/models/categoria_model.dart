import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoCategoria { ingreso, egreso }

class CategoriaModel {
  final String id;
  final String nombre;
  final TipoCategoria tipo;
  final bool esPersonalizada;
  final String idUsuario; // Para categorías personalizadas
  final DateTime fechaCreacion;

  CategoriaModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.esPersonalizada = false,
    this.idUsuario = '',
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Categorías base para ingresos
  static List<CategoriaModel> get categoriasBaseIngresos => [
    CategoriaModel(id: 'sueldo', nombre: 'Sueldo', tipo: TipoCategoria.ingreso),
    CategoriaModel(
      id: 'servicios',
      nombre: 'Servicios',
      tipo: TipoCategoria.ingreso,
    ),
    CategoriaModel(
      id: 'inversiones',
      nombre: 'Inversiones',
      tipo: TipoCategoria.ingreso,
    ),
  ];

  // Categorías base para egresos
  static List<CategoriaModel> get categoriasBaseEgresos => [
    CategoriaModel(
      id: 'vivienda',
      nombre: 'Vivienda',
      tipo: TipoCategoria.egreso,
    ),
    CategoriaModel(
      id: 'alimentacion',
      nombre: 'Alimentación',
      tipo: TipoCategoria.egreso,
    ),
    CategoriaModel(
      id: 'transporte',
      nombre: 'Transporte',
      tipo: TipoCategoria.egreso,
    ),
    CategoriaModel(id: 'salud', nombre: 'Salud', tipo: TipoCategoria.egreso),
    CategoriaModel(
      id: 'educacion',
      nombre: 'Educación',
      tipo: TipoCategoria.egreso,
    ),
    CategoriaModel(
      id: 'entretenimiento',
      nombre: 'Entretenimiento',
      tipo: TipoCategoria.egreso,
    ),
    CategoriaModel(id: 'ropa', nombre: 'Ropa', tipo: TipoCategoria.egreso),
  ];

  // Convertir a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo.toString().split('.').last,
      'esPersonalizada': esPersonalizada,
      'idUsuario': idUsuario,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  // Crear desde Map de Firebase
  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] == 'ingreso'
          ? TipoCategoria.ingreso
          : TipoCategoria.egreso,
      esPersonalizada: map['esPersonalizada'] ?? false,
      idUsuario: map['idUsuario'] ?? '',
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
    );
  }

  // Crear desde DocumentSnapshot de Firebase
  factory CategoriaModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoriaModel.fromMap(data);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoriaModel &&
        other.id == id &&
        other.nombre == nombre &&
        other.tipo == tipo;
  }

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode ^ tipo.hashCode;

  @override
  String toString() {
    return 'CategoriaModel(id: $id, nombre: $nombre, tipo: $tipo, esPersonalizada: $esPersonalizada)';
  }
}
