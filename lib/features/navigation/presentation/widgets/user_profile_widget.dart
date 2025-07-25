// lib/features/navigation/presentation/widgets/user_profile_widget.dart - VERSIÓN MEJORADA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../cubit/navigation_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          debugPrint('👤 Navegando a Perfil...');
          context.read<NavigationCubit>().goToProfile();
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            // 🆕 MANEJO MEJORADO DE ESTADOS
            if (authState is AuthAuthenticated) {
              return _buildAuthenticatedUserProfile(authState);
            } else if (authState is AuthLoading) {
              return _buildLoadingProfile(authState.message);
            } else {
              return _buildGuestProfile();
            }
          },
        ),
      ),
    );
  }

  // 🆕 MOSTRAR PERFIL DE USUARIO AUTENTICADO MEJORADO
  Widget _buildAuthenticatedUserProfile(AuthAuthenticated authState) {
    final user = authState.user;
    final fullProfile = authState.fullProfile;
    final isLoadingProfile = authState.isProfileLoading;
    
    // Usar datos del perfil completo si está disponible, sino usar datos básicos
    final displayName = fullProfile?.fullName ?? user.fullName;
    final userLevel = fullProfile?.level ?? _getUserLevelFromAge(user.age);
    final avatarUrl = fullProfile?.avatarUrl;
    final ecoPoints = fullProfile?.ecoPoints ?? 0;
    
    return Row(
      children: [
        // User avatar con indicador de estado
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLoadingProfile 
                ? AppColors.warning.withOpacity(0.5)
                : AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: isLoadingProfile 
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : _buildUserAvatar(avatarUrl),
        ),
        const SizedBox(width: 12),
        
        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.isNotEmpty ? displayName : 'Usuario',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isLoadingProfile ? 'Cargando...' : userLevel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isLoadingProfile 
                          ? AppColors.textHint 
                          : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (fullProfile != null && !isLoadingProfile) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.stars_rounded,
                      color: AppColors.warning,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$ecoPoints',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Status indicator and arrow
        Column(
          children: [
            // 🆕 INDICADOR DE ESTADO MEJORADO
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(fullProfile, isLoadingProfile),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  // 🆕 OBTENER COLOR DE ESTADO
  Color _getStatusColor(dynamic fullProfile, bool isLoadingProfile) {
    if (isLoadingProfile) return AppColors.warning;
    if (fullProfile != null) return AppColors.success;
    return AppColors.info; // Perfil básico disponible
  }

  // 🆕 MOSTRAR ESTADO DE CARGA MEJORADO
  Widget _buildLoadingProfile(String? message) {
    return Row(
      children: [
        // Loading avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Loading info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message ?? 'Cargando...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Preparando perfil...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Loading indicator
        Icon(
          Icons.refresh_rounded,
          color: AppColors.textSecondary,
          size: 16,
        ),
      ],
    );
  }

  // 🆕 MOSTRAR PERFIL DE INVITADO
  Widget _buildGuestProfile() {
    return Row(
      children: [
        // Guest avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.textHint.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textHint,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        
        // Guest info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invitado',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Inicia sesión',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        
        // Login indicator
        Icon(
          Icons.login_rounded,
          color: AppColors.primary,
          size: 16,
        ),
      ],
    );
  }

  // 🆕 HELPER PARA MOSTRAR AVATAR
  Widget _buildUserAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 24,
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
        ),
      );
    }
    
    return const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 24,
    );
  }

  // 🆕 HELPER PARA OBTENER NIVEL BASADO EN EDAD
  String _getUserLevelFromAge(int age) {
    if (age < 13) return 'Eco Explorer';
    if (age < 18) return 'Eco Guardian';
    if (age < 25) return 'Eco Warrior';
    return 'Eco Master';
  }
}