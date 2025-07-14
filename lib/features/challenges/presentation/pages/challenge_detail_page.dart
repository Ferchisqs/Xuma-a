import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/challenge_entity.dart';
import '../cubit/challenge_detail_cubit.dart';
import '../widgets/challenge_header_widget.dart';
import '../widgets/challenge_progress_widget.dart';
import '../widgets/challenge_requirements_widget.dart';
import '../widgets/challenge_rewards_widget.dart';
import '../widgets/challenge_action_buttons_widget.dart';
import '../widgets/challenge_completion_dialog.dart';

class ChallengeDetailPage extends StatelessWidget {
  final ChallengeEntity challenge;

  const ChallengeDetailPage({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChallengeDetailCubit>()..loadChallenge(challenge),
      child: _ChallengeDetailContent(challenge: challenge),
    );
  }
}

class _ChallengeDetailContent extends StatelessWidget {
  final ChallengeEntity challenge;

  const _ChallengeDetailContent({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Desafío',
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
      body: BlocConsumer<ChallengeDetailCubit, ChallengeDetailState>(
        listener: (context, state) {
          if (state is ChallengeDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is ChallengeJoinSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Te has unido al desafío!'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ChallengeCompleted) {
            _showCompletionDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is ChallengeDetailLoaded || 
              state is ChallengeDetailUpdating ||
              state is ChallengeJoinSuccess ||
              state is ChallengeCompleted) {
            
            final currentChallenge = _getCurrentChallenge(state);
            
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header del desafío
                  ChallengeHeaderWidget(challenge: currentChallenge),
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progreso (solo si participa)
                        if (currentChallenge.isParticipating)
                          ChallengeProgressWidget(
                            challenge: currentChallenge,
                            onProgressUpdate: (newProgress) {
                              context.read<ChallengeDetailCubit>()
                                  .updateProgress(currentChallenge, newProgress);
                            },
                          ),
                        
                        if (currentChallenge.isParticipating)
                          const SizedBox(height: 24),
                        
                        // Descripción
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Descripción',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentChallenge.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Requisitos
                        ChallengeRequirementsWidget(
                          requirements: currentChallenge.requirements,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Recompensas
                        ChallengeRewardsWidget(
                          rewards: currentChallenge.rewards,
                          points: currentChallenge.totalPoints,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Botones de acción
                        ChallengeActionButtonsWidget(
                          challenge: currentChallenge,
                          isLoading: state is ChallengeDetailUpdating,
                          onJoin: () {
                            context.read<ChallengeDetailCubit>()
                                .joinChallenge(currentChallenge);
                          },
                          onAddProgress: () {
                            context.read<ChallengeDetailCubit>()
                                .incrementProgress(currentChallenge);
                          },
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: EcoLoadingWidget(
              message: 'Cargando desafío...',
            ),
          );
        },
      ),
    );
  }

  ChallengeEntity _getCurrentChallenge(ChallengeDetailState state) {
    if (state is ChallengeDetailLoaded) return state.challenge;
    if (state is ChallengeDetailUpdating) return state.challenge;
    if (state is ChallengeJoinSuccess) return state.challenge;
    if (state is ChallengeCompleted) return state.challenge;
    return challenge; // fallback
  }

  void _showCompletionDialog(BuildContext context, ChallengeCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChallengeCompletionDialog(
        challenge: state.challenge,
        pointsEarned: state.pointsEarned,
        onContinue: () {
          Navigator.of(dialogContext).pop();
          context.read<ChallengeDetailCubit>().resetToLoaded();
        },
      ),
    );
  }
}