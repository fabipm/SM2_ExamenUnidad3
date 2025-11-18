import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_providers.dart';

/// Widget que muestra un indicador de notificaciones no leídas
class NotificationsBadge extends ConsumerWidget {
  const NotificationsBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.redCoral,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => context.push(AppRoutes.notifications),
      tooltip: unreadCount > 0 
          ? '$unreadCount notificaciones no leídas'
          : 'Notificaciones',
    );
  }
}

/// Widget compacto para mostrar en la barra de navegación
class NotificationsBadgeCompact extends ConsumerWidget {
  final Color? iconColor;
  final double? iconSize;

  const NotificationsBadgeCompact({
    super.key,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.notifications),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: iconColor ?? AppColors.blackGrey,
              size: iconSize,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.redCoral,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget que muestra una lista pequeña de notificaciones recientes
class RecentNotificationsWidget extends ConsumerWidget {
  final int maxNotifications;

  const RecentNotificationsWidget({
    super.key,
    this.maxNotifications = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(userNotificationsProvider);

    return notifications.when(
      data: (notificationList) {
        final recent = notificationList.take(maxNotifications).toList();
        
        if (recent.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notificaciones recientes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.notifications),
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
              ),
              ...recent.map((notification) => ListTile(
                dense: true,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      notification.iconType,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  notification.categoryName,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  notification.timeAgo,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                onTap: () => context.push(AppRoutes.notifications),
              )),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.budgetWarning80:
        return Colors.orange;
      case NotificationType.budgetExceeded100:
        return AppColors.redCoral;
      case NotificationType.budgetOverspent:
        return Colors.red;
    }
  }
}