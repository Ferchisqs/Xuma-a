import 'package:flutter/material.dart';
import '../core/config/app_theme.dart';
import '../features/auth/presentation/pages/login_page.dart'; // 🆕 IMPORT


class XumaAApp extends StatelessWidget {
  const XumaAApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XUMA\'A - Protector Ambiental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // 🔄 Usar tema claro
      home: const LoginPage(), // 🆕 Iniciar en Login
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0,
          ),
          child: child!,
        );
      },
    );
  }
}