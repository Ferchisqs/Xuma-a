// lib/features/trivia/presentation/widgets/animated_trivia_completion_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/trivia_result_entity.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class AnimatedTriviaCompletionDialog extends StatefulWidget {
  final TriviaResultEntity result;
  final VoidCallback onContinue;

  const AnimatedTriviaCompletionDialog({
    Key? key,
    required this.result,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<AnimatedTriviaCompletionDialog> createState() => _AnimatedTriviaCompletionDialogState();
}

class _AnimatedTriviaCompletionDialogState extends State<AnimatedTriviaCompletionDialog>
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
      end: widget.result.earnedPoints,
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
                  maxWidth: MediaQuery.of(context).size.width * 0.9, // 🔧 AGREGADO MAXWIDTH
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
                          '¡EXCELENTE!',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Puntos animados
                      _buildAnimatedPoints(),
                      
                      const SizedBox(height: 16),
                      
                      // Mensaje con animación
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildSuccessMessage(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Estadísticas animadas
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildAnimatedStats(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botones con animación - 🔧 NAVEGACIÓN ARREGLADA
                      SlideTransition(
                        position: _slideAnimation,
                        child: _buildActionButtons(context),
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
                Icons.star,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

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
                width: double.infinity, 
                constraints: const BoxConstraints(
                  maxWidth: 280, 
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
                  mainAxisAlignment: MainAxisAlignment.center, 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Icon(
                            Icons.eco,
                            color: AppColors.primary,
                            size: 24, // 🔧 TAMAÑO REDUCIDO
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible( // 🔧 FLEXIBLE EN LUGAR DE EXPANDED
                      child: Text(
                        '+ ${_pointsCountAnimation.value} pts',
                        style: AppTextStyles.h4.copyWith( 
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, 
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
          Text(
            '¡Felicidades por completar esta trivia!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(value * 10 - 5, 0),
                    child: const Text('🐾'),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Usa tus puntos para comprar nuevos compañeros o alimentar a Xico',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAnimatedStatItem(
          'Respuestas\nCorrectas',
          '${widget.result.correctCount}/${widget.result.totalQuestions}',
          Icons.check_circle_outline,
          0,
        ),
        _buildAnimatedStatItem(
          'Precisión',
          '${widget.result.accuracyPercentage.round()}%',
          Icons.percent,
          200,
        ),
        _buildAnimatedStatItem(
          'Tiempo',
          _formatTime(widget.result.totalTime),
          Icons.timer_outlined,
          400,
        ),
      ],
    );
  }

  Widget _buildAnimatedStatItem(String label, String value, IconData icon, int delay) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 1.0, end: 1.05),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    context.read<NavigationCubit>().goToCompanion();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: const Icon(
                              Icons.pets, 
                              color: Colors.white,
                              size: 18,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ver Compañeros',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(); 
              widget.onContinue(); 
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continuar Trivias',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
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

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}