import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de notificación para presupuestos
enum NotificationType {
  budgetWarning80, // Alerta al 80%
  budgetExceeded100, // Alerta al 100%
  budgetOverspent, // Cuando se excede el 100%
}

/// Modelo para notificaciones de presupuesto
class NotificationModel {
  final String id;
  final String userId;
  final String planId;
  final String categoryId;
  final String categoryName;
  final NotificationType type;
  final String title;
  final String message;
  final double currentAmount;
  final double budgetAmount;
  final double percentage;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.title,
    required this.message,
    required this.currentAmount,
    required this.budgetAmount,
    required this.percentage,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Factory constructor desde Map (Firestore)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      planId: map['planId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationType.budgetWarning80,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      budgetAmount: (map['budgetAmount'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      readAt: map['readAt'] != null
          ? (map['readAt'] is Timestamp
              ? (map['readAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['readAt']))
          : null,
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type.name,
      'title': title,
      'message': message,
      'currentAmount': currentAmount,
      'budgetAmount': budgetAmount,
      'percentage': percentage,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Copia con nuevos valores
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? planId,
    String? categoryId,
    String? categoryName,
    NotificationType? type,
    String? title,
    String? message,
    double? currentAmount,
    double? budgetAmount,
    double? percentage,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      currentAmount: currentAmount ?? this.currentAmount,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      percentage: percentage ?? this.percentage,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Marcar como leída
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Obtener icono según el tipo de notificación
  String get iconType {
    switch (type) {
      case NotificationType.budgetWarning80:
        return '⚠️';
      case NotificationType.budgetExceeded100:
        return '🚨';
      case NotificationType.budgetOverspent:
        return '❌';
    }
  }

  /// Obtener tiempo relativo (ej: "hace 2 horas")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'ahora mismo';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, planId: $planId, categoryId: $categoryId, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}