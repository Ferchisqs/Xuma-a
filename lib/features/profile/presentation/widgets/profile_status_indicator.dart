// lib/features/profile/presentation/widgets/profile_status_indicator.dart
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
          
          if (compact) {
            return _buildCompactIndicator(hasFullProfile);
          } else {
            return _buildFullIndicator(authState, hasFullProfile);
          }
        } else if (authState is AuthLoadingFullProfile) {
          return _buildLoadingIndicator();
        } else {
          return _buildNotAuthenticatedIndicator();
        }
      },
    );
  }

  Widget _buildCompactIndicator(bool hasFullProfile) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: hasFullProfile ? AppColors.success : AppColors.warning,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFullIndicator(AuthAuthenticated authState, bool hasFullProfile) {
    final iconData = hasFullProfile ? Icons.check_circle : Icons.schedule;
    final color = hasFullProfile ? AppColors.success : AppColors.warning;
    final text = hasFullProfile ? 'Perfil completo' : 'Cargando perfil...';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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