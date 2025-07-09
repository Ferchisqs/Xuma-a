// 🔧 ARREGLO DEL ERROR DEL PROVIDER
// lib/features/companion/presentation/pages/companion_shop_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/companion_entity.dart';
import '../cubit/companion_shop_cubit.dart';
import '../widgets/companion_shop_item_widget.dart';
import '../widgets/companion_purchase_dialog.dart';

class CompanionShopPage extends StatelessWidget {
  const CompanionShopPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    debugPrint('🏪 [SHOP_PAGE] Creando CompanionShopPage');
    
    return BlocProvider(
      create: (context) {
        debugPrint('🏪 [SHOP_PAGE] Creando CompanionShopCubit');
        return getIt<CompanionShopCubit>()..loadShop();
      },
      child: const _CompanionShopView(),
    );
  }
}

class _CompanionShopView extends StatefulWidget {
  const _CompanionShopView({Key? key}) : super(key: key);
  
  @override
  State<_CompanionShopView> createState() => _CompanionShopViewState();
}

class _CompanionShopViewState extends State<_CompanionShopView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Todos + 4 tipos
    debugPrint('🏪 [SHOP_VIEW] TabController inicializado');
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BlocConsumer<CompanionShopCubit, CompanionShopState>(
        listener: (context, state) {
          debugPrint('🏪 [SHOP_VIEW] Estado cambió a: ${state.runtimeType}');
          
          if (state is CompanionShopError) {
            debugPrint('❌ [SHOP_VIEW] Error: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CompanionShopPurchaseSuccess) {
            debugPrint('✅ [SHOP_VIEW] Compra exitosa: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          debugPrint('🏪 [SHOP_VIEW] Construyendo UI para estado: ${state.runtimeType}');
          
          if (state is CompanionShopLoading) {
            return const _LoadingView();
          } else if (state is CompanionShopError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                debugPrint('🔄 [SHOP_VIEW] Retry presionado');
                context.read<CompanionShopCubit>().loadShop();
              },
            );
          } else if (state is CompanionShopLoaded) {
            debugPrint('✅ [SHOP_VIEW] Mostrando tienda cargada');
            return _LoadedView(
              state: state,
              tabController: _tabController,
            );
          } else if (state is CompanionShopPurchasing) {
            debugPrint('⏳ [SHOP_VIEW] Mostrando estado de compra');
            return _PurchasingView(companion: state.companion);
          }
          
          return const _LoadingView();
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 [SHOP] Mostrando loading view');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Compañeros'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Cargando tienda...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
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
    debugPrint('❌ [SHOP] Mostrando error view: $message');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Compañeros'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
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
                'Error al cargar la tienda',
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
      ),
    );
  }
}

class _PurchasingView extends StatelessWidget {
  final CompanionEntity companion;
  
  const _PurchasingView({Key? key, required this.companion}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    debugPrint('⏳ [SHOP] Mostrando purchasing view para: ${companion.displayName}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Compañeros'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Comprando a ${companion.displayName}...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor espera un momento',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final CompanionShopLoaded state;
  final TabController tabController;
  
  const _LoadedView({
    Key? key,
    required this.state,
    required this.tabController,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    debugPrint('✅ [SHOP] Mostrando loaded view');
    debugPrint('🛍️ [SHOP] Compañeros disponibles: ${state.purchasableCompanions.length}');
    debugPrint('💰 [SHOP] Puntos usuario: ${state.userStats.availablePoints}');
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar con puntos disponibles
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Tienda de Compañeros',
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
                        Colors.deepPurple,
                        Colors.deepPurple.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.yellow[300], size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${state.userStats.availablePoints}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Tab Bar
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: tabController,
                  isScrollable: true,
                  indicatorColor: Colors.deepPurple,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Todos'),
                    Tab(text: 'Dexter'),
                    Tab(text: 'Elly'),
                    Tab(text: 'Paxolotl'),
                    Tab(text: 'Yami'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: tabController,
          children: [
            // Todos los compañeros
            _buildCompanionGrid(context, state.purchasableCompanions, state),
            
            // Por tipo
            _buildCompanionGrid(
              context,
              state.purchasableCompanions.where((c) => c.type == CompanionType.dexter).toList(),
              state,
            ),
            _buildCompanionGrid(
              context,
              state.purchasableCompanions.where((c) => c.type == CompanionType.elly).toList(),
              state,
            ),
            _buildCompanionGrid(
              context,
              state.purchasableCompanions.where((c) => c.type == CompanionType.paxolotl).toList(),
              state,
            ),
            _buildCompanionGrid(
              context,
              state.purchasableCompanions.where((c) => c.type == CompanionType.yami).toList(),
              state,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompanionGrid(
    BuildContext context,
    List<CompanionEntity> companions,
    CompanionShopLoaded state,
  ) {
    debugPrint('🏗️ [SHOP] Construyendo grid con ${companions.length} compañeros');
    
    if (companions.isEmpty) {
      debugPrint('📦 [SHOP] No hay compañeros en esta categoría');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay compañeros disponibles en esta categoría',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: companions.length,
        itemBuilder: (context, index) {
          final companion = companions[index];
          debugPrint('🏪 [SHOP] Creando item $index: ${companion.displayName}');
          
          return BlocBuilder<CompanionShopCubit, CompanionShopState>(
            builder: (builderContext, builderState) {
              // 🔧 USAR EL CONTEXT DEL BUILDER QUE TIENE ACCESO AL CUBIT
              return CompanionShopItemWidget(
                companion: companion,
                userPoints: state.userStats.availablePoints,
                onPurchase: () {
                  debugPrint('🎯 [SHOP] onPurchase llamado para: ${companion.displayName}');
                  _showPurchaseDialog(builderContext, companion, state);
                },
              );
            },
          );
        },
      ),
    );
  }
  
  void _showPurchaseDialog(
    BuildContext context,
    CompanionEntity companion,
    CompanionShopLoaded state,
  ) {
    debugPrint('🛒 [SHOP] Mostrando diálogo de compra para: ${companion.displayName}');
    debugPrint('💰 [SHOP] Puntos disponibles: ${state.userStats.availablePoints}');
    debugPrint('🏷️ [SHOP] Precio del compañero: ${companion.purchasePrice}');
    
    showDialog(
      context: context,
      builder: (dialogContext) => CompanionPurchaseDialog(
        companion: companion,
        userPoints: state.userStats.availablePoints,
        onConfirm: () {
          debugPrint('✅ [SHOP] Usuario confirmó compra desde diálogo: ${companion.displayName}');
          Navigator.of(dialogContext).pop();
          debugPrint('🚀 [SHOP] Enviando compra al cubit...');
          
          // 🔧 USAR EL CONTEXT CORRECTO PARA ACCEDER AL CUBIT
          context.read<CompanionShopCubit>().purchaseCompanion(companion);
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  
  _SliverTabBarDelegate(this._tabBar);
  
  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }
  
  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}