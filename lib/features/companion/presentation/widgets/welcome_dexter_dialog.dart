// lib/features/companion/presentation/widgets/welcome_dexter_dialog.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../../domain/entities/companion_entity.dart';
import '../widgets/companion_animation_widget.dart';

class WelcomeDexterDialog extends StatefulWidget {
  final CompanionEntity dexterBaby;
  final VoidCallback onContinue;
  
  const WelcomeDexterDialog({
    Key? key,
    required this.dexterBaby,
    required this.onContinue,
  }) : super(key: key);
  
  @override
  State<WelcomeDexterDialog> createState() => _WelcomeDexterDialogState();
}

class _WelcomeDexterDialogState extends State<WelcomeDexterDialog>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _sparkleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startWelcomeAnimation();
  }
  
  void _setupAnimations() {
    // Animación de brillos/estrellas
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
    
    // Animación de deslizamiento
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    // Animación de escala
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );
  }
  
  void _startWelcomeAnimation() async {
    // Iniciar brillos
    _sparkleController.repeat();
    
    // Escalar hacia arriba
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    // Deslizar desde abajo
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // No permitir cerrar con back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green[400]!,
                    Colors.green[600]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Efectos de brillos
                  _buildSparkleEffects(),
                  
                  // Título de bienvenida
                  _buildWelcomeTitle(),
                  
                  const SizedBox(height: 20),
                  
                  // Imagen de Dexter baby
                  _buildDexterImage(),
                  
                  const SizedBox(height: 20),
                  
                  // Mensaje de bienvenida
                  _buildWelcomeMessage(),
                  
                  const SizedBox(height: 24),
                  
                  // Botón continuar
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSparkleEffects() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 50,
          child: Stack(
            children: List.generate(6, (index) {
              final angle = (index * pi * 2) / 6;
              final radius = 20 + (sin(_sparkleAnimation.value * pi * 2) * 10);
              return Positioned(
                left: 150 + cos(angle + _sparkleAnimation.value * pi * 2) * radius,
                top: 25 + sin(angle + _sparkleAnimation.value * pi * 2) * radius,
                child: Transform.scale(
                  scale: 0.3 + (sin(_sparkleAnimation.value * pi * 4 + index) * 0.4),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.yellow[300]!.withOpacity(0.9),
                    size: 16,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
  
  Widget _buildWelcomeTitle() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              color: Colors.yellow[300],
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              '¡BIENVENIDO!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.celebration,
              color: Colors.yellow[300],
              size: 32,
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Has recibido tu primer compañero',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDexterImage() {
    return Container(
      height: 180,
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CompanionAnimationWidget(
          companion: widget.dexterBaby,
          size: 160,
          isInteracting: false,
        ),
      ),
    );
  }
  
  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Nombre y información
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.dexterBaby.displayName} Bebé',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.dexterBaby.typeDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Mensaje especial
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.yellow[300],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Características especiales:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildFeatureChip('Gratuito'),
                    _buildFeatureChip('Fácil cuidado'),
                    _buildFeatureChip('Tu primer amigo'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '¡${widget.dexterBaby.displayName} será tu compañero en esta aventura ecológica!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          debugPrint('🎉 [WELCOME_DIALOG] Usuario continuó después de bienvenida');
          widget.onContinue();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
        ),
        icon: Icon(
          Icons.arrow_forward,
          size: 20,
          color: Colors.green[600],
        ),
        label: Text(
          '¡Conocer a ${widget.dexterBaby.displayName}!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _sparkleController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}