import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../../../core/exceptions/error_handler.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../transactions/services/categoria_service.dart';

/// Repository que encapsula todas las operaciones de autenticación
/// Usa el sistema centralizado de error handling (ErrorHandler + AppException)
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  // StreamController para controlar manualmente las actualizaciones del usuario
  final StreamController<UserModel?> _userController =
      StreamController<UserModel?>.broadcast();

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance {
    // Escuchar cambios en Firebase Auth y propagar al stream personalizado
    _firebaseAuth.authStateChanges().listen((User? user) {
      final userModel = user != null ? UserModel.fromFirebaseUser(user) : null;
      _userController.add(userModel);
    });
  }

  /// Stream que escucha cambios en el estado de autenticación
  Stream<UserModel?> get authStateChanges {
    return _userController.stream;
  }

  /// Dispose del StreamController
  void dispose() {
    _userController.close();
  }

  /// Usuario actual (si existe)
  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  /// Iniciar sesión con email y contraseña
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Verificar si el usuario está bloqueado por intentos fallidos
      final isBlocked = await isUserBlocked(email);
      if (isBlocked) {
        throw AuthException(
          message:
              'Has superado el número de intentos. Intenta de nuevo más tarde',
          code: 'TOO_MANY_ATTEMPTS',
        );
      }

      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      if (result.user == null) {
        throw AuthException(
          message: 'Error al iniciar sesión',
          code: 'USER_NULL',
        );
      }

      // Login exitoso - reiniciar intentos fallidos
      await resetLoginAttempts(result.user!.uid);

      return UserModel.fromFirebaseUser(result.user!);
    } catch (e, stackTrace) {
      // Incrementar intentos fallidos en ciertos casos
      if (e is FirebaseAuthException &&
          (e.code == 'wrong-password' || e.code == 'user-not-found')) {
        await incrementLoginAttempts(email);
      }
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Registrar usuario con email y contraseña
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String currency,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      if (result.user == null) {
        throw AuthException(
          message: 'Error al crear cuenta',
          code: 'USER_NULL',
        );
      }

      // Actualizar el displayName en Firebase Auth
      await result.user!.updateDisplayName(username);
      await result.user!.reload();

      // Crear perfil en Firestore
      final userProfile = UserProfileModel.fromFirebaseUser(
        uid: result.user!.uid,
        email: email.trim(),
        username: username,
        currency: currency,
        verified: true, // Marcamos como verificado directamente
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userProfile.toMap());

      // Crear categorías por defecto para el nuevo usuario
      try {
        final categoriaService = CategoriaService();
        await categoriaService.crearCategoriasDefecto(result.user!.uid);
      } catch (e) {
        print('Error al crear categorías por defecto: $e');
        // No lanzar error, el usuario puede crearlas después
      }

      return UserModel.fromFirebaseUser(result.user!);
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Iniciar sesión con Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // IMPORTANTE: Cerrar completamente cualquier sesión previa
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      // Importante: signIn() devuelve null si el usuario cancela
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si el usuario cancela el login, lanzar excepción inmediatamente
      if (googleUser == null) {
        // Asegurar que no hay sesión activa
        await _firebaseAuth.signOut();
        throw AuthException(
          message: 'Inicio de sesión cancelado por el usuario',
          code: 'SIGN_IN_CANCELLED',
        );
      }

      // Verificar que el usuario de Google es válido
      if (googleUser.email.isEmpty) {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        throw AuthException(
          message: 'No se pudo obtener información de la cuenta de Google',
          code: 'GOOGLE_ACCOUNT_INVALID',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verificar que tenemos los tokens necesarios
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        throw AuthException(
          message: 'Error al obtener credenciales de Google',
          code: 'GOOGLE_AUTH_FAILED',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (result.user == null) {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        throw AuthException(
          message: 'Error al iniciar sesión con Google',
          code: 'GOOGLE_SIGNIN_FAILED',
        );
      }

      // Crear o actualizar perfil en Firestore con información de Google
      await _createOrUpdateGoogleUserProfile(result.user!, googleUser);

      return UserModel.fromFirebaseUser(result.user!);
    } catch (e) {
      // Si es una cancelación u otro error, cerrar cualquier sesión parcial
      if (e is AuthException &&
          (e.code == 'SIGN_IN_CANCELLED' ||
              e.code == 'GOOGLE_ACCOUNT_INVALID' ||
              e.code == 'GOOGLE_AUTH_FAILED')) {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
      }

      // Re-lanzar la excepción para que el ViewModel la maneje
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Obtener perfil del usuario desde Firestore
  Future<UserProfileModel?> getUserProfile() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists ? UserProfileModel.fromMap(doc.data()!) : null;
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateUserProfile(UserProfileModel profile) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.userNotFound();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(profile.toMap());

      // Actualizar displayName en Firebase Auth si cambió
      if (profile.username != user.displayName) {
        await user.updateDisplayName(profile.username);
        await user.reload();
      }
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Actualizar foto de perfil del usuario
  Future<void> updateUserPhotoUrl(String? photoUrl) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.userNotFound();
      }

      // Actualizar en Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': photoUrl,
      });

      // Actualizar en Firebase Auth
      await user.updatePhotoURL(photoUrl);
      await user.reload();

      // Forzar actualización del stream personalizado
      final updatedUser = _firebaseAuth.currentUser;
      if (updatedUser != null) {
        final userModel = UserModel.fromFirebaseUser(updatedUser);
        _userController.add(userModel);
      }
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.userNotFound();
      }

      // Re-autenticar al usuario
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cambiar contraseña
      await user.updatePassword(newPassword);
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.userNotFound();
      }

      // Re-autenticar antes de eliminar
      if (user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Eliminar datos de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar cuenta de Firebase Auth
      await user.delete();
    } catch (e, stackTrace) {
      throw ErrorHandler.handleError(e, stackTrace);
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Crear o actualizar perfil de usuario específico para Google
  Future<void> _createOrUpdateGoogleUserProfile(
    User user,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Crear nuevo perfil con información real de Google
        final profile = UserProfileModel.fromFirebaseUser(
          uid: user.uid,
          email: user.email ?? googleUser.email,
          username:
              user.displayName ?? googleUser.displayName ?? 'Usuario de Google',
          currency: 'S/', // Moneda por defecto para Perú (basado en tu app)
          verified: user.emailVerified,
        );

        await _firestore.collection('users').doc(user.uid).set(profile.toMap());
        
        // Crear categorías por defecto para el nuevo usuario de Google
        try {
          final categoriaService = CategoriaService();
          await categoriaService.crearCategoriasDefecto(user.uid);
        } catch (e) {
          print('Error al crear categorías por defecto para usuario Google: $e');
        }
      } else {
        // Actualizar información con datos de Google
        await _firestore.collection('users').doc(user.uid).update({
          'email': user.email ?? googleUser.email,
          'username':
              user.displayName ??
              googleUser.displayName ??
              userDoc.data()!['username'],
          'verified': user.emailVerified,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, stackTrace) {
      // No lanzar error aquí para no bloquear el login
      ErrorHandler.logError(ErrorHandler.handleError(e, stackTrace));
    }
  }

  // ========== CONTROL DE INTENTOS FALLIDOS ==========

  /// Incrementar intentos fallidos de login
  Future<void> incrementLoginAttempts(String email) async {
    try {
      final attemptDoc = await _firestore
          .collection('login_attempts')
          .doc(email.toLowerCase())
          .get();

      if (attemptDoc.exists) {
        final data = attemptDoc.data()!;
        final attempts = (data['attempts'] as int? ?? 0) + 1;
        await attemptDoc.reference.update({
          'attempts': attempts,
          'lastAttempt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection('login_attempts')
            .doc(email.toLowerCase())
            .set({'attempts': 1, 'lastAttempt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      // No bloquear el proceso si falla el tracking
      print('Error tracking login attempts: $e');
    }
  }

  /// Verificar si el usuario está bloqueado por intentos fallidos
  Future<bool> isUserBlocked(String email) async {
    try {
      final attemptDoc = await _firestore
          .collection('login_attempts')
          .doc(email.toLowerCase())
          .get();

      if (!attemptDoc.exists) return false;

      final data = attemptDoc.data()!;
      final attempts = data['attempts'] as int? ?? 0;
      final lastAttempt = data['lastAttempt'] as Timestamp?;

      if (attempts >= 5 && lastAttempt != null) {
        final timeDiff = DateTime.now().difference(lastAttempt.toDate());
        return timeDiff.inMinutes < 15; // Bloqueo por 15 minutos
      }

      return false;
    } catch (e) {
      // En caso de error, no bloquear al usuario
      return false;
    }
  }

  /// Reiniciar intentos fallidos de login
  Future<void> resetLoginAttempts(String identifier) async {
    try {
      await _firestore
          .collection('login_attempts')
          .doc(identifier.toLowerCase())
          .delete();
    } catch (e) {
      // No es crítico si falla
      print('Error resetting login attempts: $e');
    }
  }
}
