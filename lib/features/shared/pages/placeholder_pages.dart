import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../navigation/presentation/widgets/custom_app_bar.dart';

// 🔄 NUEVAS PÁGINAS
class CompanionPage extends StatelessWidget {
  const CompanionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Scaffold.of(context).hasDrawer ? null : Drawer(), // 🔄 Asegurar drawer
      appBar: const CustomAppBar(
        title: 'Compañero',
        showDrawerButton: true, // 🔄 Mostrar botón hamburguesa
      ),
      body: const _PlaceholderContent(
        icon: Icons.pets_rounded,
        title: 'Tu Compañero Xico',
        subtitle: 'Próximamente: Interactúa con tu guía ecológico',
        color: AppColors.accent,
      ),
    );
  }
}

class TriviaPage extends StatelessWidget {
  const TriviaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Scaffold.of(context).hasDrawer ? null : Drawer(), // 🔄 Asegurar drawer
      appBar: const CustomAppBar(
        title: 'Trivias',
        showDrawerButton: true, // 🔄 Mostrar botón hamburguesa
      ),
      body: const _PlaceholderContent(
        icon: Icons.quiz_rounded,
        title: 'Trivias Ecológicas',
        subtitle: 'Próximamente: Pon a prueba tus conocimientos',
        color: AppColors.warning,
      ),
    );
  }
}

// PÁGINAS EXISTENTES ACTUALIZADAS
class ChallengesPage extends StatelessWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Scaffold.of(context).hasDrawer ? null : Drawer(), // 🔄 Asegurar drawer
      appBar: const CustomAppBar(
        title: 'Desafíos',
        showDrawerButton: true, // 🔄 Mostrar botón hamburguesa
      ),
      body: const _PlaceholderContent(
        icon: Icons.emoji_events_rounded,
        title: 'Desafíos Ecológicos',
        subtitle: 'Próximamente: Retos y competencias',
        color: AppColors.primaryLight,
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Scaffold.of(context).hasDrawer ? null : Drawer(), // 🔄 Asegurar drawer
      appBar: const CustomAppBar(
        title: 'Contacto',
        showDrawerButton: true, // 🔄 Mostrar botón hamburguesa
      ),
      body: const _PlaceholderContent(
        icon: Icons.support_agent_rounded,
        title: 'Contacto y Soporte',
        subtitle: 'Próximamente: Ayuda y contacto',
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PlaceholderContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                size: 50,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}