import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/financial_plans_with_notifications_service.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../../auth/providers/auth_providers.dart';

/// Provider para el servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider para el servicio integrado de planes financieros con notificaciones
final financialPlansWithNotificationsServiceProvider = Provider<FinancialPlansWithNotificationsService>((ref) {
  return FinancialPlansWithNotificationsService();
});

/// Provider para obtener notificaciones del usuario actual
final userNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<NotificationModel>[]);
      return notificationService.watchUserNotifications(user.id);
    },
    loading: () => Stream.value(<NotificationModel>[]),
    error: (_, __) => Stream.value(<NotificationModel>[]),
  );
});

/// Provider para obtener solo notificaciones no leídas
final unreadNotificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return <NotificationModel>[];
      return await notificationService.getUnreadNotifications(user.id);
    },
    loading: () => <NotificationModel>[],
    error: (_, __) => <NotificationModel>[],
  );
});

/// Provider para contar notificaciones no leídas
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider);

  return notifications.when(
    data: (notificationList) => notificationList.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider para filtrar notificaciones por tipo
final notificationsByTypeProvider = Provider.autoDispose.family<List<NotificationModel>, NotificationType?>((ref, type) {
  final notifications = ref.watch(userNotificationsProvider);

  return notifications.when(
    data: (notificationList) {
      if (type == null) return notificationList;
      return notificationList.where((n) => n.type == type).toList();
    },
    loading: () => <NotificationModel>[],
    error: (_, __) => <NotificationModel>[],
  );
});

/// Provider para obtener notificaciones de un plan específico
final planNotificationsProvider = Provider.autoDispose.family<List<NotificationModel>, String>((ref, planId) {
  final notifications = ref.watch(userNotificationsProvider);

  return notifications.when(
    data: (notificationList) => notificationList.where((n) => n.planId == planId).toList(),
    loading: () => <NotificationModel>[],
    error: (_, __) => <NotificationModel>[],
  );
});

/// Provider para obtener notificaciones de una categoría específica
final categoryNotificationsProvider = Provider.autoDispose.family<List<NotificationModel>, String>((ref, categoryId) {
  final notifications = ref.watch(userNotificationsProvider);

  return notifications.when(
    data: (notificationList) => notificationList.where((n) => n.categoryId == categoryId).toList(),
    loading: () => <NotificationModel>[],
    error: (_, __) => <NotificationModel>[],
  );
});

/// Provider para marcar notificación como leída
final markNotificationAsReadProvider = Provider.autoDispose<Future<bool> Function(String)>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);

  return (String notificationId) async {
    final result = await notificationService.markAsRead(notificationId);
    if (result) {
      // Refrescar las notificaciones después de marcar como leída
      ref.invalidate(userNotificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    }
    return result;
  };
});

/// Provider para marcar todas las notificaciones como leídas
final markAllNotificationsAsReadProvider = Provider.autoDispose<Future<bool> Function()>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return () async {
    return authState.when(
      data: (user) async {
        if (user == null) return false;
        
        final result = await notificationService.markAllAsRead(user.id);
        if (result) {
          // Refrescar las notificaciones después de marcar todas como leídas
          ref.invalidate(userNotificationsProvider);
          ref.invalidate(unreadNotificationsProvider);
        }
        return result;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  };
});

/// Provider para eliminar notificación
final deleteNotificationProvider = Provider.autoDispose<Future<bool> Function(String)>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);

  return (String notificationId) async {
    final result = await notificationService.deleteNotification(notificationId);
    if (result) {
      // Refrescar las notificaciones después de eliminar
      ref.invalidate(userNotificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
    }
    return result;
  };
});

/// Provider para limpiar notificaciones antiguas
final cleanOldNotificationsProvider = Provider.autoDispose<Future<void> Function()>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return () async {
    return authState.when(
      data: (user) async {
        if (user == null) return;
        
        await notificationService.cleanOldNotifications(user.id);
        // Refrescar las notificaciones después de limpiar
        ref.invalidate(userNotificationsProvider);
        ref.invalidate(unreadNotificationsProvider);
      },
      loading: () {},
      error: (_, __) {},
    );
  };
});

/// Provider para el viewmodel de notificaciones
final notificationViewmodelProvider = StateNotifierProvider<NotificationViewmodel, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  
  return NotificationViewmodel(
    notificationService: notificationService,
  );
});