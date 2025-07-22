// lib/features/companion/presentation/pages/companion_main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xuma_a/features/companion/domain/entities/companion_entity.dart';
import '../../../../di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../cubit/companion_cubit.dart';
import '../cubit/companion_actions_cubit.dart';
import '../cubit/companion_shop_cubit.dart';
import '../widgets/companion_animation_widget.dart';
import '../widgets/companion_card_widget.dart';
import '../widgets/companion_stats_widget.dart';
import 'companion_detail_page.dart';
import 'companion_shop_page.dart';

class CompanionMainPage extends StatelessWidget {
  const CompanionMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Cubit principal de companions
        BlocProvider(
          create: (context) => getIt<CompanionCubit>()..loadCompanions(),
        ),
        // Cubit de la tienda
        BlocProvider(
          create: (context) => getIt<CompanionShopCubit>(),
        ),
        // Cubit de acciones (para feed, love, evolve, etc.)
        BlocProvider(
          create: (context) => getIt<CompanionActionsCubit>(),
        ),
      ],
      child: const _CompanionMainView(),
    );
  }
}

class _CompanionMainView extends StatelessWidget {
  const _CompanionMainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener para acciones de compañeros
        BlocListener<CompanionActionsCubit, CompanionActionsState>(
          listener: (context, state) {
            if (state is CompanionActionsSuccess) {
              debugPrint('✅ [ACTIONS] Acción exitosa: ${state.action}');

              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        _getActionIcon(state.action),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Refrescar companions después de acción exitosa
              context.read<CompanionCubit>().refreshCompanions();
            } else if (state is CompanionActionsError) {
              debugPrint('❌ [ACTIONS] Error: ${state.message}');

              // Mostrar mensaje de error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const SideNavBar(),
        appBar: AppBar(
          title: const Text('Compañeros'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // CONTENIDO PRINCIPAL
              BlocBuilder<CompanionCubit, CompanionState>(
                builder: (context, state) {
                  if (state is CompanionLoading) {
                    return const _LoadingView();
                  } else if (state is CompanionError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<CompanionCubit>().loadCompanions(),
                    );
                  } else if (state is CompanionLoaded) {
                    return _LoadedView(state: state);
                  }

                  return const _LoadingView();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obtener ícono para cada acción
  IconData _getActionIcon(String action) {
    switch (action) {
      case 'feeding':
        return Icons.restaurant;
      case 'loving':
        return Icons.favorite;
      case 'evolving':
        return Icons.auto_awesome;
      case 'featuring':
        return Icons.star;
      default:
        return Icons.check;
    }
  }

  // Mostrar diálogo de bienvenida
}

// ==================== VISTAS AUXILIARES ====================

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando compañeros...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '📡 Error de Conexión API',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Reintentar Conexión',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Mostrar modo offline con datos locales
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📱 Usando datos locales temporalmente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.offline_pin),
                  label: const Text('Usar Datos Locales'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final CompanionLoaded state;

  const _LoadedView({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 [MAIN] === MOSTRANDO VISTA CARGADA ===');
    debugPrint(
        '🐾 [MAIN] Compañeros poseídos: ${state.ownedCompanions.length}');
    debugPrint(
        '💰 [MAIN] Puntos disponibles: ${state.userStats.availablePoints}');

    return CustomScrollView(
      slivers: [
        // HEADER CON INFORMACIÓN DE LA API
      

        // Estadísticas del usuario
        SliverToBoxAdapter(
          child: Padding(
             padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: CompanionStatsWidget(
              stats: state.userStats,
              onShopTap: () => _navigateToShop(context),
            ),
          ),
        ),

        // SECCIÓN: COMPAÑERO ACTIVO/DESTACADO
        if (state.activeCompanion != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '⭐ Tu Compañero Activo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // BOTÓN PARA CAMBIAR COMPAÑERO ACTIVO
                      IconButton(
                        onPressed: () => _showSelectActiveCompanionDialog(
                            context, state.ownedCompanions),
                        icon: const Icon(Icons.swap_horiz,
                            color: AppColors.primary),
                        tooltip: 'Cambiar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActiveCompanionCard(context, state.activeCompanion!),
                ],
              ),
            ),
          ),
        ] else if (state.ownedCompanions.isNotEmpty) ...[
          // SI NO HAY ACTIVO PERO SÍ HAY MASCOTAS, MOSTRAR PRIMERA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🐾 Tu Primera Mascota',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActiveCompanionCard(
                      context, state.ownedCompanions.first),
                ],
              ),
            ),
          ),
        ],

        // SECCIÓN: TODAS MIS MASCOTAS ADOPTADAS
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Compañeros (${state.ownedCompanions.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToShop(context),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Adoptar más',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),

        // GRID DE MASCOTAS ADOPTADAS
        if (state.ownedCompanions.isNotEmpty)
          _buildOwnedCompanionsGrid(context, state.ownedCompanions)
        else
          _buildEmptyCompanionsView(context),
      ],
    );
  }

