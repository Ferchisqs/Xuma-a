import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../domain/entities/companion_entity.dart';

class CompanionAnimationWidget extends StatefulWidget {
  final CompanionEntity companion;
  final double size;
  final bool isInteracting; // true cuando se está alimentando o dando amor
  final String? currentAction; // 'feeding', 'loving', null
  
  const CompanionAnimationWidget({
    Key? key,
    required this.companion,
    this.size = 200,
    this.isInteracting = false,
    this.currentAction,
  }) : super(key: key);
  
  @override
  State<CompanionAnimationWidget> createState() => _CompanionAnimationWidgetState();
}

class _CompanionAnimationWidgetState extends State<CompanionAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _bounceController;
  late AnimationController _heartController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _heartAnimation;
  
  Timer? _blinkTimer;
  bool _isBlinking = false;
  bool _showHearts = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startBlinkTimer();
  }
  
  void _setupAnimations() {
    // Animación de parpadeo
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    
    // Animación de rebote (cuando está feliz o interactuando)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    // Animación de corazones
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );
  }
  
  void _startBlinkTimer() {
    _blinkTimer = Timer.periodic(
      Duration(milliseconds: Random().nextInt(3000) + 2000), // 2-5 segundos
      (timer) {
        if (mounted && !_isBlinking) {
          _blink();
        }
      },
    );
  }
  
  void _blink() async {
    setState(() => _isBlinking = true);
    await _blinkController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _blinkController.reverse();
    setState(() => _isBlinking = false);
  }
  
  @override
  void didUpdateWidget(CompanionAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reaccionar a interacciones
    if (widget.isInteracting && !oldWidget.isInteracting) {
      _handleInteraction();
    }
    
    // Reaccionar a cambios de humor
    if (widget.companion.currentMood != oldWidget.companion.currentMood) {
      _handleMoodChange();
    }
  }
  
  void _handleInteraction() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    if (widget.currentAction == 'loving') {
      _showHearts = true;
      _heartController.forward().then((_) {
        _heartController.reverse().then((_) {
          setState(() => _showHearts = false);
        });
      });
    }
  }
  
  void _handleMoodChange() {
    switch (widget.companion.currentMood) {
      case CompanionMood.happy:
      case CompanionMood.excited:
        _bounceController.forward().then((_) => _bounceController.reverse());
        break;
      case CompanionMood.sad:
        // Parpadeo más lento cuando está triste
        break;
      default:
        break;
    }
  }
  
  String get _currentImagePath {
    final basePath = 'assets/images/companions';
    final name = '${widget.companion.type.name}_${widget.companion.stage.name}';
    
    // Si está parpadeando, mostrar imagen con ojos cerrados
    if (_isBlinking) {
      return '$basePath/animations/${name}_closed.png';
    }
    
    // Imagen normal con ojos abiertos
    return '$basePath/${name}.png';
  }
  
  Color get _moodColor {
    switch (widget.companion.currentMood) {
      case CompanionMood.happy:
        return Colors.yellow;
      case CompanionMood.excited:
        return Colors.orange;
      case CompanionMood.sad:
        return Colors.blue;
      case CompanionMood.hungry:
        return Colors.red;
      case CompanionMood.sleepy:
        return Colors.purple;
      default:
        return Colors.green;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Aura de humor (sutil)
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: widget.size + 20,
          height: widget.size + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _moodColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        
        // Compañero principal con animaciones
        AnimatedBuilder(
          animation: Listenable.merge([_blinkAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_bounceAnimation.value * 0.1),
              child: Transform.translate(
                offset: Offset(0, -_bounceAnimation.value * 10),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      _currentImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.pets,
                            size: widget.size * 0.5,
                            color: Colors.grey[600],
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
        
        // Corazones flotantes (cuando recibe amor)
        if (_showHearts)
          AnimatedBuilder(
            animation: _heartAnimation,
            builder: (context, child) {
              return Positioned(
                top: 20 - (_heartAnimation.value * 30),
                child: Opacity(
                  opacity: 1.0 - _heartAnimation.value,
                  child: Row(
                    children: List.generate(3, (index) {
                      return Transform.translate(
                        offset: Offset(
                          (index - 1) * 20.0,
                          sin(_heartAnimation.value * pi * 2 + index) * 10,
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 16 + (_heartAnimation.value * 8),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        
        // Indicador de hambre
        if (widget.companion.needsFood)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        
        // Indicador de necesidad de amor
        if (widget.companion.needsLove)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        
        // Indicador de evolución disponible
        if (widget.companion.canEvolve)
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Puede evolucionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    _bounceController.dispose();
    _heartController.dispose();
    super.dispose();
  }
}