import 'package:flutter/material.dart';
import 'package:xuma_a/core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/welcome_header.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/eco_stats_widget.dart';
import '../widgets/quick_actions_grid.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SideNavBar(),
      appBar: CustomAppBar(
        title: 'XUMA\'A',
        showDrawerButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
            ),
            onPressed: () {
              _showAccessibilityMenu(context);
            },
          ),
        ],
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
    );
  }

  void _showAccessibilityMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Menú de Accesibilidad',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Próximamente: Opciones de accesibilidad',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}