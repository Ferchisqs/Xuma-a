import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../cubit/companion_cubit.dart';
import '../widgets/companion_animation_widget.dart';
import '../widgets/companion_card_widget.dart';
import '../widgets/companion_stats_widget.dart';
import 'companion_detail_page.dart';
import 'companion_shop_page.dart';

class CompanionMainPage extends StatelessWidget {
  const CompanionMainPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CompanionCubit>()..loadCompanions(),
      child: const _CompanionMainView(),
    );
  }
}

class _CompanionMainView extends StatelessWidget {
  const _CompanionMainView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: BlocBuilder<CompanionCubit, CompanionState>(
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
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando tus compañeros...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops, algo salió mal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
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
    return CustomScrollView(
      slivers: [
        // App Bar personalizado
        _buildSliverAppBar(context),
        
        // Estadísticas del usuario
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu Compañero Activo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToShop(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Obtener más'),
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
  
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Compañeros',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.read<CompanionCubit>().refreshCompanions(),
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
        IconButton(
          onPressed: () => _navigateToShop(context),
          icon: const Icon(Icons.store, color: Colors.white),
        ),
      ],
    );
  }
  
  Widget _buildActiveCompanionCard(BuildContext context, companion) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, companion),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
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
        child: Row(
          children: [
            // Imagen del compañero activo
            CompanionAnimationWidget(
              companion: companion,
              size: 80,
            ),
            
            const SizedBox(width: 20),
            
            // Info del compañero activo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companion.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${companion.typeDescription} ${companion.stageDisplayName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nivel ${companion.level} • ${companion.experience}/${companion.experienceNeededForNextStage} EXP',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón para ir al detalle
            Container(
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
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
            Icon(
              Icons.pets,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes compañeros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Visita la tienda para conseguir tu primer compañero!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToShop(context),
              icon: const Icon(Icons.store),
              label: const Text('Ir a la Tienda'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToDetail(BuildContext context, companion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompanionDetailPage(companion: companion),
      ),
    ).then((_) {
      // Refrescar cuando regrese del detalle
      context.read<CompanionCubit>().refreshCompanions();
    });
  }
  
  void _navigateToShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CompanionShopPage(),
      ),
    ).then((_) {
      // Refrescar cuando regrese de la tienda
      context.read<CompanionCubit>().refreshCompanions();
    });
  }
}