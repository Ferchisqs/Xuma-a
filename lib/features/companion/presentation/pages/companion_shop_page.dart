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
    return BlocProvider(
      create: (context) => getIt<CompanionShopCubit>()..loadShop(),
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
          if (state is CompanionShopError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CompanionShopPurchaseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CompanionShopLoading) {
            return const _LoadingView();
          } else if (state is CompanionShopError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<CompanionShopCubit>().loadShop(),
            );
          } else if (state is CompanionShopLoaded) {
            return _LoadedView(
              state: state,
              tabController: _tabController,
            );
          } else if (state is CompanionShopPurchasing) {
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
    if (companions.isEmpty) {
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
          return CompanionShopItemWidget(
            companion: companion,
            userPoints: state.userStats.availablePoints,
            onPurchase: () => _showPurchaseDialog(context, companion, state),
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
    showDialog(
      context: context,
      builder: (context) => CompanionPurchaseDialog(
        companion: companion,
        userPoints: state.userStats.availablePoints,
        onConfirm: () {
          Navigator.of(context).pop();
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