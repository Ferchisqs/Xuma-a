import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/welcome_header.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/eco_stats_widget.dart';
import '../widgets/quick_actions_grid.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<NavigationCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const SideNavBar(),
        appBar: const CustomAppBar(
          title: 'XUMA\'A',
          showDrawerButton: true,
          showEcoTip: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          backgroundColor: AppColors.surface,
          color: AppColors.primary,
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Welcome Header con Xico
              SliverToBoxAdapter(
                child: WelcomeHeader(),
              ),
              
              // Sección de Consejo del día
              SliverToBoxAdapter(
                child: DailyTipSection(),
              ),
              
              // User Stats - 🔧 CORREGIDO CON PADDING ADECUADO
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0), // 🔧 REDUCIDO spacing superior
                  child: EcoStatsWidget(),
                ),
              ),
              
              // Quick Actions Grid - 🔧 CORREGIDO CON ESPACIADO
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16), // 🔧 REDUCIDO spacing superior de 24 a 16
                  child: QuickActionsGrid(),
                ),
              ),
              
              // Bottom spacing
              SliverToBoxAdapter(
                child: SizedBox(height: 100), // 🔧 Más espacio para evitar solapamiento
              ),
            ],
          ),
        ),
      ),
    );
  }
}