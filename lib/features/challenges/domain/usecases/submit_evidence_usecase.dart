// lib/features/challenges/domain/usecases/submit_evidence_usecase.dart - NUEVO
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/challenges_repository.dart';

class SubmitEvidenceParams extends Equatable {
  final String userChallengeId;
  final String submissionType;
  final String contentText;
  final List<String> mediaUrls;
  final Map<String, dynamic>? locationData;
  final Map<String, dynamic>? measurementData;
  final Map<String, dynamic>? metadata;

  const SubmitEvidenceParams({
    required this.userChallengeId,
    required this.submissionType,
    required this.contentText,
    required this.mediaUrls,
    this.locationData,
    this.measurementData,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    userChallengeId,
    submissionType,
    contentText,
    mediaUrls,
    locationData,
    measurementData,
    metadata,
  ];
}

@injectable
class SubmitEvidenceUseCase implements UseCase<void, SubmitEvidenceParams> {
  final ChallengesRepository repository;

  SubmitEvidenceUseCase(this.repository) {
    print('✅ [SUBMIT EVIDENCE USE CASE] Constructor');
  }

  @override
  Future<Either<Failure, void>> call(SubmitEvidenceParams params) {
    print('🎯 [SUBMIT EVIDENCE USE CASE] Executing - submitting evidence for: ${params.userChallengeId}');
    
    // Necesitamos hacer un cast del repository para acceder al método
    final repositoryImpl = repository as dynamic;
    return repositoryImpl.submitEvidence(
      userChallengeId: params.userChallengeId,
      submissionType: params.submissionType,
      contentText: params.contentText,
      mediaUrls: params.mediaUrls,
      locationData: params.locationData,
      measurementData: params.measurementData,
      metadata: params.metadata,
    );
  }
}