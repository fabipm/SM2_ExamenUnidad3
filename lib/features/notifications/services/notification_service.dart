import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../constants/notification_constants.dart';

/// Servicio para manejar notificaciones push y locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configurar notificaciones locales
      await _initializeLocalNotifications();
      
      // Configurar Firebase Messaging
      await _initializeFirebaseMessaging();
      
      _initialized = true;
      print('Servicio de notificaciones inicializado correctamente');
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
    }
  }

  /// Configurar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificación para Android
    const channel = AndroidNotificationChannel(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      description: NotificationConstants.channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configurar Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Solicitar permisos
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificación concedidos');
    } else {
      print('Permisos de notificación denegados');
    }

    // Configurar manejadores de mensajes
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Manejar notificación cuando la app está en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.messageId}');
    // Mostrar notificación local cuando la app está activa
    _showLocalNotification(
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
      message.data,
    );
  }

  /// Manejar notificación cuando se abre la app desde una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App abierta desde notificación: ${message.messageId}');
    // Aquí puedes navegar a una pantalla específica
  }

  /// Manejar tap en notificación local
  void _onNotificationTapped(NotificationResponse response) {
    print('Notificación local tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica
  }

  /// Crear una notificación en Firestore
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      // Verificar si ya existe una notificación similar reciente
      final existingQuery = await _firestore
          .collection(NotificationConstants.collection)
          .where('userId', isEqualTo: notification.userId)
          .where('planId', isEqualTo: notification.planId)
          .where('categoryId', isEqualTo: notification.categoryId)
          .where('type', isEqualTo: notification.type.name)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1))
          ))
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        print('Notificación similar ya existe, no se crea duplicada');
        return null;
      }

      // Crear nueva notificación
      final docRef = await _firestore
          .collection(NotificationConstants.collection)
          .add(notification.toMap());

      await docRef.update({'id': docRef.id});

      // Enviar notificación push/local
      await _sendPushNotification(notification);

      print('Notificación creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error al crear notificación: $e');
      return null;
    }
  }

  /// Obtener notificaciones de un usuario
  Future<List<NotificationModel>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(NotificationConstants.collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error al obtener notificaciones: $e');
      return [];
    }
  }

  /// Obtener notificaciones no leídas
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(NotificationConstants.collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error al obtener notificaciones no leídas: $e');
      return [];
    }
  }

  /// Marcar notificación como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(NotificationConstants.collection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      return false;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection(NotificationConstants.collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error al marcar todas las notificaciones como leídas: $e');
      return false;
    }
  }

  /// Eliminar notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(NotificationConstants.collection)
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      print('Error al eliminar notificación: $e');
      return false;
    }
  }

  /// Enviar notificación push/local
  Future<void> _sendPushNotification(NotificationModel notification) async {
    try {
      await _showLocalNotification(
        notification.title,
        notification.message,
        {'notificationId': notification.id},
      );
    } catch (e) {
      print('Error al enviar notificación push: $e');
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: data.toString(),
      );
    } catch (e) {
      print('Error al mostrar notificación local: $e');
    }
  }

  /// Obtener token FCM del dispositivo
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error al obtener token FCM: $e');
      return null;
    }
  }

  /// Stream de notificaciones de un usuario
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _firestore
        .collection(NotificationConstants.collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  /// Limpiar notificaciones antiguas (más de 30 días)
  Future<void> cleanOldNotifications(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection(NotificationConstants.collection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Notificaciones antiguas eliminadas: ${oldNotifications.docs.length}');
    } catch (e) {
      print('Error al limpiar notificaciones antiguas: $e');
    }
  }
}

/// Manejar mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Mensaje recibido en segundo plano: ${message.messageId}');
}