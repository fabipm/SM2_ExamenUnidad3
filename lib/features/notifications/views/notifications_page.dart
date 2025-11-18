import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/notification_model.dart';
import '../providers/notification_providers.dart';

/// Página para mostrar todas las notificaciones del usuario
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  NotificationType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notificaciones'),
            if (unreadCount > 0) ...[
              const SizedBox(width: AppSizes.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.redCoral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Filtro por tipo
          PopupMenuButton<NotificationType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() {
                _selectedFilter = type;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todas'),
              ),
              const PopupMenuItem(
                value: NotificationType.budgetWarning80,
                child: Row(
                  children: [
                    Text('⚠️'),
                    SizedBox(width: 8),
                    Text('Alerta 80%'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NotificationType.budgetExceeded100,
                child: Row(
                  children: [
                    Text('🚨'),
                    SizedBox(width: 8),
                    Text('Límite alcanzado'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NotificationType.budgetOverspent,
                child: Row(
                  children: [
                    Text('❌'),
                    SizedBox(width: 8),
                    Text('Presupuesto excedido'),
                  ],
                ),
              ),
            ],
          ),
          // Marcar todas como leídas
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: () => _markAllAsRead(),
              tooltip: 'Marcar todas como leídas',
            ),
          // Menú de opciones
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clean':
                  _showCleanDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clean',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Limpiar antiguas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notifications.when(
        data: (notificationList) {
          final filteredNotifications = _selectedFilter == null
              ? notificationList
              : notificationList.where((n) => n.type == _selectedFilter).toList();

          if (filteredNotifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userNotificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.spaceM),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.redCoral,
              ),
              const SizedBox(height: AppSizes.spaceM),
              Text(
                'Error al cargar notificaciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.spaceS),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppSizes.spaceM),
              ElevatedButton(
                onPressed: () => ref.invalidate(userNotificationsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceM),
      elevation: notification.isRead ? 1 : 3,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              notification.iconType,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: notification.isRead ? Colors.grey[600] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notification.categoryName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.blueLavender,
                  shape: BoxShape.circle,
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'read':
                    _markAsRead(notification.id);
                    break;
                  case 'delete':
                    _deleteNotification(notification.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!notification.isRead)
                  const PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, size: 20),
                        SizedBox(width: 8),
                        Text('Marcar como leída'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppColors.redCoral),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: AppColors.redCoral)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: notification.isRead ? null : () => _markAsRead(notification.id),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 60,
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),
          Text(
            _selectedFilter == null 
                ? 'No tienes notificaciones'
                : 'No hay notificaciones de este tipo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Text(
            _selectedFilter == null
                ? 'Las notificaciones sobre tu presupuesto aparecerán aquí'
                : 'Selecciona "Todas" para ver todas las notificaciones',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),
          if (_selectedFilter != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = null;
                });
              },
              child: const Text('Ver todas las notificaciones'),
            ),
        ],
      ),
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

  Future<void> _markAsRead(String notificationId) async {
    final markAsRead = ref.read(markNotificationAsReadProvider);
    await markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    final markAllAsRead = ref.read(markAllNotificationsAsReadProvider);
    final success = await markAllAsRead();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final deleteNotification = ref.read(deleteNotificationProvider);
    final success = await deleteNotification(notificationId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación eliminada'),
          backgroundColor: AppColors.greyDark,
        ),
      );
    }
  }

  void _showCleanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar notificaciones'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar las notificaciones de más de 30 días? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cleanOldNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redCoral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanOldNotifications() async {
    final cleanNotifications = ref.read(cleanOldNotificationsProvider);
    await cleanNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificaciones antiguas eliminadas'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}