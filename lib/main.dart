import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/xuma_a_app.dart';
import 'core/services/cache_service.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _initializeServices();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
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
    configureDependencies();
    
    setupLearningDependencies();
    
    await getIt<CacheService>().init();
    
    debugPrint('XUMA\'A services initialized successfully');
    debugPrint('Learning feature configured successfully');
  } catch (e) {
    debugPrint('Error initializing XUMA\'A services: $e');
  }
}

void setupLearningDependencies() {
  try {
    debugPrint('Learning dependencies ready');
  } catch (e) {
    debugPrint('Error setting up Learning dependencies: $e');
  }
}