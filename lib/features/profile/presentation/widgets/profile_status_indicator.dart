// lib/features/profile/presentation/widgets/profile_status_indicator.dart - CORREGIDO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ProfileStatusIndicator extends StatelessWidget {
  final bool showText;
  final bool compact;

  const ProfileStatusIndicator({
    Key? key,
    this.showText = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final hasFullProfile = authState.fullProfile != null;
          final isLoadingProfile = authState.isProfileLoading;
          
          if (compact) {
            return _buildCompactIndicator(hasFullProfile, isLoadingProfile);
          } else {
            return _buildFullIndicator(authState, hasFullProfile, isLoadingProfile);
          }
        } else if (authState is AuthLoading) {
          return _buildLoadingIndicator();
        } else {
          return _buildNotAuthenticatedIndicator();
        }
      },
    );
  }

  Widget _buildCompactIndicator(bool hasFullProfile, bool isLoadingProfile) {
    if (isLoadingProfile) {
      return SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: hasFullProfile ? AppColors.success : AppColors.warning,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFullIndicator(AuthAuthenticated authState, bool hasFullProfile, bool isLoadingProfile) {
    IconData iconData;
    Color color;
    String text;

    if (isLoadingProfile) {
      iconData = Icons.schedule;
      color = AppColors.primary;
      text = 'Cargando perfil...';
    } else if (hasFullProfile) {
      iconData = Icons.check_circle;
      color = AppColors.success;
      text = 'Perfil completo';
    } else {
      iconData = Icons.info_outline;
      color = AppColors.warning;
      text = 'Perfil básico';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoadingProfile) 
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else
          Icon(
            iconData,
            color: color,
            size: 16,
          ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            'Cargando...',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotAuthenticatedIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_outline,
          color: AppColors.textHint,
          size: 16,
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            'No autenticado',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }
}