import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool needsParentalConsent;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.profilePicture,
    required this.createdAt,
    this.lastLogin,
    this.needsParentalConsent = false,
  });

  String get fullName => '$firstName $lastName';
  bool get isMinor => age < 13;

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    age,
    profilePicture,
    createdAt,
    lastLogin,
    needsParentalConsent,
  ];
}