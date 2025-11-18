import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';

class CategoriaService {
  static const String _collection = 'categorias';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todas las categorías del usuario desde la base de datos
  Future<List<CategoriaModel>> obtenerCategorias(
    String idUsuario,
    TipoCategoria tipo,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('idUsuario', isEqualTo: idUsuario)
          .where('tipo', isEqualTo: tipo.toString().split('.').last)
          .get();

      final categorias = querySnapshot.docs
          .map((doc) => CategoriaModel.fromDocument(doc))
          .toList();
      
      // Ordenar manualmente por fecha de creación (más antiguas primero)
      categorias.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));

      // Si no tiene categorías, crear las por defecto
      if (categorias.isEmpty) {
        await crearCategoriasDefecto(idUsuario);
        // Volver a consultar después de crear
        final newQuery = await _firestore
            .collection(_collection)
            .where('idUsuario', isEqualTo: idUsuario)
            .where('tipo', isEqualTo: tipo.toString().split('.').last)
            .get();
        
        final newCategorias = newQuery.docs
            .map((doc) => CategoriaModel.fromDocument(doc))
            .toList();
        
        // Ordenar manualmente
        newCategorias.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
        return newCategorias;
      }

      return categorias;
    } catch (e) {
      print('Error al obtener categorías: $e');
      return [];
    }
  }

  /// Crear categorías por defecto para un nuevo usuario
  Future<bool> crearCategoriasDefecto(String idUsuario) async {
    try {
      // Verificar si ya tiene categorías
      final existingQuery = await _firestore
          .collection(_collection)
          .where('idUsuario', isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        print('El usuario ya tiene categorías');
        return true; // Ya tiene categorías
      }

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Crear categorías de ingresos
      final categoriasIngresos = [
        {'id': 'sueldo', 'nombre': 'Sueldo'},
        {'id': 'servicios', 'nombre': 'Servicios'},
        {'id': 'inversiones', 'nombre': 'Inversiones'},
      ];

      for (final cat in categoriasIngresos) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          'id': docRef.id,
          'nombre': cat['nombre'],
          'tipo': 'ingreso',
          'esPersonalizada': false,
          'idUsuario': idUsuario,
          'fechaCreacion': now.toIso8601String(),
        });
      }

      // Crear categorías de egresos
      final categoriasEgresos = [
        {'id': 'vivienda', 'nombre': 'Vivienda'},
        {'id': 'alimentacion', 'nombre': 'Alimentación'},
        {'id': 'transporte', 'nombre': 'Transporte'},
        {'id': 'salud', 'nombre': 'Salud'},
        {'id': 'educacion', 'nombre': 'Educación'},
        {'id': 'entretenimiento', 'nombre': 'Entretenimiento'},
        {'id': 'ropa', 'nombre': 'Ropa'},
      ];

      for (final cat in categoriasEgresos) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          'id': docRef.id,
          'nombre': cat['nombre'],
          'tipo': 'egreso',
          'esPersonalizada': false,
          'idUsuario': idUsuario,
          'fechaCreacion': now.toIso8601String(),
        });
      }

      await batch.commit();
      print('Categorías por defecto creadas exitosamente para usuario: $idUsuario');
      return true;
    } catch (e) {
      print('Error al crear categorías por defecto: $e');
      return false;
    }
  }

  // Agregar nueva categoría personalizada
  Future<bool> agregarCategoriaPersonalizada(
    String idUsuario,
    String nombre,
    TipoCategoria tipo,
  ) async {
    try {
      // Verificar que no exista una categoría con el mismo nombre
      final existe = await _verificarCategoriaExiste(idUsuario, nombre, tipo);
      if (existe) {
        return false;
      }

      final categoria = CategoriaModel(
        id: _firestore.collection(_collection).doc().id,
        nombre: nombre,
        tipo: tipo,
        esPersonalizada: true,
        idUsuario: idUsuario,
        fechaCreacion: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(categoria.id)
          .set(categoria.toMap());

      return true;
    } catch (e) {
      print('Error al agregar categoría: $e');
      return false;
    }
  }

  // Editar categoría personalizada
  Future<bool> editarCategoriaPersonalizada(
    String idCategoria,
    String nuevoNombre,
    String idUsuario,
  ) async {
    try {
      await _firestore.collection(_collection).doc(idCategoria).update({
        'nombre': nuevoNombre,
      });
      return true;
    } catch (e) {
      print('Error al editar categoría: $e');
      return false;
    }
  }

  // Eliminar categoría (personalizada o por defecto)
  Future<bool> eliminarCategoriaPersonalizada(
    String idCategoria,
    String idUsuario,
  ) async {
    try {
      // Verificar que la categoría pertenece al usuario
      final doc = await _firestore
          .collection(_collection)
          .doc(idCategoria)
          .get();

      if (!doc.exists) return false;

      final categoria = CategoriaModel.fromDocument(doc);

      // Solo verificar que pertenece al usuario
      if (categoria.idUsuario != idUsuario) {
        return false;
      }

      await _firestore.collection(_collection).doc(idCategoria).delete();
      return true;
    } catch (e) {
      print('Error al eliminar categoría: $e');
      return false;
    }
  }

  // Verificar si existe una categoría con el mismo nombre
  Future<bool> _verificarCategoriaExiste(
    String idUsuario,
    String nombre,
    TipoCategoria tipo,
  ) async {
    try {
      // Verificar en todas las categorías del usuario (base y personalizadas)
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('idUsuario', isEqualTo: idUsuario)
          .where('tipo', isEqualTo: tipo.toString().split('.').last)
          .get();

      final existe = querySnapshot.docs.any(
        (doc) =>
            doc.data()['nombre'].toString().toLowerCase() ==
            nombre.toLowerCase(),
      );

      return existe;
    } catch (e) {
      print('Error al verificar categoría existente: $e');
      return true; // En caso de error, asumimos que existe para evitar duplicados
    }
  }

  // Obtener solo categorías personalizadas del usuario
  Future<List<CategoriaModel>> obtenerCategoriasPersonalizadas(
    String idUsuario,
    TipoCategoria tipo,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('idUsuario', isEqualTo: idUsuario)
          .where('tipo', isEqualTo: tipo.toString().split('.').last)
          .where('esPersonalizada', isEqualTo: true)
          .get();

      final categorias = querySnapshot.docs
          .map((doc) => CategoriaModel.fromDocument(doc))
          .toList();
      
      // Ordenar manualmente por fecha de creación
      categorias.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
      
      return categorias;
    } catch (e) {
      print('Error al obtener categorías personalizadas: $e');
      return [];
    }
  }

  // Stream para escuchar cambios en categorías personalizadas
  Stream<List<CategoriaModel>> streamCategoriasPersonalizadas(
    String idUsuario,
    TipoCategoria tipo,
  ) {
    return _firestore
        .collection(_collection)
        .where('idUsuario', isEqualTo: idUsuario)
        .where('tipo', isEqualTo: tipo.toString().split('.').last)
        .where('esPersonalizada', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) {
            final categorias = snapshot.docs
                .map((doc) => CategoriaModel.fromDocument(doc))
                .toList();
            // Ordenar manualmente por fecha de creación
            categorias.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
            return categorias;
          },
        );
  }
}
