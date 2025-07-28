import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../domain/entities/companion_entity.dart';

class CompanionAnimationWidget extends StatefulWidget {
  final CompanionEntity companion;
  final double size;
  final bool isInteracting;
  final String? currentAction;
  final bool showBackground;
  
  const CompanionAnimationWidget({
    Key? key,
    required this.companion,
    this.size = 350,
    this.isInteracting = false,
    this.currentAction,
    this.showBackground = false,
  }) : super(key: key);
  
  @override
  State<CompanionAnimationWidget> createState() => _CompanionAnimationWidgetState();
}

class _CompanionAnimationWidgetState extends State<CompanionAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _bounceController;
  late AnimationController _heartController;
  late AnimationController _feedController;
  late AnimationController _happyController;
  late AnimationController _floatingController;
  
  late Animation<double> _blinkAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _heartAnimation;
  late Animation<double> _feedAnimation;
  late Animation<double> _happyAnimation;
  late Animation<double> _floatingAnimation;
  
  Timer? _blinkTimer;
  Timer? _actionTimer;
  bool _isBlinking = false;
  bool _showHearts = false;
  bool _isHappy = false;
  bool _isFeeding = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startBlinkTimer();
    _startFloatingAnimation();
  }
  
  void _setupAnimations() {
    // 👁️ Animación de parpadeo
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    
    // 🦘 Animación de rebote (cuando interactúa)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    // 💕 Animación de corazones (amor)
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );
    
    // 🍎 Animación de alimentación
    _feedController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _feedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedController, curve: Curves.easeInOut),
    );
    
    // 😊 Animación de felicidad
    _happyController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _happyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _happyController, curve: Curves.bounceOut),
    );
    
    // 🌸 Animación flotante sutil
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }
  
  void _startBlinkTimer() {
    _blinkTimer = Timer.periodic(
      Duration(milliseconds: Random().nextInt(3000) + 2000),
      (timer) {
        if (mounted && !_isBlinking && !widget.isInteracting) {
          _blink();
        }
      },
    );
  }
  
  void _startFloatingAnimation() {
    _floatingController.repeat(reverse: true);
  }
  
  void _blink() async {
    if (!mounted) return;
    setState(() => _isBlinking = true);
    await _blinkController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await _blinkController.reverse();
      setState(() => _isBlinking = false);
    }
  }
  
  @override
  void didUpdateWidget(CompanionAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isInteracting && !oldWidget.isInteracting) {
      _handleInteraction();
    }
  }
  
  void _handleInteraction() {
    debugPrint('🎭 [ANIMATION] === INICIANDO INTERACCIÓN ===');
    debugPrint('🎯 [ANIMATION] Acción: ${widget.currentAction}');
    
    // 🦘 Rebote universal más suave
    _bounceController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _bounceController.reverse();
      });
    });
    
    if (widget.currentAction == 'loving') {
      _handleLoveAction();
    } else if (widget.currentAction == 'feeding') {
      _handleFeedAction();
    }
  }
  
  void _handleLoveAction() {
    debugPrint('💖 [ANIMATION] === ANIMACIÓN DE AMOR ===');
    _actionTimer?.cancel();
    
    setState(() {
      _showHearts = true;
      _isHappy = true;
    });
    
    // Corazones flotantes
    _heartController.reset();
    _heartController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _heartController.reverse().then((_) {
            if (mounted) {
              setState(() => _showHearts = false);
            }
          });
        }
      });
    });
    
    // Felicidad
    _happyController.reset();
    _happyController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _happyController.reverse();
      });
    });
    
    _actionTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _isHappy = false);
    });
  }
  
  void _handleFeedAction() {
    debugPrint('🍎 [ANIMATION] === ANIMACIÓN DE ALIMENTACIÓN ===');
    _actionTimer?.cancel();
    
    setState(() {
      _isFeeding = true;
      _isHappy = true;
    });
    
    // Animación de comida
    _feedController.reset();
    _feedController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _feedController.reverse().then((_) {
            if (mounted) {
              setState(() => _isFeeding = false);
            }
          });
        }
      });
    });
    
    // Felicidad por comer
    _happyController.reset();
    _happyController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _happyController.reverse();
      });
    });
    
    _actionTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _isHappy = false);
    });
  }
  
  String get _petImagePath {
    final baseName = '${widget.companion.type.name}_${widget.companion.stage.name}';
    
    // 👁️ Parpadeo
    if (_isBlinking) {
      return 'assets/images/companions/animations/${baseName}_closed.png';
    }
    
    // 🍎 Comiendo
    if (_isFeeding && widget.isInteracting) {
      return 'assets/images/companions/animations/${baseName}_eating.png';
    }
    
    // 😊 Feliz por interacción
    if (_isHappy && widget.isInteracting) {
      return 'assets/images/companions/animations/${baseName}_happy.png';
    }
    
    // 🔧 Imagen normal
    return 'assets/images/companions/${baseName}.png';
  }

  String get _backgroundImagePath {
    switch (widget.companion.type) {
      case CompanionType.dexter:
        return 'assets/images/companions/backgrounds/dexter_bg.png';
      case CompanionType.elly:
        return 'assets/images/companions/backgrounds/elly_bg.png';
      case CompanionType.paxolotl:
        return 'assets/images/companions/backgrounds/paxolotl_bg.png';
      case CompanionType.yami:
        return 'assets/images/companions/backgrounds/yami_bg.png';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🆕 FONDO CONDICIONAL
          if (widget.showBackground)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    _backgroundImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getCompanionColor().withOpacity(0.3),
                              _getCompanionColor().withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          
          if (!widget.showBackground)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          
          // 🐾 MASCOTA CON ANIMACIONES SUAVES
          AnimatedBuilder(
            animation: Listenable.merge([
              _bounceAnimation, 
              _happyAnimation, 
              _floatingAnimation
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  // 🌸 Flotación muy sutil
                  (sin(_floatingAnimation.value * pi * 2) * 3) + 
                  // 🦘 Rebote suave
                  (_bounceAnimation.value * -8) +
                  // 😊 Movimiento de felicidad sutil
                  (sin(_happyAnimation.value * pi * 3) * 1.5)
                ),
                child: Transform.scale(
                  scale: 1.0 + 
                         (_bounceAnimation.value * 0.05) +  // Rebote muy sutil
                         (_happyAnimation.value * 0.03) +   // Felicidad sutil
                         (sin(_floatingAnimation.value * pi * 2) * 0.01), // Flotación mínima
                  child: Container(
                    width: widget.size * 0.8,  // Mantener tamaño original
                    height: widget.size * 0.8, // Mantener tamaño original
                    child: Image.asset(
                      _petImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        if (_isBlinking || _isHappy || _isFeeding) {
                          final normalPath = 'assets/images/companions/${widget.companion.type.name}_${widget.companion.stage.name}.png';
                          return Image.asset(
                            normalPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error2, stackTrace2) {
                              return _buildEnhancedPlaceholder();
                            },
                          );
                        }
                        return _buildEnhancedPlaceholder();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 💕 CORAZONES FLOTANTES MEJORADOS
          if (_showHearts)
            AnimatedBuilder(
              animation: _heartAnimation,
              builder: (context, child) {
                return Stack(
                  children: List.generate(8, (index) {
                    final angle = (index * pi * 2) / 8;
                    final radius = 40 + (_heartAnimation.value * 60);
                    final opacity = (1.0 - _heartAnimation.value * 0.8).clamp(0.2, 1.0);
                    
                    return Positioned(
                      left: (widget.size / 2) + cos(angle + _heartAnimation.value * pi) * radius,
                      top: (widget.size / 2) + sin(angle + _heartAnimation.value * pi) * radius - 
                          (_heartAnimation.value * 80),
                      child: Transform.scale(
                        scale: 0.6 + (_heartAnimation.value * 0.8),
                        child: Transform.rotate(
                          angle: _heartAnimation.value * pi / 4,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red[400],
                                size: 16 + (_heartAnimation.value * 8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          
          // 🍎 EFECTOS DE ALIMENTACIÓN MEJORADOS
          if (_isFeeding)
            AnimatedBuilder(
              animation: _feedAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Comida cayendo desde arriba
                    Positioned(
                      top: 20 - (_feedAnimation.value * 50),
                      left: widget.size / 2 - 40,
                      child: Opacity(
                        opacity: (1.0 - _feedAnimation.value * 0.7).clamp(0.3, 1.0),
                        child: Transform.scale(
                          scale: 0.8 + (_feedAnimation.value * 0.4),
                          child: Transform.rotate(
                            angle: _feedAnimation.value * pi / 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🍎',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Más comida
                    Positioned(
                      top: 25 - (_feedAnimation.value * 45),
                      left: widget.size / 2 + 10,
                      child: Opacity(
                        opacity: (1.0 - _feedAnimation.value * 0.8).clamp(0.2, 1.0),
                        child: Transform.scale(
                          scale: 0.7 + (_feedAnimation.value * 0.3),
                          child: Transform.rotate(
                            angle: -_feedAnimation.value * pi / 3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🥕',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Tercera comida
                    Positioned(
                      top: 30 - (_feedAnimation.value * 40),
                      left: widget.size / 2 - 20,
                      child: Opacity(
                        opacity: (1.0 - _feedAnimation.value * 0.9).clamp(0.1, 1.0),
                        child: Transform.scale(
                          scale: 0.6 + (_feedAnimation.value * 0.2),
                          child: Transform.rotate(
                            angle: _feedAnimation.value * pi / 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '🥬',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          
          // ✨ EFECTOS DE FELICIDAD SUAVES
          if (_isHappy && widget.isInteracting)
            AnimatedBuilder(
              animation: _happyAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Estrella principal
                    Positioned(
                      top: 15 - (_happyAnimation.value * 30),
                      left: widget.size / 2 - 10,
                      child: Opacity(
                        opacity: (1.0 - _happyAnimation.value * 0.5).clamp(0.5, 1.0),
                        child: Transform.scale(
                          scale: 0.8 + (_happyAnimation.value * 0.6),
                          child: Transform.rotate(
                            angle: _happyAnimation.value * pi,
                            child: Text(
                              '✨',
                              style: TextStyle(
                                fontSize: 18 + (_happyAnimation.value * 8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Estrella secundaria
                    Positioned(
                      top: 20 - (_happyAnimation.value * 25),
                      left: widget.size / 2 + 15,
                      child: Opacity(
                        opacity: (1.0 - _happyAnimation.value * 0.6).clamp(0.4, 1.0),
                        child: Transform.scale(
                          scale: 0.6 + (_happyAnimation.value * 0.4),
                          child: Transform.rotate(
                            angle: -_happyAnimation.value * pi / 2,
                            child: Text(
                              '⭐',
                              style: TextStyle(
                                fontSize: 14 + (_happyAnimation.value * 6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Tercera estrella
                    Positioned(
                      top: 25 - (_happyAnimation.value * 20),
                      left: widget.size / 2 - 25,
                      child: Opacity(
                        opacity: (1.0 - _happyAnimation.value * 0.7).clamp(0.3, 1.0),
                        child: Transform.scale(
                          scale: 0.5 + (_happyAnimation.value * 0.3),
                          child: Transform.rotate(
                            angle: _happyAnimation.value * pi / 3,
                            child: Text(
                              '💫',
                              style: TextStyle(
                                fontSize: 12 + (_happyAnimation.value * 4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCompanionColor().withOpacity(0.3),
            _getCompanionColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getCompanionColor().withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCompanionColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _getCompanionIcon(),
              size: 40,
              color: _getCompanionColor(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.companion.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getCompanionColor(),
            ),
          ),
          Text(
            widget.companion.typeDescription,
            style: TextStyle(
              fontSize: 12,
              color: _getCompanionColor().withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
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
  
  IconData _getCompanionIcon() {
    switch (widget.companion.type) {
      case CompanionType.dexter:
        return Icons.pets;
      case CompanionType.elly:
        return Icons.forest;
      case CompanionType.paxolotl:
        return Icons.water;
      case CompanionType.yami:
        return Icons.nature;
    }
  }
  
  @override
  void dispose() {
    _blinkTimer?.cancel();
    _actionTimer?.cancel();
    _blinkController.dispose();
    _bounceController.dispose();
    _heartController.dispose();
    _feedController.dispose();
    _happyController.dispose();
    _floatingController.dispose();
    super.dispose();
  }
}