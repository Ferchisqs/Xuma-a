// lib/app/xuma_a_app.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/config/app_theme.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../core/services/notification_service.dart';

// Función para manejar mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Manejando mensaje en background: ${message.messageId}');
}

class XumaAApp extends StatefulWidget {
  const XumaAApp({super.key});

  @override
  State<XumaAApp> createState() => _XumaAAppState();
}

class _XumaAAppState extends State<XumaAApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      
      // Suscribirse a tópicos relevantes para tu app ambiental
      await NotificationService().subscribeToTopic('environmental_alerts');
      await NotificationService().subscribeToTopic('xuma_updates');
      
      print('Notificaciones inicializadas correctamente');
    } catch (e) {
      print('Error al inicializar notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XUMA\'A - Protector Ambiental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Actualizado para Flutter 3.16+
          ),
          child: child!,
        );
      },
    );
  }
}

// Página de prueba para notificaciones (opcional)
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  String? _currentToken;

  @override
  void initState() {
    super.initState();
    _getCurrentToken();
  }

  Future<void> _getCurrentToken() async {
    try {
      String? token = await NotificationService().getToken();
      setState(() {
        _currentToken = token;
      });
    } catch (e) {
      print('Error al obtener token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Notificaciones'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token FCM Actual:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentToken ?? 'Cargando...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _getCurrentToken,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar Token FCM'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await NotificationService().subscribeToTopic('general');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Suscrito al tópico general'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Suscribirse a Tópico General'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await NotificationService().subscribeToTopic('environmental_alerts');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Suscrito a alertas ambientales'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.eco),
              label: const Text('Suscribirse a Alertas Ambientales'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await NotificationService().unsubscribeFromTopic('general');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Desuscrito del tópico general'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.notifications_off),
              label: const Text('Desuscribirse de Tópico General'),
            ),
          ],
        ),
      ),
    );
  }
}