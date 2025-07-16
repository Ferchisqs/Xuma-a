// lib/main.dart - CORREGIDO Y SIMPLIFICADO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/xuma_a_app.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  configureDependencies();
  
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