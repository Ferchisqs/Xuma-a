import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart'; // 🆕 IMPORT EXPLÍCITO
import '../../../navigation/presentation/cubit/navigation_cubit.dart'; // 🆕 IMPORT CUBIT
import '../cubit/challenges_cubit.dart';
import '../widgets/challenges_header_widget.dart';
import '../widgets/challenge_tabs_widget.dart';
import '../widgets/challenge_grid_widget.dart';

class ChallengesMainPage extends StatelessWidget {
  const ChallengesMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔄 VERIFICAR SI YA EXISTE NAVIGATION CUBIT EN EL CONTEXTO
    return BlocProvider.value(
      // 🔄 USAR EL CUBIT EXISTENTE DEL MAIN WRAPPER
      value: context.read<NavigationCubit>(),
      child: BlocProvider(
        create: (_) => getIt<ChallengesCubit>()..loadChallenges(),
        child: const _ChallengesMainContent(),
      ),
    );
  }
}

class _ChallengesMainContent extends StatelessWidget {
  const _ChallengesMainContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // 🔄 DRAWER DIRECTO - asegurar que está disponible
      drawer: const SideNavBar(),
      appBar: const CustomAppBar(
        title: 'Desafíos',
        showDrawerButton: true,
        showEcoTip: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ChallengesCubit>().refreshChallenges();
        },
        child: BlocBuilder<ChallengesCubit, ChallengesState>(
          builder: (context, state) {
            if (state is ChallengesLoading) {
              return const Center(
                child: EcoLoadingWidget(
                  message: 'Cargando desafíos...',
                ),
              );
            }

            if (state is ChallengesError) {
              return Center(
                child: EcoErrorWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<ChallengesCubit>().loadChallenges();
                  },
                ),
              );
            }

            if (state is ChallengesLoaded || state is ChallengesRefreshing) {
              final loadedState = state as ChallengesLoaded;
              
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con estadísticas del usuario
                    ChallengesHeaderWidget(
                      userStats: loadedState.userStats,
                      activeChallengesCount: loadedState.activeChallenges.length,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pestañas para filtrar desafíos
                    ChallengeTabsWidget(
                      currentFilter: loadedState.currentFilter,
                      onFilterChange: (type) {
                        context.read<ChallengesCubit>().filterByType(type);
                      },
                      dailyCount: loadedState.dailyChallenges.length,
                      weeklyCount: loadedState.weeklyChallenges.length,
                      monthlyCount: loadedState.monthlyChallenges.length,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Grid de desafíos
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ChallengeGridWidget(
                        challenges: loadedState.filteredChallenges,
                        isRefreshing: state is ChallengesRefreshing,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}