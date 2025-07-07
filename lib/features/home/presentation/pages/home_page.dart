import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🔄 IMPORT BLOC
import 'package:xuma_a/core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../di/injection.dart'; // 🔄 IMPORT GETIT
import '../widgets/welcome_header.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/eco_stats_widget.dart';
import '../widgets/quick_actions_grid.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart'; // 🔄 IMPORT CUBIT

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // 🔄 ASEGURAR QUE TENGA ACCESO AL NAVIGATION CUBIT
      value: context.read<NavigationCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        // 🔄 DRAWER DIRECTO - no condicional
        drawer: const SideNavBar(),
        appBar: const CustomAppBar(
          title: 'XUMA\'A',
          showDrawerButton: true, // 🔄 Mostrar drawer
          showEcoTip: true,       // 🔄 Mostrar consejo ecológico
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // Simular refresh
            await Future.delayed(const Duration(seconds: 1));
          },
          backgroundColor: AppColors.surface,
          color: AppColors.primary,
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Welcome Header con Xico (diseño exacto del PDF)
              SliverToBoxAdapter(
                child: WelcomeHeader(),
              ),
              
              // Sección de Consejo del día (nueva)
              SliverToBoxAdapter(
                child: DailyTipSection(),
              ),
              
              // User Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EcoStatsWidget(),
                ),
              ),
              
              // Quick Actions Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: QuickActionsGrid(),
                ),
              ),
              
              // Bottom spacing
              SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}