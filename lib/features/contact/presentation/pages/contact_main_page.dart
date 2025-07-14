import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart'; // 🆕 AGREGADO
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class ContactMainPage extends StatelessWidget {
  const ContactMainPage({Key? key}) : super(key: key);

  // 🆕 EMAIL DE CONTACTO AGREGADO
  static const String contactEmail = 'nova.code.oficial.1@gmail.com';

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<NavigationCubit>(),
      child: const _ContactMainContent(),
    );
  }
}

class _ContactMainContent extends StatelessWidget {
  const _ContactMainContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SideNavBar(),
      appBar: const CustomAppBar(
        title: 'Contacto y Soporte',
        showDrawerButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.earthGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Necesitas ayuda?',
                          style: AppTextStyles.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Estamos aquí para ayudarte',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Opciones de contacto
            _buildContactOption(
              icon: Icons.email_rounded,
              title: 'Correo Electrónico',
              subtitle: 'soporte@xumaa.com',
              onTap: () {
                // 🆕 MODIFICADO: Ahora redirige al email
                _sendEmail(context);
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildContactOption(
              icon: Icons.phone_rounded,
              title: 'Teléfono',
              subtitle: '‪+52 961 123 4567‬',
              onTap: () {
                _showSnackBar(context, 'Función de llamada próximamente');
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildContactOption(
              icon: Icons.chat_rounded,
              title: 'Chat en Línea',
              subtitle: 'Respuesta inmediata',
              onTap: () {
                _showSnackBar(context, 'Función de chat próximamente');
              },
            ),
            
            const SizedBox(height: 32),
            
            // FAQ Section
            Text(
              'Preguntas Frecuentes',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildFAQItem(
              '¿Cómo puedo ganar más puntos?',
              'Completa lecciones, desafíos y cuida bien a tu compañero Xico.',
            ),
            
            _buildFAQItem(
              '¿Cómo evoluciono a mi compañero?',
              'Dale amor y comida regularmente. Cuando gane suficiente experiencia, podrá evolucionar.',
            ),
            
            _buildFAQItem(
              '¿Qué pasa si pierdo mi progreso?',
              'Tu progreso se guarda automáticamente. Si tienes problemas, contáctanos.',
            ),
            
            _buildFAQItem(
              '¿Puedo tener más de un compañero?',
              'Sí, puedes comprar y coleccionar diferentes compañeros en la tienda usando tus puntos.',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFAQItem(String question, String answer) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 FUNCIÓN AGREGADA PARA ENVIAR EMAIL
  Future<void> _sendEmail(BuildContext context) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: ContactMainPage.contactEmail,
        queryParameters: {
          'subject': 'Consulta sobre XUMA\'A',
          'body': 'Hola equipo de XUMA\'A,\n\nTengo una consulta sobre:\n\n[Describe tu consulta aquí]\n\nGracias por su tiempo.\n\nSaludos cordiales.',
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback si no puede abrir el email
        _showSnackBar(context, 'No se pudo abrir el cliente de email. Email: ${ContactMainPage.contactEmail}');
      }
    } catch (e) {
      _showSnackBar(context, 'Error al abrir email. Contacto: ${ContactMainPage.contactEmail}');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}