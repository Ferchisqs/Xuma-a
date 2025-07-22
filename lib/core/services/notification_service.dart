// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Configurar notificaciones locales
      await _initializeLocalNotifications();
      
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

  /// Inicializa las notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Maneja la respuesta cuando se toca una notificación local
  void _onNotificationResponse(NotificationResponse response) {
    print('Notificación local tocada: ${response.payload}');
    // Aquí puedes agregar lógica para navegar a pantallas específicas
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
      showLocalNotification(
        title: message.notification!.title ?? 'Nueva notificación',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Maneja cuando se abre la app desde una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Implementar navegación específica aquí
    print('Datos del mensaje: ${message.data}');
  }

  /// Obtiene el token FCM
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      print('Token FCM: $token');
      return token;
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  /// Se suscribe a un tópico
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Suscrito al tópico: $topic');
    } catch (e) {
      print('Error suscribiéndose al tópico $topic: $e');
      throw e;
    }
  }

  /// Se desuscribe de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Desuscrito del tópico: $topic');
    } catch (e) {
      print('Error desuscribiéndose del tópico $topic: $e');
      throw e;
    }
  }

  /// Muestra una notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'xuma_channel',
        'XUMA Notifications',
        channelDescription: 'Notificaciones de la app XUMA',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error mostrando notificación local: $e');
    }
  }

  /// Cancela todas las notificaciones locales
  Future<void> cancelAllLocalNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancela una notificación local específica
  Future<void> cancelLocalNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Verifica si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? false;
    }
    return true; // En iOS, se asume que están habilitadas si se otorgaron permisos
  }

  /// Obtiene el mensaje inicial si la app fue abierta desde una notificación
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }
}