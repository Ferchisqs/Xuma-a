// lib/features/auth/presentation/widgets/email_verification_page.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/user_entity.dart';

class EmailVerificationPage extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onResendEmail;
  final VoidCallback onCheckStatus;

  const EmailVerificationPage({
    Key? key,
    required this.user,
    required this.onResendEmail,
    required this.onCheckStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView( // Solución 1: Agregar scroll
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 48, // Altura mínima menos padding
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Espaciador flexible al inicio
                const Spacer(flex: 1),
                
                // Icono principal
                Container(
                  width: 100, // Reducido de 120 a 100
                  height: 100, // Reducido de 120 a 100
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                    size: 50, // Reducido de 60 a 50
                  ),
                ),
                
                const SizedBox(height: 24), // Reducido de 32 a 24
                
                // Título
                Text(
                  '📧 Verifica tu Email',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12), // Reducido de 16 a 12
                
                // Saludo personalizado
                Text(
                  '¡Hola ${user.firstName}! 👋',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje principal
                Container(
                  padding: const EdgeInsets.all(16), // Reducido de 20 a 16
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 28, // Reducido de 32 a 28
                      ),
                      const SizedBox(height: 8), // Reducido de 12 a 8
                      Text(
                        'Hemos enviado un email de verificación a:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6), // Reducido de 8 a 6
                      Text(
                        user.email,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8), // Reducido de 12 a 8
                      Text(
                        'Por favor revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24), // Reducido de 32 a 24
                
                // Botones de acción
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCheckStatus,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Ya Verifiqué mi Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14), // Reducido de 16 a 14
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10), // Reducido de 12 a 10
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onResendEmail,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Reenviar Email'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14), // Reducido de 16 a 14
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20), // Reducido de 24 a 20
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(14), // Reducido de 16 a 14
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.warning,
                        size: 22, // Reducido de 24 a 22
                      ),
                      const SizedBox(height: 6), // Reducido de 8 a 6
                      Text(
                        'Consejos:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Revisa tu carpeta de spam\n• El email puede tardar unos minutos\n• Asegúrate de hacer clic en el enlace completo',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                
                // Espaciador flexible al final
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para cuando el email ya fue enviado - También optimizado
class EmailVerificationSentPage extends StatelessWidget {
  final UserEntity user;
  final String email;
  final VoidCallback onResendEmail;
  final VoidCallback onCheckStatus;

  const EmailVerificationSentPage({
    Key? key,
    required this.user,
    required this.email,
    required this.onResendEmail,
    required this.onCheckStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 48,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                
                // Icono de éxito
                Container(
                  width: 100, // Reducido
                  height: 100, // Reducido
                  decoration: BoxDecoration(
                    gradient: AppColors.earthGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.white,
                    size: 50, // Reducido
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Título
                Text(
                  '✅ Email Enviado',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de confirmación
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email de verificación enviado exitosamente a:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botones de acción
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCheckStatus,
                        icon: const Icon(Icons.verified_rounded),
                        label: const Text('Verificar Estado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    TextButton.icon(
                      onPressed: onResendEmail,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Enviar Nuevamente'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Información de espera
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppColors.info,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Verificaremos automáticamente el estado de tu email cada 30 segundos.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}