import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../cubit/navigation_cubit.dart';
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
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Xico small icon
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible( // 🔄 Cambiar Column por Flexible
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola eco-explorador!',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis, // 🆕 Evitar desbordamiento
                              ),
                              Text(
                                'Con Xico tu guía',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis, // 🆕 Evitar desbordamiento
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          context.read<NavigationCubit>().goToHome();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.article_rounded,
                        title: 'Noticias',
                        isSelected: state.currentTab == NavigationTab.news,
                        onTap: () {
                          context.read<NavigationCubit>().goToNews();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.school_rounded,
                        title: 'Aprendamos',
                        isSelected: state.currentTab == NavigationTab.learn,
                        onTap: () {
                          context.read<NavigationCubit>().goToLearn();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.construction_rounded,
                        title: 'Proyectos',
                        isSelected: state.currentTab == NavigationTab.projects,
                        onTap: () {
                          context.read<NavigationCubit>().goToProjects();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.emoji_events_rounded,
                        title: 'Desafíos',
                        isSelected: state.currentTab == NavigationTab.challenges,
                        onTap: () {
                          context.read<NavigationCubit>().goToChallenges();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.groups_rounded,
                        title: 'Comunidad',
                        isSelected: state.currentTab == NavigationTab.community,
                        onTap: () {
                          context.read<NavigationCubit>().goToCommunity();
                          Navigator.of(context).pop();
                        },
                      ),
                      NavItemWidget(
                        icon: Icons.help_outline_rounded,
                        title: 'Contacto', // 🔄 Cambié "Contactanos" por "Contacto"
                        isSelected: state.currentTab == NavigationTab.contact,
                        onTap: () {
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
          const UserProfileWidget(),
        ],
      ),
    );
  }
}