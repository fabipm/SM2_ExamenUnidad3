import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/edit_profile_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_repository.dart';
import '../services/image_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../providers/auth_providers.dart';
import 'auth_viewmodel.dart';

/// Provider para obtener el perfil completo del usuario desde Firestore
final currentUserProfileProvider = FutureProvider<UserProfileModel?>((
  ref,
) async {
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    return null;
  }

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .get();

    if (doc.exists && doc.data() != null) {
      return UserProfileModel.fromMap(doc.data()!);
    }

    return null;
  } catch (e) {
    print('Error loading user profile: $e');
    return null;
  }
});

/// Provider para el estado de edición del perfil
final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>(
      (ref) => EditProfileNotifier(
        authRepository: ref.read(authRepositoryProvider),
        ref: ref,
      ),
    );

/// Notifier que maneja el estado y la lógica de edición del perfil
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  EditProfileNotifier({
    required AuthRepository authRepository,
    required Ref ref,
  }) : _authRepository = authRepository,
       _ref = ref,
       super(EditProfileState.initial());

  /// Inicializar el formulario con los datos actuales del usuario
  void initializeFromUserProfile(UserProfileModel? userProfile) {
    if (userProfile != null) {
      final editProfile = EditProfileModel.fromUserProfile(userProfile);
      state = state.copyWithProfile(editProfile);
    } else {
      state = EditProfileState.initial();
    }
  }

  /// Actualizar el nombre de usuario
  void updateUsername(String username) {
    final updatedProfile = state.profile.copyWith(username: username);
    state = state.copyWithProfile(updatedProfile);

    // Limpiar errores de validación previos
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar la moneda
  void updateCurrency(String currency) {
    final updatedProfile = state.profile.copyWith(currency: currency);
    state = state.copyWithProfile(updatedProfile);

    // Limpiar errores de validación previos
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar la edad
  void updateEdad(int? edad) {
    final updatedProfile = state.profile.copyWith(edad: edad);
    state = state.copyWithProfile(updatedProfile);

    // Limpiar errores de validación previos
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar la ocupación
  void updateOcupacion(String? ocupacion) {
    final updatedProfile = state.profile.copyWith(ocupacion: ocupacion);
    state = state.copyWithProfile(updatedProfile);

    // Limpiar errores de validación previos
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar el ingreso mensual aproximado
  void updateIngresoMensualAprox(double? ingresoMensualAprox) {
    final updatedProfile = state.profile.copyWith(
      ingresoMensualAprox: ingresoMensualAprox,
    );
    state = state.copyWithProfile(updatedProfile);

    // Limpiar errores de validación previos
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar el ingreso mensual desde un string (útil para TextFields)
  void updateIngresoMensualAproxFromString(String ingresoText) {
    final ingreso = double.tryParse(ingresoText.replaceAll(',', ''));
    updateIngresoMensualAprox(ingreso);
  }

  /// Actualizar la edad desde un string (útil para TextFields)
  void updateEdadFromString(String edadText) {
    final edad = int.tryParse(edadText);
    updateEdad(edad);
  }

  /// Actualizar la foto de perfil
  void updatePhotoUrl(String? photoUrl) {
    final updatedProfile = state.profile.copyWith(photoUrl: photoUrl);
    state = state.copyWithProfile(updatedProfile);
  }

  // 🆕 MÉTODOS PARA NUEVOS CAMPOS DEMOGRÁFICOS

  /// Actualizar estado civil
  void updateEstadoCivil(String? estadoCivil) {
    final updatedProfile = state.profile.copyWith(estadoCivil: estadoCivil);
    state = state.copyWithProfile(updatedProfile);
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar número de dependientes
  void updateNumeroDependientes(int? numeroDependientes) {
    final updatedProfile = state.profile.copyWith(
      numeroDependientes: numeroDependientes,
    );
    state = state.copyWithProfile(updatedProfile);
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar número de dependientes desde string
  void updateNumeroDependientesFromString(String text) {
    final numero = int.tryParse(text);
    updateNumeroDependientes(numero);
  }

  /// Actualizar si tiene hijos
  void updateTieneHijos(bool? tieneHijos) {
    final updatedProfile = state.profile.copyWith(tieneHijos: tieneHijos);
    state = state.copyWithProfile(updatedProfile);
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar nivel de educación
  void updateNivelEducacion(String? nivelEducacion) {
    final updatedProfile = state.profile.copyWith(
      nivelEducacion: nivelEducacion,
    );
    state = state.copyWithProfile(updatedProfile);
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Actualizar objetivos financieros
  void updateObjetivosFinancieros(List<String>? objetivos) {
    final updatedProfile = state.profile.copyWith(
      objetivosFinancieros: objetivos,
    );
    state = state.copyWithProfile(updatedProfile);
    if (state.validationErrors.isNotEmpty) {
      _validateProfile();
    }
  }

  /// Toggle un objetivo financiero específico
  void toggleObjetivoFinanciero(String objetivo) {
    final currentObjetivos = List<String>.from(
      state.profile.objetivosFinancieros ?? [],
    );

    if (currentObjetivos.contains(objetivo)) {
      currentObjetivos.remove(objetivo);
    } else {
      currentObjetivos.add(objetivo);
    }

    updateObjetivosFinancieros(
      currentObjetivos.isEmpty ? null : currentObjetivos,
    );
  }

  /// Seleccionar imagen desde la cámara
  Future<void> pickImageFromCamera() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWithError('Usuario no autenticado');
      return;
    }

    state = state.copyWithLoading();

    try {
      // Verificar permisos
      final hasPermissions = await ImageService.checkAndRequestPermissions();
      if (!hasPermissions) {
        state = state.copyWithError('Permisos de cámara requeridos');
        return;
      }

      // Seleccionar imagen
      final imageFile = await ImageService.pickImageFromCamera();
      if (imageFile == null) {
        // Usuario canceló la selección
        state = state.copyWithProfile(state.profile);
        return;
      }

      // Subir imagen
      final imageUrl = await ImageService.uploadProfileImage(
        imageFile,
        currentUser.id,
      );
      if (imageUrl == null) {
        state = state.copyWithError('Error al subir la imagen');
        return;
      }

      // Actualizar el perfil con la nueva URL
      updatePhotoUrl(imageUrl);

      // Guardar en Firebase
      await _savePhotoUrlToFirestore(imageUrl);

      state = state.copyWithSuccess();
    } catch (e) {
      state = state.copyWithError(
        'Error al procesar la imagen: ${e.toString()}',
      );
    }
  }

  /// Seleccionar imagen desde la galería
  Future<void> pickImageFromGallery() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWithError('Usuario no autenticado');
      return;
    }

    state = state.copyWithLoading();

    try {
      // Verificar permisos
      final hasPermissions = await ImageService.checkAndRequestPermissions();
      if (!hasPermissions) {
        state = state.copyWithError('Permisos de galería requeridos');
        return;
      }

      // Seleccionar imagen
      final imageFile = await ImageService.pickImageFromGallery();
      if (imageFile == null) {
        // Usuario canceló la selección
        state = state.copyWithProfile(state.profile);
        return;
      }

      // Subir imagen
      final imageUrl = await ImageService.uploadProfileImage(
        imageFile,
        currentUser.id,
      );
      if (imageUrl == null) {
        state = state.copyWithError('Error al subir la imagen');
        return;
      }

      // Actualizar el perfil con la nueva URL
      updatePhotoUrl(imageUrl);

      // Guardar en Firebase
      await _savePhotoUrlToFirestore(imageUrl);

      state = state.copyWithSuccess();
    } catch (e) {
      state = state.copyWithError(
        'Error al procesar la imagen: ${e.toString()}',
      );
    }
  }

  /// Eliminar la foto de perfil
  Future<void> deleteProfilePhoto() async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWithError('Usuario no autenticado');
      return;
    }

    state = state.copyWithLoading();

    try {
      // Eliminar de Firebase Storage si existe
      await ImageService.deleteProfileImage(currentUser.id);

      // Actualizar el perfil sin foto
      updatePhotoUrl(null);

      // Guardar en Firebase
      await _savePhotoUrlToFirestore(null);

      state = state.copyWithSuccess();
    } catch (e) {
      state = state.copyWithError(
        'Error al eliminar la imagen: ${e.toString()}',
      );
    }
  }

  /// Guardar solo la URL de la foto
  Future<void> _savePhotoUrlToFirestore(String? photoUrl) async {
    try {
      await _authRepository.updateUserPhotoUrl(photoUrl);
      _ref.invalidate(currentUserProfileProvider);
    } catch (e) {
      print('Error al guardar URL de foto: $e');
      rethrow;
    }
  }

  /// Validar el perfil sin guardarlo
  bool _validateProfile() {
    final errors = state.profile.validationErrors;
    if (errors.isNotEmpty) {
      state = state.copyWithValidationErrors(errors);
      return false;
    }

    // Si no hay errores, limpiar el estado de error
    if (state.status == EditProfileStatus.error &&
        state.validationErrors.isNotEmpty) {
      state = state.copyWithProfile(state.profile);
    }

    return true;
  }

  /// Guardar los cambios del perfil
  Future<bool> saveProfile() async {
    // Validar primero
    if (!_validateProfile()) {
      return false;
    }

    return await _saveToFirestore();
  }

  /// Método específico para actualizar solo la moneda sin validación completa
  Future<bool> saveCurrencyOnly(String currency) async {
    final currentUser = _ref.read(currentUserProvider);
    final currentUserProfileAsync = _ref.read(currentUserProfileProvider);

    if (currentUser == null) {
      state = state.copyWithError('Usuario no autenticado');
      return false;
    }

    state = state.copyWithLoading();

    try {
      await currentUserProfileAsync.when(
        data: (userProfile) async {
          if (userProfile != null) {
            // Solo actualizar la moneda
            final updatedProfile = userProfile.copyWith(currency: currency);
            await _authRepository.updateUserProfile(updatedProfile);

            // Invalidar el cache del perfil para que se recargue
            _ref.invalidate(currentUserProfileProvider);

            state = state.copyWithSuccess();
          } else {
            state = state.copyWithError('No se pudo cargar el perfil actual');
          }
        },
        loading: () async {
          state = state.copyWithError('Cargando perfil...');
        },
        error: (error, stack) async {
          state = state.copyWithError('Error al cargar el perfil');
        },
      );

      return state.status == EditProfileStatus.success;
    } catch (e) {
      String errorMessage = 'Error al actualizar la moneda';
      if (e is AuthException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Error inesperado: $e';
      }
      state = state.copyWithError(errorMessage);
      return false;
    }
  }

  /// Método privado común para guardar en Firestore
  Future<bool> _saveToFirestore() async {
    final currentUser = _ref.read(currentUserProvider);
    final currentUserProfileAsync = _ref.read(currentUserProfileProvider);

    if (currentUser == null) {
      state = state.copyWithError('Usuario no autenticado');
      return false;
    }

    state = state.copyWithLoading();

    try {
      // Obtener el perfil actual para mantener los datos no editables
      await currentUserProfileAsync.when(
        data: (userProfile) async {
          if (userProfile != null) {
            // Crear un perfil actualizado manteniendo los datos originales
            final updatedProfile = userProfile.copyWith(
              username: state.profile.username,
              currency: state.profile.currency,
              edad: state.profile.edad,
              ocupacion: state.profile.ocupacion,
              ingresoMensualAprox: state.profile.ingresoMensualAprox,
            );

            // Actualizar perfil usando el método correcto del repository
            await _authRepository.updateUserProfile(updatedProfile);

            // Invalidar el cache del perfil para que se recargue
            _ref.invalidate(currentUserProfileProvider);

            state = state.copyWithSuccess();
          } else {
            state = state.copyWithError('No se pudo cargar el perfil actual');
          }
        },
        loading: () async {
          state = state.copyWithError('Cargando perfil...');
        },
        error: (error, stack) async {
          state = state.copyWithError('Error al cargar el perfil');
        },
      );

      return state.status == EditProfileStatus.success;
    } catch (e) {
      String errorMessage = 'Error al actualizar el perfil';

      if (e is AuthException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Error inesperado: $e';
      }

      state = state.copyWithError(errorMessage);
      return false;
    }
  }

  /// Resetear el estado a inicial
  void reset() {
    state = EditProfileState.initial();
  }

  /// Limpiar errores
  void clearErrors() {
    if (state.status == EditProfileStatus.error) {
      state = state.copyWithProfile(state.profile);
    }
  }

  /// Getters para acceso fácil a los valores formateados

  /// Obtener la edad como string para mostrar en UI
  String get edadText => state.profile.edad?.toString() ?? '';

  /// Obtener el ingreso como string formateado para mostrar en UI
  String get ingresoMensualText {
    if (state.profile.ingresoMensualAprox == null) return '';
    return state.profile.ingresoMensualAprox!.toStringAsFixed(2);
  }

  /// Obtener la ocupación para mostrar en UI
  String get ocupacionText => state.profile.ocupacion ?? '';

  /// Verificar si el formulario está completo y válido
  bool get isFormValid => state.profile.isValid;

  /// Verificar si hay cambios pendientes comparando con el perfil original
  bool hasChanges(UserProfileModel? originalProfile) {
    if (originalProfile == null) return true;

    return originalProfile.username != state.profile.username ||
        originalProfile.currency != state.profile.currency ||
        originalProfile.edad != state.profile.edad ||
        originalProfile.ocupacion != state.profile.ocupacion ||
        originalProfile.ingresoMensualAprox !=
            state.profile.ingresoMensualAprox;
  }

  /// Resetear a los valores originales del perfil
  void resetToOriginal(UserProfileModel? originalProfile) {
    if (originalProfile != null) {
      initializeFromUserProfile(originalProfile);
    } else {
      reset();
    }
  }
}
