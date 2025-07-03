import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/xuma_a_app.dart';
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
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8F9FA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const XumaAApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize dependency injection
    configureDependencies();
    
    debugPrint('✅ Xuma\'a services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Xuma\'a services: $e');
  }
}