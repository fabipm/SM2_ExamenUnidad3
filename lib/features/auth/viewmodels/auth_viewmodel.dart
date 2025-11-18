import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../../../core/exceptions/app_exception.dart';
import 'auth_state.dart';

/// ViewModel para manejo de autenticación usando AsyncNotifier
class AuthViewModel extends AsyncNotifier<AuthState> {
  late AuthRepository _authRepository;

  @override
  Future<AuthState> build() async {
    _authRepository = ref.read(authRepositoryProvider);

    // Escuchar cambios en el estado de autenticación
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            state = AsyncValue.data(AuthAuthenticated(user));
          } else {
            state = const AsyncValue.data(AuthUnauthenticated());
          }
        },
        loading: () => state = const AsyncValue.data(AuthLoading()),
        error: (error, stack) => state = AsyncValue.data(
          AuthError('Error en el estado de autenticación: $error'),
        ),
      );
    });

    // Estado inicial basado en el usuario actual
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      return AuthAuthenticated(currentUser);
    } else {
      return const AuthUnauthenticated();
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(AuthAuthenticated(user));
    } on AuthException catch (e) {
      // Guardar el estado de error y relanzar para que la UI lo maneje
      state = AsyncValue.data(AuthError(e.message, code: e.code));
      rethrow;
    } catch (e) {
      // Mantener registro del error y relanzar para que la UI lo muestre
      state = AsyncValue.data(AuthError('Error inesperado: $e'));
      rethrow;
    }
  }

  /// Registrar usuario con email y contraseña
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String currency,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.registerWithEmail(
        email: email,
        password: password,
        username: username,
        currency: currency,
      );
      state = AsyncValue.data(AuthAuthenticated(user));
    } on AuthException catch (e) {
      // Guardar el estado de error y relanzar para que la UI lo maneje
      state = AsyncValue.data(AuthError(e.message, code: e.code));
      rethrow;
    } catch (e) {
      // Mantener registro del error y relanzar para que la UI lo muestre
      state = AsyncValue.data(AuthError('Error inesperado: $e'));
      rethrow;
    }
  }

  /// Iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.signInWithGoogle();
      state = AsyncValue.data(AuthAuthenticated(user));
    } on AuthException catch (e) {
      // Si es una cancelación del usuario, volver al estado anterior sin mostrar error
      if (e.code == 'SIGN_IN_CANCELLED') {
        state = const AsyncValue.data(AuthUnauthenticated());
        // Re-lanzar para que la UI pueda manejar si es necesario
        rethrow;
      } else {
        // Guardar el estado de error y relanzar para que la UI lo maneje
        state = AsyncValue.data(AuthError(e.message, code: e.code));
        rethrow;
      }
    } catch (e) {
      state = AsyncValue.data(AuthError('Error inesperado: $e'));
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(AuthUnauthenticated());
    } on AuthException catch (e) {
      state = AsyncValue.data(AuthError(e.message, code: e.code));
    } catch (e) {
      state = AsyncValue.data(AuthError('Error inesperado: $e'));
    }
  }

  /// Enviar email para resetear contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } on AuthException catch (e) {
      state = AsyncValue.data(AuthError(e.message, code: e.code));
    }
  }

  /// Refrescar información del usuario actual
  Future<void> refreshUser() async {
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        state = AsyncValue.data(AuthAuthenticated(currentUser));
      } else {
        state = const AsyncValue.data(AuthUnauthenticated());
      }
    } catch (e) {
      // No cambiar el estado si hay error, mantener el estado actual
      print('Error al refrescar usuario: $e');
    }
  }

  /// Limpiar errores
  void clearError() {
    state.whenData((data) {
      if (data is AuthError) {
        state = const AsyncValue.data(AuthUnauthenticated());
      }
    });
  }

  /// Getters de conveniencia
  bool get isAuthenticated {
    return state.value is AuthAuthenticated;
  }

  bool get isLoading {
    return state.isLoading || state.value is AuthLoading;
  }

  UserModel? get currentUser {
    final authState = state.value;
    if (authState is AuthAuthenticated) {
      return authState.user;
    }
    return null;
  }

  String? get errorMessage {
    final authState = state.value;
    if (authState is AuthError) {
      return authState.message;
    }
    return null;
  }
}

/// Provider principal del AuthViewModel
final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, AuthState>(
  () {
    return AuthViewModel();
  },
);

/// Provider de conveniencia para verificar si está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authViewModelProvider).value;
  return authState is AuthAuthenticated;
});

/// Provider de conveniencia para obtener el usuario actual
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authViewModelProvider).value;
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Provider de conveniencia para verificar si está cargando
final isLoadingProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(authViewModelProvider);
  return asyncState.isLoading || asyncState.value is AuthLoading;
});

/// Provider de conveniencia para obtener el mensaje de error
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authViewModelProvider).value;
  if (authState is AuthError) {
    return authState.message;
  }
  return null;
});
