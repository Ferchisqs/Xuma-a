import 'package:equatable/equatable.dart';

class ParentalInfo extends Equatable {
  final String guardianName;
  final String relationship;
  final String guardianEmail;

  const ParentalInfo({
    required this.guardianName,
    required this.relationship,
    required this.guardianEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'guardianName': guardianName,
      'relationship': relationship,
      'guardianEmail': guardianEmail,
    };
  }

  @override
  List<Object> get props => [guardianName, relationship, guardianEmail];
}