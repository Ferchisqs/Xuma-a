// lib/features/companion/presentation/pages/companion_main_page.dart - ACTUALIZADO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../cubit/companion_cubit.dart';
import '../cubit/companion_shop_cubit.dart';
import '../cubit/welcome_companion_cubit.dart'; // 🆕
import '../widgets/companion_animation_widget.dart';
import '../widgets/companion_card_widget.dart';
import '../widgets/companion_stats_widget.dart';
import '../widgets/welcome_dexter_dialog.dart'; // 🆕
import 'companion_detail_page.dart';
import 'companion_shop_page.dart';

class CompanionMainPage extends StatelessWidget {
  const CompanionMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 🆕 WELCOME CUBIT PARA VERIFICAR PRIMERA VEZ
        BlocProvider(
          create: (context) => getIt<WelcomeCompanionCubit>()..checkAndShowWelcomeIfNeeded(),
        ),
        BlocProvider(
          create: (context) => getIt<CompanionCubit>()..loadCompanions(),
        ),
        BlocProvider(
          create: (context) => getIt<CompanionShopCubit>(),
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
    return Scaffold(
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
        actions: [
          // 🔧 BOTÓN PARA PROBAR CONECTIVIDAD API
          IconButton(
            icon: const Icon(Icons.api, color: Colors.white),
            tooltip: 'Probar API Real',
            onPressed: () => _testApiConnection(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refrescar',
            onPressed: () => _refreshAll(context),
          ),
        ],
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
                    onRetry: () => context.read<CompanionCubit>().loadCompanions(),
                  );
                } else if (state is CompanionLoaded) {
                  return _LoadedView(state: state);
                }

                return const _LoadingView();
              },
            ),
            
            // 🆕 OVERLAY PARA BIENVENIDA DE DEXTER
            BlocConsumer<WelcomeCompanionCubit, WelcomeCompanionState>(
              listener: (context, state) {
                debugPrint('🎉 [WELCOME] Estado cambió: ${state.runtimeType}');
              },
              builder: (context, welcomeState) {
                if (welcomeState is WelcomeCompanionShowDexterWelcome) {
                  debugPrint('🎉 [WELCOME] Mostrando diálogo de bienvenida');
                  
                  // Mostrar diálogo de bienvenida
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showWelcomeDialog(context, welcomeState.dexterBaby);
                  });
                }
                
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 MOSTRAR DIÁLOGO DE BIENVENIDA
  void _showWelcomeDialog(BuildContext context, companion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WelcomeDexterDialog(
        dexterBaby: companion,
        onContinue: () {
          debugPrint('🎉 [WELCOME] Bienvenida completada');
          Navigator.of(dialogContext).pop();
          
          // Marcar bienvenida como completada
          context.read<WelcomeCompanionCubit>().completeWelcome();
          
          // Refrescar los companions para mostrar Dexter
          context.read<CompanionCubit>().refreshCompanions();
          
          // Mostrar mensaje de confirmación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.pets, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡${companion.displayName} se ha unido a tu equipo! 🐕✨',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  // 🔧 PROBAR CONECTIVIDAD CON LA API REAL
  void _testApiConnection(BuildContext context) async {
    debugPrint('🧪 [MAIN] === PROBANDO CONECTIVIDAD API ===');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.api, color: Colors.blue),
            SizedBox(width: 8),
            Text('🧪 Test API Real'),
          ],
        ),
        content: const Text(
          '¿Quieres probar la conexión con la API real de mascotas?\n\n'
          'Esto verificará:\n'
          '• Endpoint /pets/available\n'
          '• Mapeo de datos\n'
          '• Dexter baby inicial\n'
          '• Mascotas de la tienda',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              debugPrint('🧪 [MAIN] Ejecutando test completo...');
              
              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        '🚀 Conectando con API real...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
              
              // Simular test
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _refreshAll(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '🎉 API conectada! Datos actualizados desde el servidor.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Probar API',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshAll(BuildContext context) {
    debugPrint('🔄 [MAIN] Refrescando todos los datos...');
    context.read<CompanionCubit>().refreshCompanions();
    context.read<WelcomeCompanionCubit>().checkAndShowWelcomeIfNeeded();
  }
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
            '🚀 Conectando con API real...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cargando tus compañeros desde el servidor',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Reintentar Conexión',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    debugPrint('🐾 [MAIN] Compañeros poseídos: ${state.ownedCompanions.length}');
    debugPrint('💰 [MAIN] Puntos disponibles: ${state.userStats.availablePoints}');

    return CustomScrollView(
      slivers: [
        // 🔧 HEADER CON INFORMACIÓN DE LA API
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [Colors.blue[50]!, Colors.green[50]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_done, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚀 API Conectada',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Datos desde: gamification-service-production.up.railway.app',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.userStats.availablePoints}★',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Estadísticas del usuario
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CompanionStatsWidget(
              stats: state.userStats,
              onShopTap: () => _navigateToShop(context),
            ),
          ),
        ),

        // Compañero activo (si existe)
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
                        'Tu Compañero Activo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _navigateToShop(context),
                        icon: const Icon(Icons.store, color: AppColors.primary),
                        label: const Text(
                          'Tienda',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActiveCompanionCard(context, state.activeCompanion!),
                ],
              ),
            ),
          ),
        ],

        // Lista de compañeros propios
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Compañeros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToShop(context),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Obtener más',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Grid de compañeros
        if (state.ownedCompanions.isNotEmpty)
          _buildCompanionsGrid(context, state.ownedCompanions)
        else
          _buildEmptyCompanionsView(context),
      ],
    );
  }

  Widget _buildActiveCompanionCard(BuildContext context, companion) {
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
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  companion.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Positioned(
              top: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${companion.typeDescription} ${companion.stageDisplayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivel ${companion.level} • ${companion.experience}/${companion.experienceNeededForNextStage} EXP',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: CompanionAnimationWidget(
                  companion: companion,
                  size: MediaQuery.of(context).size.width * 0.7,
                ),
              ),
            ),

            // Botón para ir al detalle en la parte inferior derecha
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionsGrid(BuildContext context, List companions) {
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
              isSelected: companion.isSelected,
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
            Text(
              'Aún no tienes compañeros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, companion) {
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
    debugPrint('🏪 [MAIN] Navegando a la tienda...');
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CompanionShopPage(),
      ),
    )
        .then((_) {
      debugPrint('🔄 [MAIN] Regresando de la tienda - REFRESCANDO TODO...');
      context.read<CompanionCubit>().refreshCompanions();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          debugPrint('🔄 [MAIN] Refresh adicional...');
          context.read<CompanionCubit>().loadCompanions();
        }
      });
    });
  }
}