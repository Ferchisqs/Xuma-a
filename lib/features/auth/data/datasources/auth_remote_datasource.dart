// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:injectable/injectable.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/usecases/register_usecase.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(RegisterParams params);
  Future<UserModel> registerWithParentalConsent(RegisterParams params);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Simulamos una base de datos local para fines de demostración
  final Map<String, Map<String, dynamic>> _users = {};

  AuthRemoteDataSourceImpl();

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));
      
      final hashedPassword = _hashPassword(password);
      final user = _users[email];
      
      if (user == null) {
        throw AuthException('Usuario no encontrado');
      }
      
      if (user['password'] != hashedPassword) {
        throw AuthException('Contraseña incorrecta');
      }
      
      // Actualizar último login
      user['lastLogin'] = DateTime.now().toIso8601String();
      
      return UserModel.fromJson(user);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException('Error del servidor: $e');
    }
  }

  @override
  Future<UserModel> register(RegisterParams params) async {
    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));
      
      if (_users.containsKey(params.email)) {
        throw AuthException('El email ya está registrado');
      }
      
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(params.password);
      final now = DateTime.now();
      
      final userData = {
        'id': userId,
        'firstName': params.firstName,
        'lastName': params.lastName,
        'email': params.email,
        'age': params.age,
        'password': hashedPassword,
        'profilePicture': null,
        'createdAt': now.toIso8601String(),
        'lastLogin': now.toIso8601String(),
        'needsParentalConsent': false,
      };
      
      _users[params.email] = userData;
      
      // Remover password del response
      final responseData = Map<String, dynamic>.from(userData);
      responseData.remove('password');
      
      return UserModel.fromJson(responseData);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException('Error del servidor: $e');
    }
  }

  @override
  Future<UserModel> registerWithParentalConsent(RegisterParams params) async {
    try {
      // Simular delay de red más largo para proceso de autorización parental
      await Future.delayed(const Duration(seconds: 2));
      
      if (_users.containsKey(params.email)) {
        throw AuthException('El email ya está registrado');
      }
      
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(params.password);
      final now = DateTime.now();
      
      final userData = {
        'id': userId,
        'firstName': params.firstName,
        'lastName': params.lastName,
        'email': params.email,
        'age': params.age,
        'password': hashedPassword,
        'profilePicture': null,
        'createdAt': now.toIso8601String(),
        'lastLogin': now.toIso8601String(),
        'needsParentalConsent': true,
        // Información parental
        'guardianName': params.parentalInfo?.guardianName,
        'relationship': params.parentalInfo?.relationship,
        'guardianEmail': params.parentalInfo?.guardianEmail,
      };
      
      _users[params.email] = userData;
      
      // Simular envío de email de autorización parental
      print('📧 Enviando solicitud de autorización parental para ${params.firstName} ${params.lastName}');
      print('👨‍👩‍👧‍👦 Tutor: ${params.parentalInfo?.guardianName} (${params.parentalInfo?.relationship})');
      print('📮 Email del tutor: ${params.parentalInfo?.guardianEmail}');
      
      // Remover password del response
      final responseData = Map<String, dynamic>.from(userData);
      responseData.remove('password');
      
      return UserModel.fromJson(responseData);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException('Error en registro con autorización parental: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 500));
      // En una implementación real, invalidaríamos el token en el servidor
    } catch (e) {
      throw ServerException('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      // En una implementación real, obtendríamos el usuario actual desde el servidor
      // usando el token de autenticación
      await Future.delayed(const Duration(milliseconds: 500));
      return null;
    } catch (e) {
      throw ServerException('Error al obtener usuario actual: $e');
    }
  }

  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}