  // TARJETA DE COMPAÑERO ACTIVO CON ACCIONES
  Widget _buildActiveCompanionCard(BuildContext context, dynamic companion) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, companion),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Header con nombre
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  companion.displayName ?? 'Compañero',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Info y nivel
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${companion.typeDescription ?? 'Mascota'} ${companion.stageDisplayName ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivel ${companion.level ?? 1} • ${companion.experience ?? 0}/${companion.experienceNeededForNextStage ?? 100} EXP',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // MASCOTA CON FONDO
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 60),
                child: CompanionAnimationWidget(
                  companion: companion,
                  size: MediaQuery.of(context).size.width * 0.7,
                  showBackground: true, // CON FONDO EN MAIN PAGE
                ),
              ),
            ),

            // ACCIONES RÁPIDAS EN LA PARTE INFERIOR
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    onPressed: () => _feedCompanion(context, companion),
                    needsAttention: companion.needsFood ?? false,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.favorite,
                    color: Colors.pink,
                    onPressed: () => _loveCompanion(context, companion),
                    needsAttention: companion.needsLove ?? false,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.auto_awesome,
                    color: Colors.purple,
                    onPressed: (companion.canEvolve ?? false)
                        ? () => _evolveCompanion(context, companion)
                        : null,
                    needsAttention: companion.canEvolve ?? false,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.visibility,
                    color: Colors.blue,
                    onPressed: () => _navigateToDetail(context, companion),
                    needsAttention: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BOTÓN DE ACCIÓN RÁPIDA
  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required bool needsAttention,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onPressed != null
            ? (needsAttention ? color : color.withOpacity(0.7))
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(22),
        border:
            needsAttention ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // GRID DE MASCOTAS ADOPTADAS
  Widget _buildOwnedCompanionsGrid(
      BuildContext context, List<dynamic> companions) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final companion = companions[index];
            return CompanionCardWidget(
              companion: companion,
              onTap: () => _navigateToDetail(context, companion),
              isSelected: companion.isSelected ?? false,
              showDetails: true, // MOSTRAR DETALLES COMPLETOS
            );
          },
          childCount: companions.length,
        ),
      ),
    );
  }

  Widget _buildEmptyCompanionsView(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.pets, size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes compañeros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Visita la tienda para conseguir tu primer compañero!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToShop(context),
              icon: const Icon(Icons.store),
              label: const Text('Ir a la Tienda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIÁLOGO PARA SELECCIONAR COMPAÑERO ACTIVO
  void _showSelectActiveCompanionDialog(
      BuildContext context, List<dynamic> companions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Compañero Activo'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: companions.length,
            itemBuilder: (context, index) {
              final companion = companions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCompanionColor(companion.type),
                  child: Icon(
                    _getCompanionIcon(companion.type),
                    color: Colors.white,
                  ),
                ),
                title: Text(companion.displayName ?? 'Compañero'),
                subtitle: Text(
                    '${companion.typeDescription ?? 'Mascota'} ${companion.stageDisplayName ?? ''}'),
                trailing: (companion.isSelected ?? false)
                    ? const Icon(Icons.star, color: Colors.orange)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _featureCompanion(context, companion);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // ACCIONES DE COMPAÑEROS CON BlocProvider
  void _feedCompanion(BuildContext context, dynamic companion) {
    context.read<CompanionActionsCubit>().feedCompanion(companion);
  }

  void _loveCompanion(BuildContext context, dynamic companion) {
    context.read<CompanionActionsCubit>().loveCompanion(companion);
  }

  void _evolveCompanion(BuildContext context, dynamic companion) {
    context.read<CompanionActionsCubit>().evolveCompanion(companion);
  }

  void _featureCompanion(BuildContext context, dynamic companion) {
    context.read<CompanionActionsCubit>().featureCompanion(companion);
  }

  // Métodos helper
  Color _getCompanionColor(CompanionType? type) {
    if (type == null) return Colors.grey;

    switch (type) {
      case CompanionType.dexter:
        return Colors.brown;
      case CompanionType.elly:
        return Colors.green;
      case CompanionType.paxolotl:
        return Colors.cyan;
      case CompanionType.yami:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCompanionIcon(CompanionType? type) {
    if (type == null) return Icons.pets;

    switch (type) {
      case CompanionType.dexter:
        return Icons.pets;
      case CompanionType.elly:
        return Icons.forest;
      case CompanionType.paxolotl:
        return Icons.water;
      case CompanionType.yami:
        return Icons.nature;
      default:
        return Icons.pets;
    }
  }

  void _navigateToDetail(BuildContext context, dynamic companion) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CompanionDetailPage(companion: companion),
      ),
    )
        .then((_) {
      // Refrescar cuando regrese del detalle
      context.read<CompanionCubit>().refreshCompanions();
    });
  }

  void _navigateToShop(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CompanionShopPage(),
      ),
    )
        .then((_) {
      // Refrescar cuando regrese de la tienda
      context.read<CompanionCubit>().refreshCompanions();
    });
  }
}
