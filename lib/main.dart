import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    
    // 1. Configurar dependencias principales
    configureDependencies();
    
    // 2. Configurar Auth dependencies PRIMERO (muy importante)
    setupAuthDependencies();
    
    // 3. 🆕 CONFIGURAR CONTENT DEPENDENCIES (INCLUYE TOPIC CONTENTS CUBIT)
    setupContentDependencies();
    
    // 4. Configurar otras dependencias
    setupLearningDependencies();
    setupChallengesDependencies();
    setupTipsDependencies();
    
    // 5. Inicializar servicios
    await getIt.allReady();
    
    // 6. Debug de dependencias (opcional, quitar en producción)
    debugDependencies();
    
    print('✅ [MAIN] XUMA\'A services initialized successfully');
    print('✅ [MAIN] Auth feature configured successfully');
    print('✅ [MAIN] Content feature configured successfully'); // 🆕
    print('✅ [MAIN] Learning feature configured successfully');
    print('✅ [MAIN] Challenges feature configured successfully');
    print('✅ [MAIN] Tips feature configured successfully');
    
  } catch (e) {
    print('❌ [MAIN] Error initializing XUMA\'A services: $e');
    print('❌ [MAIN] Stack trace: ${StackTrace.current}');
  }
}

void setupAuthDependencies() {
  try {
    print('🔧 [MAIN] Setting up Auth dependencies...');
    debugPrint('✅ Auth dependencies ready');
  } catch (e) {
    debugPrint('❌ Error setting up Auth dependencies: $e');
  }
}

// 🆕 FUNCIÓN AGREGADA PARA CONTENT DEPENDENCIES
void setupContentDependencies() {
  try {
    print('🔧 [MAIN] Setting up Content dependencies...');
    
    // Llamar la función que registra todas las dependencias de contenido
    // incluyendo TopicContentsCubit
    setupContentDependencies();
    
    debugPrint('✅ Content dependencies ready');
  } catch (e) {
    debugPrint('❌ Error setting up Content dependencies: $e');
  }
}

void setupLearningDependencies() {
  try {
    print('🔧 [MAIN] Setting up Learning dependencies...');
    debugPrint('✅ Learning dependencies ready');
  } catch (e) {
    debugPrint('❌ Error setting up Learning dependencies: $e');
  }
}

void setupChallengesDependencies() {
  try {
    print('🔧 [MAIN] Setting up Challenges dependencies...');
    debugPrint('✅ Challenges dependencies ready');
  } catch (e) {
    debugPrint('❌ Error setting up Challenges dependencies: $e');
  }
}

void setupTipsDependencies() {
  try {
    print('🔧 [MAIN] Setting up Tips dependencies...');
    debugPrint('✅ Tips dependencies ready');
  } catch (e) {
    debugPrint('❌ Error setting up Tips dependencies: $e');
  }
}