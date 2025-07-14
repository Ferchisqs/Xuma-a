import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final bool needsParentalConsent;
  final int ecoPoints;
  final int achievementsCount;
  final int lessonsCompleted;
  final String level;

  const UserProfileEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.avatarUrl,
    this.bio,
    this.location,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.needsParentalConsent = false,
    this.ecoPoints = 0,
    this.achievementsCount = 0,
    this.lessonsCompleted = 0,
    this.level = 'Eco Explorer',
  });

  String get fullName => '$firstName $lastName';
  bool get isMinor => age < 13;
  int get daysActive => DateTime.now().difference(createdAt).inDays;

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    age,
    avatarUrl,
    bio,
    location,
    createdAt,
    updatedAt,
    lastLogin,
    needsParentalConsent,
    ecoPoints,
    achievementsCount,
    lessonsCompleted,
    level,
  ];

  get profilePicture => null;
}
