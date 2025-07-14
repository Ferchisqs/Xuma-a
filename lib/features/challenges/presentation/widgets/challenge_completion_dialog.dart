// lib/features/challenges/presentation/widgets/challenge_completion_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/challenge_entity.dart';

class ChallengeCompletionDialog extends StatefulWidget {
  final ChallengeEntity challenge;
  final int pointsEarned;
  final VoidCallback? onContinue;

  const ChallengeCompletionDialog({
    Key? key,
    required this.challenge,
    required this.pointsEarned,
    this.onContinue,
  }) : super(key: key);

  @override
  State<ChallengeCompletionDialog> createState() => _ChallengeCompletionDialogState();
}

class _ChallengeCompletionDialogState extends State<ChallengeCompletionDialog>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _starController;
  late AnimationController _pointsController;
  late AnimationController _confettiController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starRotationAnimation;
  late Animation<double> _starScaleAnimation;
  late Animation<int> _pointsCountAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador principal para la aparición del diálogo
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Controlador para la animación de la estrella
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Controlador para animación de puntos
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Controlador para efecto confetti
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Configurar animaciones
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeIn,
    ));

    _starRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.elasticOut,
    ));

    _starScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.bounceOut,
    ));

    _pointsCountAnimation = IntTween(
      begin: 0,
      end: widget.pointsEarned,
    ).animate(CurvedAnimation(
      parent: _pointsController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));

    // Iniciar animaciones en secuencia
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mainController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _starController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _pointsController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _confettiController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _starController.dispose();
    _pointsController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Confetti animado
                      _buildConfettiEffect(),
                      
                      // Estrella animada
                      _buildAnimatedStar(),
                      
                      const SizedBox(height: 16),
                      
                      // Título con animación
                      SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          '¡Desafío Completado!',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Puntos animados - ARREGLADO PARA NO DESBORDARSE
                      _buildAnimatedPoints(),
                      
                      const SizedBox(height: 16),
                      
                      // Mensaje con animación
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildSuccessMessage(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botón continuar
                      SlideTransition(
                        position: _slideAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continuar',
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfettiEffect() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: Stack(
            children: List.generate(12, (index) {
              final angle = (index * 30.0) * (3.14159 / 180);
              final radius = 40.0 * _confettiController.value;
              final x = radius * (index % 2 == 0 ? 1 : -1) * 0.5;
              final y = radius * (index % 3 == 0 ? 1 : -1) * 0.3;
              
              return Positioned(
                left: 150 + x,
                top: 30 + y,
                child: Transform.rotate(
                  angle: angle * _confettiController.value,
                  child: Opacity(
                    opacity: _confettiController.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getConfettiColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStar() {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, child) {
        return Transform.scale(
          scale: _starScaleAnimation.value,
          child: Transform.rotate(
            angle: _starRotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.warning,
                    AppColors.primary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔧 ARREGLADO: Puntos animados que no se desbordan
  Widget _buildAnimatedPoints() {
    return AnimatedBuilder(
      animation: _pointsController,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.8, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: double.infinity, // 🔧 ANCHO COMPLETO
                constraints: const BoxConstraints(
                  maxWidth: 280, // 🔧 MÁXIMO ANCHO PARA EVITAR DESBORDAMIENTO
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 🔧 PADDING REDUCIDO
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 🔧 CENTRADO
                  mainAxisSize: MainAxisSize.min, // 🔧 TAMAÑO MÍNIMO
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Icon(
                            Icons.stars,
                            color: AppColors.accent,
                            size: 24, // 🔧 TAMAÑO REDUCIDO
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible( // 🔧 FLEXIBLE EN LUGAR DE EXPANDED
                      child: Text(
                        '+ ${_pointsCountAnimation.value} puntos',
                        style: AppTextStyles.h4.copyWith( // 🔧 TEXTO MÁS PEQUEÑO
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, // 🔧 PREVENIR OVERFLOW
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.earthGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Xico dice:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '¡Excelente trabajo! Has contribuido al cuidado del medio ambiente. Cada acción cuenta para proteger nuestro planeta.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getConfettiColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }
}