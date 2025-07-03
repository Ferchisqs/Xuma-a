import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/xuma_a_app.dart';
import 'core/services/cache_service.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await _initializeServices();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style (modo claro para XUMA'A)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // 🔄 Cambiado a dark
      systemNavigationBarColor: Color(0xFFF8F9FA), // 🔄 Fondo claro
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const XumaAApp());
}

Future<void> _initializeServices() async {
  try {
    configureDependencies();
    await CacheService().init();
    debugPrint('✅ XUMA\'A services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing XUMA\'A services: $e');
  }
}
