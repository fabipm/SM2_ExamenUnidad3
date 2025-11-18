import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Seleccionar imagen desde la cámara
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error al seleccionar imagen de cámara: $e');
      return null;
    }
  }

  /// Seleccionar imagen desde la galería
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error al seleccionar imagen de galería: $e');
      return null;
    }
  }

  /// Subir imagen a Firebase Storage
  static Future<String?> uploadProfileImage(
    XFile imageFile,
    String userId,
  ) async {
    try {
      // Crear referencia al archivo en Firebase Storage
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage
          .ref()
          .child('profile_images')
          .child(fileName);

      // Subir el archivo
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));

      // Esperar a que termine la subida
      final TaskSnapshot snapshot = await uploadTask;

      // Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  /// Eliminar imagen de perfil de Firebase Storage
  static Future<bool> deleteProfileImage(String userId) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage
          .ref()
          .child('profile_images')
          .child(fileName);

      await ref.delete();
      return true;
    } catch (e) {
      print('Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Verificar y solicitar permisos para cámara y galería
  static Future<bool> checkAndRequestPermissions() async {
    // Los permisos se manejan automáticamente por image_picker
    // pero puedes agregar lógica adicional aquí si es necesario
    return true;
  }
}
