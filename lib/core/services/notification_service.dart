// lib/core/services/notification_service.dart - VERSIÓN SIMPLIFICADA
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Solicitar permisos
      await _requestPermissions();
      
      // Configurar manejadores
      _setupMessageHandlers();
      
      _isInitialized = true;
      print('NotificationService inicializado correctamente');
    } catch (e) {
      print('Error inicializando NotificationService: $e');
      throw e;
    }
  }

  /// Solicita permisos de notificación
  Future<NotificationSettings> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permisos otorgados: ${settings.authorizationStatus}');
    return settings;
  }

  /// Configura los manejadores de mensajes
  void _setupMessageHandlers() {
    // Mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje en primer plano: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación: ${message.notification?.title}');
      _handleMessageOpenedApp(message);
    });
  }

  /// Maneja mensajes cuando la app está en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      print('📱 NOTIFICACIÓN RECIBIDA:');
      print('Título: ${message.notification!.title}');
      print('Cuerpo: ${message.notification!.body}');
      print('Datos: ${message.data}');
      
      // Por ahora solo mostramos en consola
      // TODO: Implementar notificaciones locales más adelante
    }
  }

  /// Maneja cuando se abre la app desde una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 App abierta desde notificación');
    print('Datos del mensaje: ${message.data}');
    // TODO: Implementar navegación específica aquí
  }

  /// Obtiene el token FCM
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      print('🔑 Token FCM: $token');
      return token;
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  /// Se suscribe a un tópico
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Suscrito al tópico: $topic');
    } catch (e) {
      print('❌ Error suscribiéndose al tópico $topic: $e');
      throw e;
    }
  }

  /// Se desuscribe de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('🚫 Desuscrito del tópico: $topic');
    } catch (e) {
      print('❌ Error desuscribiéndose del tópico $topic: $e');
      throw e;
    }
  }

  /// Obtiene el mensaje inicial si la app fue abierta desde una notificación
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  /// Verifica el estado de los permisos
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Obtiene información sobre el estado del servicio
  Map<String, dynamic> getServiceInfo() {
    return {
      'isInitialized': _isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}