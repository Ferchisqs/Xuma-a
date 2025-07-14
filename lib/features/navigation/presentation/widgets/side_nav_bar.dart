// lib/features/navigation/presentation/widgets/side_nav_bar.dart - VERSIÓN MEJORADA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../cubit/navigation_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'nav_item_widget.dart';
import 'user_profile_widget.dart';

class SideNavBar extends StatelessWidget {
  const SideNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.earthGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'XUMA\'A',
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 🆕 SALUDO DINÁMICO MEJORADO
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        return _buildDynamicGreeting(authState);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: BlocBuilder<NavigationCubit, NavigationState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      NavItemWidget(
                        icon: Icons.home_rounded,
                        title: 'Inicio',
                        isSelected: state.currentTab == NavigationTab.home,
                        onTap: () {
                          debugPrint('🏠 Navegando a Home...');
                          context.read<NavigationCubit>().goToHome();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.pets_rounded,
                        title: 'Compañero',
                        isSelected: state.currentTab == NavigationTab.companion,
                        onTap: () {
                          debugPrint('🐾 Navegando a Compañero...');
                          context.read<NavigationCubit>().goToCompanion();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.school_rounded,
                        title: 'Aprendamos',
                        isSelected: state.currentTab == NavigationTab.learn,
                        onTap: () {
                          debugPrint('📚 Navegando a Aprendamos...');
                          context.read<NavigationCubit>().goToLearn();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.quiz_rounded,
                        title: 'Trivias',
                        isSelected: state.currentTab == NavigationTab.trivia,
                        onTap: () {
                          debugPrint('🧠 Navegando a Trivias...');
                          context.read<NavigationCubit>().goToTrivia();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.emoji_events_rounded,
                        title: 'Desafíos',
                        isSelected: state.currentTab == NavigationTab.challenges,
                        onTap: () {
                          debugPrint('🏆 Navegando a Desafíos...');
                          context.read<NavigationCubit>().goToChallenges();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.help_outline_rounded,
                        title: 'Contacto',
                        isSelected: state.currentTab == NavigationTab.contact,
                        onTap: () {
                          debugPrint('📞 Navegando a Contacto...');
                          context.read<NavigationCubit>().goToContact();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // User Profile at bottom
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return const UserProfileWidget();
            },
          ),
        ],
      ),
    );
  }

  // 🆕 MÉTODO MEJORADO PARA CONSTRUIR SALUDO DINÁMICO
  Widget _buildDynamicGreeting(AuthState authState) {
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final fullProfile = authState.fullProfile;
      final isLoadingProfile = authState.isProfileLoading;
      
      // Usar nombre del perfil completo si está disponible
      final firstName = fullProfile?.firstName ?? user.firstName;
      final userLevel = fullProfile?.level ?? _getUserLevelFromAge(user.age);
      
      return Row(
        children: [
          // Xico icon con estado
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: isLoadingProfile 
                ? Border.all(color: Colors.white.withOpacity(0.5), width: 2)
                : null,
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
              : const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 24,
                ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola ${firstName.isNotEmpty ? firstName : 'eco-explorador'}!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isLoadingProfile ? 'Cargando nivel...' : userLevel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 🆕 INDICADOR DE PERFIL COMPLETO
                    if (fullProfile != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ] else if (isLoadingProfile) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 6,
                        height: 6,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (authState is AuthLoading) {
      return _buildLoadingGreeting(authState.message);
    } else {
      return _buildGuestGreeting();
    }
  }

  // 🆕 SALUDO DE CARGA MEJORADO
  Widget _buildLoadingGreeting(String? message) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message ?? 'Cargando...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Preparando tu experiencia',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🆕 SALUDO DE INVITADO
  Widget _buildGuestGreeting() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.pets_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola visitante!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Únete a Xico',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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