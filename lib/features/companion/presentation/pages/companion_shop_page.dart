// lib/features/companion/presentation/pages/companion_shop_page.dart - API CONECTADA
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
    debugPrint('🏪 [SHOP_PAGE] === INICIALIZANDO TIENDA CON API ===');

    return BlocProvider(
      create: (context) {
        debugPrint('🚀 [SHOP_PAGE] Creando cubit conectado a API');
        final cubit = getIt<CompanionShopCubit>();

        // 🔥 CARGAR TIENDA DESDE TU API
        cubit.loadShop();

        return cubit;
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
    _tabController = TabController(length: 5, vsync: this);
    debugPrint('🏪 [SHOP_VIEW] Vista inicializada');
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
          debugPrint('🏪 [SHOP_VIEW] Estado cambió: ${state.runtimeType}');

          if (state is CompanionShopError) {
            debugPrint('❌ [SHOP_VIEW] Error: ${state.message}');
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
                action: SnackBarAction(
                  label: 'REINTENTAR',
                  textColor: Colors.white,
                  onPressed: () {
                    debugPrint('🔄 [SHOP_VIEW] Reintentando carga...');
                    context.read<CompanionShopCubit>().loadShop();
                  },
                ),
              ),
            );
          } else if (state is CompanionShopPurchaseSuccess) {
            debugPrint('🎉 [SHOP_VIEW] Adopción exitosa: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.pets, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          debugPrint('🏪 [SHOP_VIEW] Construyendo UI: ${state.runtimeType}');

          if (state is CompanionShopLoading) {
            return _buildLoadingView();
          } else if (state is CompanionShopError) {
            return _buildErrorView(state.message, context);
          } else if (state is CompanionShopLoaded) {
            debugPrint('✅ [SHOP_VIEW] === MOSTRANDO TIENDA CARGADA ===');
            debugPrint(
                '💰 [SHOP_VIEW] Puntos usuario: ${state.userStats.availablePoints}');
            debugPrint(
                '🛍️ [SHOP_VIEW] Mascotas en tienda: ${state.purchasableCompanions.length}');
            return _buildLoadedView(state, context);
          } else if (state is CompanionShopPurchasing) {
            return _buildPurchasingView(state.companion);
          }

          return _buildLoadingView();
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Tienda de Mascotas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            SizedBox(height: 20),
            Text(
              'Cargando tienda...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Obteniendo mascotas disponibles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Tienda de Mascotas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
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
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '❌ Error de Conexión',
                style: TextStyle(
                  fontSize: 22,
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        debugPrint('🔄 Reintentando conexión API...');
                        context.read<CompanionShopCubit>().loadShop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasingView(CompanionEntity companion) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Tienda de Mascotas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 24),
            Text(
              '🐾 Adoptando a ${companion.displayName}...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectando con la API, por favor espera',
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

  Widget _buildLoadedView(CompanionShopLoaded state, BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar con información de la API
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  '🏪 Tienda',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Puntos del usuario desde la API
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    color: Colors.yellow[300], size: 20),
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

                          const SizedBox(height: 4),

                         
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

           
            // Tab Bar para categorías
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
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
          controller: _tabController,
          children: [
            // Todos los compañeros
            _buildCompanionGrid(context, state.purchasableCompanions, state),

            // Por tipo específico
            _buildCompanionGrid(
              context,
              state.purchasableCompanions
                  .where((c) => c.type == CompanionType.dexter)
                  .toList(),
              state,
            ),
            _buildCompanionGrid(
              context,
              state.purchasableCompanions
                  .where((c) => c.type == CompanionType.elly)
                  .toList(),
              state,
            ),
            _buildCompanionGrid(
              context,
              state.purchasableCompanions
                  .where((c) => c.type == CompanionType.paxolotl)
                  .toList(),
              state,
            ),
            _buildCompanionGrid(
              context,
              state.purchasableCompanions
                  .where((c) => c.type == CompanionType.yami)
                  .toList(),
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
    debugPrint(
        '🏗️ [SHOP] Construyendo grid con ${companions.length} compañeros');

    if (companions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.pets, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay mascotas en esta categoría',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta en otra pestaña o recarga la tienda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('🔄 Recargando tienda...');
                context.read<CompanionShopCubit>().refreshShop();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          

          // Grid de mascotas
          Expanded(
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
                debugPrint(
                    '🏪 [SHOP] Renderizando: ${companion.displayName} (${companion.purchasePrice}★)');

                return BlocBuilder<CompanionShopCubit, CompanionShopState>(
                  builder: (builderContext, builderState) {
                    return CompanionShopItemWidget(
                      companion: companion,
                      userPoints: state.userStats.availablePoints,
                      onPurchase: () {
                        debugPrint('🎯 [SHOP] === INICIANDO ADOPCIÓN ===');
                        debugPrint(
                            '🐾 [SHOP] Mascota: ${companion.displayName}');
                        debugPrint(
                            '💰 [SHOP] Precio: ${companion.purchasePrice}★');
                        debugPrint(
                            '👤 [SHOP] Puntos usuario: ${state.userStats.availablePoints}');

                        _showPurchaseDialog(builderContext, companion, state);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(
    BuildContext context,
    CompanionEntity companion,
    CompanionShopLoaded state,
  ) {
    debugPrint('🛒 [SHOP] === MOSTRANDO DIÁLOGO DE ADOPCIÓN ===');
    debugPrint('🐾 [SHOP] Mascota: ${companion.displayName}');
    debugPrint('💰 [SHOP] Precio: ${companion.purchasePrice}★');
    debugPrint(
        '👤 [SHOP] Puntos disponibles: ${state.userStats.availablePoints}');

    showDialog(
      context: context,
      builder: (dialogContext) => CompanionPurchaseDialog(
        companion: companion,
        userPoints: state.userStats.availablePoints,
        onConfirm: () {
          debugPrint('✅ [SHOP] === ADOPCIÓN CONFIRMADA ===');
          debugPrint('🚀 [SHOP] Enviando adopción a API...');

          Navigator.of(dialogContext).pop();

          // 🚀 LLAMADA A LA API DE ADOPCIÓN
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
