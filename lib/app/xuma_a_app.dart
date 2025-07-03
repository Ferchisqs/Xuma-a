import 'package:flutter/material.dart';
import '../core/config/app_theme.dart';
import '../features/auth/presentation/pages/login_page.dart';

class XumaAApp extends StatelessWidget {
  const XumaAApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xuma\'a - Conciencia Ambiental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
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