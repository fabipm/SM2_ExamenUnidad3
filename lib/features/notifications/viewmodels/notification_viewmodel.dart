import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Estado para el viewmodel de notificaciones
class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// ViewModel para manejar la lógica de notificaciones
class NotificationViewmodel extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationViewmodel({
    required NotificationService notificationService,
  })  : _notificationService = notificationService,
        super(const NotificationState());

  /// Cargar notificaciones del usuario
  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final notifications = await _notificationService.getUserNotifications(userId);
      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar notificaciones: $e',
      );
    }
  }

  /// Cargar solo notificaciones no leídas
  Future<void> loadUnreadNotifications(String userId) async {
    try {
      final unreadNotifications = await _notificationService.getUnreadNotifications(userId);
      
      state = state.copyWith(
        unreadCount: unreadNotifications.length,
      );
    } catch (e) {
      print('Error al cargar notificaciones no leídas: $e');
    }
  }

  /// Marcar notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        // Actualizar el estado local
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.markAsRead();
          }
          return notification;
        }).toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error al marcar notificación como leída: $e');
      return false;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _notificationService.markAllAsRead(userId);
      
      if (success) {
        // Actualizar el estado local
        final updatedNotifications = state.notifications.map((notification) {
          return notification.markAsRead();
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al marcar todas las notificaciones como leídas: $e',
      );
      return false;
    }
  }

  /// Eliminar notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);
      
      if (success) {
        // Actualizar el estado local
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != notificationId)
            .toList();

        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: 'Error al eliminar notificación: $e');
      return false;
    }
  }

  /// Limpiar notificaciones antiguas
  Future<void> cleanOldNotifications(String userId) async {
    try {
      await _notificationService.cleanOldNotifications(userId);
      // Recargar notificaciones después de limpiar
      await loadNotifications(userId);
    } catch (e) {
      state = state.copyWith(error: 'Error al limpiar notificaciones antiguas: $e');
    }
  }

  /// Filtrar notificaciones por tipo
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return state.notifications.where((notification) => notification.type == type).toList();
  }

  /// Filtrar notificaciones por plan
  List<NotificationModel> getNotificationsByPlan(String planId) {
    return state.notifications.where((notification) => notification.planId == planId).toList();
  }

  /// Filtrar notificaciones por categoría
  List<NotificationModel> getNotificationsByCategory(String categoryId) {
    return state.notifications.where((notification) => notification.categoryId == categoryId).toList();
  }

  /// Obtener notificaciones de las últimas 24 horas
  List<NotificationModel> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return state.notifications
        .where((notification) => notification.createdAt.isAfter(yesterday))
        .toList();
  }

  /// Obtener estadísticas de notificaciones
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{
      'total': state.notifications.length,
      'unread': state.unreadCount,
      'warning80': 0,
      'exceeded100': 0,
      'overspent': 0,
    };

    for (final notification in state.notifications) {
      switch (notification.type) {
        case NotificationType.budgetWarning80:
          stats['warning80'] = (stats['warning80'] ?? 0) + 1;
          break;
        case NotificationType.budgetExceeded100:
          stats['exceeded100'] = (stats['exceeded100'] ?? 0) + 1;
          break;
        case NotificationType.budgetOverspent:
          stats['overspent'] = (stats['overspent'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Inicializar servicio de notificaciones
  Future<void> initializeNotifications() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      state = state.copyWith(error: 'Error al inicializar notificaciones: $e');
    }
  }

  /// Obtener token FCM
  Future<String?> getFCMToken() async {
    try {
      return await _notificationService.getFCMToken();
    } catch (e) {
      print('Error al obtener token FCM: $e');
      return null;
    }
  }
}