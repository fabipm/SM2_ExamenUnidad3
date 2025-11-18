import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/services/notification_service.dart';

/// Widget que inicializa servicios importantes al inicio de la app
class ServicesInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const ServicesInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ServicesInitializer> createState() => _ServicesInitializerState();
}

class _ServicesInitializerState extends ConsumerState<ServicesInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Inicializar servicio de notificaciones
      final notificationService = NotificationService();
      await notificationService.initialize();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('Error al inicializar servicios: $e');
      // Incluso si hay error, mostramos la app
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Mostrar splash screen mientras se inicializan los servicios
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Inicializando servicios...'),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}