import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../navigation/presentation/widgets/custom_app_bar.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Noticias'),
      body: const _PlaceholderContent(
        icon: Icons.article_rounded,
        title: 'Noticias Ambientales',
        subtitle: 'Próximamente: Últimas noticias sobre medio ambiente',
        color: AppColors.info,
      ),
    );
  }
}

class LearnPage extends StatelessWidget {
  const LearnPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Aprendamos'),
      body: const _PlaceholderContent(
        icon: Icons.school_rounded,
        title: 'Educación Ecológica',
        subtitle: 'Próximamente: Cursos y contenido educativo',
        color: AppColors.secondary,
      ),
    );
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Proyectos'),
      body: const _PlaceholderContent(
        icon: Icons.construction_rounded,
        title: 'Proyectos Verdes',
        subtitle: 'Próximamente: Iniciativas ambientales',
        color: AppColors.warning,
      ),
    );
  }
}

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Desafíos'),
      body: const _PlaceholderContent(
        icon: Icons.emoji_events_rounded,
        title: 'Desafíos Ecológicos',
        subtitle: 'Próximamente: Retos y competencias',
        color: AppColors.accent,
      ),
    );
  }
}

class CommunityPage extends StatelessWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Comunidad'),
      body: const _PlaceholderContent(
        icon: Icons.groups_rounded,
        title: 'Comunidad Eco',
        subtitle: 'Próximamente: Red social ambiental',
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
      appBar: const CustomAppBar(title: 'Contacto'),
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