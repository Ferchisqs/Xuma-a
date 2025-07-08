import 'package:flutter/material.dart';
import 'dart:math';
import '../../domain/entities/companion_entity.dart';

class CompanionEvolutionDialog extends StatefulWidget {
  final CompanionEntity companion;
  final VoidCallback onContinue;
  
  const CompanionEvolutionDialog({
    Key? key,
    required this.companion,
    required this.onContinue,
  }) : super(key: key);
  
  @override
  State<CompanionEvolutionDialog> createState() => _CompanionEvolutionDialogState();
}

class _CompanionEvolutionDialogState extends State<CompanionEvolutionDialog>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _showEvolved = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEvolutionAnimation();
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
    
    // Animación de escala (efecto de transformación)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Animación de desvanecimiento
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }
  
  void _startEvolutionAnimation() async {
    // Iniciar efectos de evolución
    _sparkleController.repeat();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Escalar y desvanecer la imagen anterior
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    // Mostrar la nueva forma
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showEvolved = true);
    
    // Resetear animaciones para la nueva forma
    _fadeController.reverse();
    _scaleController.reverse();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    _sparkleController.stop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getCompanionColor().withOpacity(0.9),
              _getCompanionColor(),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título con efectos
            _buildTitle(),
            
            const SizedBox(height: 20),
            
            // Imagen del compañero con efectos de evolución
            _buildEvolutionImage(),
            
            const SizedBox(height: 20),
            
            // Información del compañero evolucionado
            _buildEvolutionInfo(),
            
            const SizedBox(height: 24),
            
            // Botón continuar
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTitle() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.yellow[300],
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              '¡EVOLUCIÓN!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.auto_awesome,
              color: Colors.yellow[300],
              size: 28,
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '${widget.companion.displayName} ha evolucionado',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEvolutionImage() {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efectos de brillos
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Stack(
                children: List.generate(8, (index) {
                  final angle = (index * pi * 2) / 8;
                  final radius = 80 + (sin(_sparkleAnimation.value * pi * 2) * 20);
                  return Positioned(
                    left: 100 + cos(angle + _sparkleAnimation.value * pi * 2) * radius,
                    top: 100 + sin(angle + _sparkleAnimation.value * pi * 2) * radius,
                    child: Transform.scale(
                      scale: 0.5 + (sin(_sparkleAnimation.value * pi * 4 + index) * 0.5),
                      child: Icon(
                        Icons.star,
                        color: Colors.yellow[300]!.withOpacity(0.8),
                        size: 16,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          
          // Imagen del compañero
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _showEvolved ? 1.0 : _fadeAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.companion.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white.withOpacity(0.2),
                            child: Icon(
                              Icons.pets,
                              size: 75,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvolutionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Nombre y etapa
          Text(
            '${widget.companion.displayName} ${widget.companion.stageDisplayName}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            widget.companion.typeDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Nuevas habilidades desbloqueadas
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
                      Icons.new_releases,
                      color: Colors.yellow[300],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Nuevas habilidades desbloqueadas:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 6,
                  children: _getNewAbilities().map((ability) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ability,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Estadísticas mejoradas
          Text(
            '¡${widget.companion.displayName} ahora es más fuerte y tiene nuevas animaciones!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _getCompanionColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Continuar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 20,
              color: _getCompanionColor(),
            ),
          ],
        ),
      ),
    );
  }
  
  List<String> _getNewAbilities() {
    switch (widget.companion.stage) {
      case CompanionStage.young:
        return ['Más resistente', 'Nuevas expresiones', 'Mayor experiencia'];
      case CompanionStage.adult:
        return ['Máximo poder', 'Todas las animaciones', 'Súper resistente'];
      default:
        return ['Animaciones básicas'];
    }
  }
  
  Color _getCompanionColor() {
    switch (widget.companion.type) {
      case CompanionType.dexter:
        return Colors.brown;
      case CompanionType.elly:
        return Colors.green;
      case CompanionType.paxolotl:
        return Colors.cyan;
      case CompanionType.yami:
        return Colors.purple;
    }
  }
  
  @override
  void dispose() {
    _sparkleController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}