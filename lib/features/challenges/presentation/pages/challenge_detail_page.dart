// lib/features/challenges/presentation/pages/challenge_detail_page.dart - VERSIÓN COMPLETA
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
import '../widgets/evidence_submission_button.dart';

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
          } else if (state is ChallengeNotAuthenticated) {
            _showLoginDialog(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ChallengeDetailLoaded || 
              state is ChallengeDetailUpdating ||
              state is ChallengeJoinSuccess ||
              state is ChallengeCompleted ||
              state is ChallengeEvidenceRequired ||
              state is ChallengePendingValidation) {
            
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
                        
                        // Botón de evidencia (si se requiere)
                        if (state is ChallengeEvidenceRequired)
                          Column(
                            children: [
                              EvidenceSubmissionButton(
                                challenge: currentChallenge,
                                userChallengeId: state.userChallengeId,
                                onEvidenceSubmitted: () {
                                  context.read<ChallengeDetailCubit>()
                                      .loadChallenge(currentChallenge);
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),

                        // Estado de validación pendiente
                        if (state is ChallengePendingValidation)
                          Column(
                            children: [
                              _buildPendingValidationWidget(state),
                              const SizedBox(height: 24),
                            ],
                          ),
                        
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
                        
                        // Botones de acción (solo si no requiere evidencia)
                        if (state is! ChallengeEvidenceRequired && 
                            state is! ChallengePendingValidation)
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

          // Estado para no autenticación
          if (state is ChallengeNotAuthenticated) {
            return _buildNotAuthenticatedView(context, state.message);
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

  // Widget para estado de validación pendiente
  Widget _buildPendingValidationWidget(ChallengePendingValidation state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: AppColors.warning,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Evidencia Enviada!',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu evidencia está siendo revisada por nuestro equipo. Recibirás una notificación cuando sea validada.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enviado: ${_formatDate(state.submissionDate)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // Vista para usuario no autenticado
  Widget _buildNotAuthenticatedView(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header del desafío (visible para todos)
          ChallengeHeaderWidget(challenge: challenge),
          
          const SizedBox(height: 24),
          
          // Mensaje de autenticación requerida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.login,
                  color: AppColors.info,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Inicia Sesión para Participar',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Beneficios de registrarse
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Al unirte podrás:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(Icons.emoji_events, 'Ganar ${challenge.totalPoints} puntos'),
                      _buildBenefitRow(Icons.trending_up, 'Seguir tu progreso ambiental'),
                      _buildBenefitRow(Icons.groups, 'Competir con otros eco-warriors'),
                      _buildBenefitRow(Icons.card_giftcard, 'Desbloquear recompensas especiales'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Botones de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Iniciar Sesión',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate gratis',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Información del desafío (visible para todos)
          ChallengeRequirementsWidget(
            requirements: challenge.requirements,
          ),
          
          const SizedBox(height: 16),
          
          ChallengeRewardsWidget(
            rewards: challenge.rewards,
            points: challenge.totalPoints,
          ),
          
          const SizedBox(height: 24),
          
          // Widget motivacional
          _buildMotivationalWidget(),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.earthGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Xico te está esperando',
            style: AppTextStyles.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu mascota virtual necesita que protejas el medio ambiente. ¡Cada desafío completado la hace más feliz!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ChallengeEntity _getCurrentChallenge(ChallengeDetailState state) {
    if (state is ChallengeDetailLoaded) return state.challenge;
    if (state is ChallengeDetailUpdating) return state.challenge;
    if (state is ChallengeJoinSuccess) return state.challenge;
    if (state is ChallengeCompleted) return state.challenge;
    if (state is ChallengeEvidenceRequired) return state.challenge;
    if (state is ChallengePendingValidation) return state.challenge;
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

  void _showLoginDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.login,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Iniciar Sesión',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Es gratis y solo toma 2 minutos',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Iniciar Sesión',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}