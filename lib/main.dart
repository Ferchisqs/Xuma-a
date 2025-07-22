import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app/xuma_a_app.dart'; // Your main app widget
import 'di/injection.dart'; // Your dependency injection setup

// Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase si aún no lo está en el contexto de la aplicación.
  // Esto es crucial para que los mensajes en segundo plano puedan acceder a los servicios de Firebase.
  await Firebase.initializeApp();
  print('Mensaje en segundo plano: ${message.messageId}');
  // Aquí puedes agregar lógica para manejar el mensaje, como mostrar una notificación local.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase primero
  await Firebase.initializeApp();

  // Configurar handler para mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Solicitar permisos de notificación (opcional, pero recomendado para iOS y Android 13+)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Configurar la escucha de mensajes en primer plano y la apertura desde notificaciones
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.notification?.title}');
    // Muestra una notificación local cuando la aplicación está en primer plano
    _showLocalNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App abierta desde notificación: ${message.notification?.title}');
    // Aquí puedes navegar a una pantalla específica en tu aplicación si lo necesitas
  });

  // Configurar la inyección de dependencias (si la necesitas antes de runApp)
  configureDependencies();

  // Configuración de la orientación de la pantalla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuración del estilo de la barra de sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8F9FA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const XumaAApp()); // Tu widget principal de la aplicación Xuma
}

// Función para mostrar notificaciones locales
Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel', // ID del canal (debe ser único)
    'Notificaciones Importantes', // Nombre del canal visible para el usuario
    channelDescription: 'Este canal se usa para notificaciones importantes.',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0, // ID de la notificación
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
    payload: 'item x', // Puedes enviar datos adicionales con la notificación
  );
}