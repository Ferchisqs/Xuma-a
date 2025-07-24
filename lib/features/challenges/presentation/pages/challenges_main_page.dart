// lib/features/challenges/presentation/pages/challenges_main_page.dart - ACTUALIZADO CON AUTENTICACIÓN
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../cubit/challenges_cubit.dart';
import '../widgets/challenges_header_widget.dart';
import '../widgets/challenge_tabs_widget.dart';
import '../widgets/challenge_grid_widget.dart';
import '../widgets/challenges_auth_prompt_widget.dart'; // 🆕 NUEVO WIDGET

class ChallengesMainPage extends StatelessWidget {
  const ChallengesMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<NavigationCubit>(),
      child: BlocProvider(
        create: (_) => getIt<ChallengesCubit>()..loadWithAuthCheck(), // 🔧 USAR MÉTODO CON CHECK
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

            // 🆕 ESTADO PARA USUARIO NO AUTENTICADO
            if (state is ChallengesNotAuthenticated) {
              return _buildNotAuthenticatedView(context, state.message);
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

  // 🆕 VISTA PARA USUARIO NO AUTENTICADO
  Widget _buildNotAuthenticatedView(BuildContext context, String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header motivacional para usuarios no autenticados
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.earthGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Únete a la Comunidad Eco!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubre desafíos ambientales, gana puntos y ayuda a salvar el planeta junto a Xico',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Widget de prompt de autenticación
          ChallengesAuthPromptWidget(
            message: message,
            onLogin: () {
              Navigator.pushNamed(context, '/login');
            },
            onRegister: () {
              Navigator.pushNamed(context, '/register');
            },
          ),

          const SizedBox(height: 24),

          // Mostrar algunos desafíos de ejemplo (sin funcionalidad)
          _buildSampleChallenges(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 🆕 DESAFÍOS DE EJEMPLO PARA MOTIVAR EL REGISTRO
  Widget _buildSampleChallenges(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ejemplos de Desafíos Disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSampleChallengeCard(
                'Recicla 10 Botellas',
                '100 pts',
                Icons.recycling,
                AppColors.success,
              ),
              _buildSampleChallengeCard(
                'Composta Casera',
                '200 pts',
                Icons.compost,
                AppColors.earth,
              ),
              _buildSampleChallengeCard(
                'Ahorra Energía',
                '150 pts',
                Icons.lightbulb,
                AppColors.warning,
              ),
              _buildSampleChallengeCard(
                'Planta un Árbol',
                '300 pts',
                Icons.park,
                AppColors.nature,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleChallengeCard(
    String title,
    String points,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Overlay para indicar que requiere login
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          points,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Diario',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}