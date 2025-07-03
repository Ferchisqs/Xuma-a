import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 
        ? 'Buenos días' 
        : hour < 18 
            ? 'Buenas tardes' 
            : 'Buenas noches';

    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: Column(
        children: [
          Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título "Bienvenido"
            Text(
              'Bienvenido',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                  ),
                ),
                
                
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Presentación de Xico - Diseño exacto del PDF
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Texto "¡Hola! Me presento soy Xico"
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '¡Hola! Me presento soy ',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: 'Xico',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Imagen de Xico con bandera - Placeholder por ahora
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo de fondo verde con hojas
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Hojas decorativas
                          Positioned(
                            left: 20,
                            top: 30,
                            child: Transform.rotate(
                              angle: -0.3,
                              child: Icon(
                                Icons.eco,
                                color: AppColors.nature.withOpacity(0.7),
                                size: 24,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 20,
                            top: 40,
                            child: Transform.rotate(
                              angle: 0.5,
                              child: Icon(
                                Icons.eco,
                                color: AppColors.nature.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 30,
                            bottom: 50,
                            child: Icon(
                              Icons.local_florist,
                              color: AppColors.accent.withOpacity(0.7),
                              size: 16,
                            ),
                          ),
                          
                          // Xico - Placeholder del jaguar
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Placeholder para imagen de Xico
                                  Icon(
                                    Icons.pets,
                                    size: 50,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Xico',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bandera de México en la esquina superior derecha
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 30,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(color: Colors.green.shade600),
                              ),
                              Expanded(
                                child: Container(color: Colors.white),
                              ),
                              Expanded(
                                child: Container(color: Colors.red.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Descripción de Xico - Texto exacto del PDF
                Text(
                  'Soy un protector de la naturaleza, que busca compartir sus conocimientos para que todas las personas puedan aprender la importancia del cuidado del medio ambiente.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'En esta App tendrás disponible múltiples contenidos para aprender sobre el cambio climático y su impacto, así como retos, proyectos e información educativa sobre cómo mitigar nuestro impacto.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Ícono de reciclaje en la parte inferior
                Icon(
                  Icons.recycling,
                  color: AppColors.nature,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}