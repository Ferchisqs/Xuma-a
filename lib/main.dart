// lib/main.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xuma_a/features/learning/presentation/cubit/topic_contents_cubit.dart';
import 'app/xuma_a_app.dart';
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

Future _initializeServices() async {
  try {
    print('🚀 [MAIN] Initializing XUMA\'A services...');
    
    // 🔧 CONFIGURACIÓN CORREGIDA - UNA SOLA LLAMADA A configureDependencies()
    // Esta función ya incluye todas las dependencias necesarias
    configureDependencies();
    
    // Verificación crítica de TopicContentsCubit
    if (!getIt.isRegistered<TopicContentsCubit>()) {
      print('❌ [MAIN] CRITICAL: TopicContentsCubit not registered!');
      throw Exception('TopicContentsCubit registration failed');
    }
    
    // Inicializar servicios
    await getIt.allReady();
    
    print('✅ [MAIN] XUMA\'A services initialized successfully');
    print('✅ [MAIN] TopicContentsCubit verified and ready');
    
  } catch (e, stackTrace) {
    print('❌ [MAIN] Error initializing XUMA\'A services: $e');
    print('❌ [MAIN] Stack trace: $stackTrace');
    rethrow; // Re-lanzar el error para que la app no inicie con dependencias rotas
  }
}


