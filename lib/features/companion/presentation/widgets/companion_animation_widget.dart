import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../domain/entities/companion_entity.dart';

class CompanionAnimationWidget extends StatefulWidget {
  final CompanionEntity companion;
  final double size;
  final bool isInteracting;
  final String? currentAction;
  
  const CompanionAnimationWidget({
    Key? key,
    required this.companion,
    this.size = 300,
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
  bool _isHappy = false;
  
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
    
    // Animación de rebote (solo cuando interactúa)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      Duration(milliseconds: Random().nextInt(4000) + 3000), // 3-7 segundos
      (timer) {
        if (mounted && !_isBlinking && !widget.isInteracting) {
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
    
    if (widget.isInteracting && !oldWidget.isInteracting) {
      _handleInteraction();
    }
  }
  
  void _handleInteraction() {
    // Solo rebote cuando interactúa
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    
    if (widget.currentAction == 'loving') {
      setState(() {
        _showHearts = true;
        _isHappy = true;
      });
      _heartController.forward().then((_) {
        _heartController.reverse().then((_) {
          setState(() {
            _showHearts = false;
            _isHappy = false;
          });
        });
      });
    }
    
    if (widget.currentAction == 'feeding') {
      setState(() => _isHappy = true);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _isHappy = false);
      });
    }
  }
  
  // 🔧 RUTAS CORREGIDAS PARA MASCOTAS
  String get _petImagePath {
    final name = '${widget.companion.type.name}_${widget.companion.stage.name}';
    
    // Si está parpadeando, mostrar imagen con ojos cerrados (SI EXISTE)
    if (_isBlinking) {
      return 'assets/images/companions/animations/${name}_closed.png';
    }
    
    // Si está feliz por interacción, mostrar imagen feliz (SI EXISTE)
    if (_isHappy && widget.isInteracting) {
      return 'assets/images/companions/animations/${name}_happy.png';
    }
    
    // 🔧 IMAGEN NORMAL DE LA MASCOTA - RUTA ORIGINAL
    return 'assets/images/companions/${name}.png';
  }
  
  // 🔧 FONDO ESPECÍFICO POR TIPO DE MASCOTA
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
          // 🔧 FONDO MÁS GRANDE
          Container(
            width: widget.size * 1.1, // 🔧 10% más grande
            height: widget.size * 3.1, // 🔧 10% más grande
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                _backgroundImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('🔧 Error loading background: $_backgroundImagePath');
                  debugPrint('🔧 Error details: $error');
                  // Gradiente por defecto si no encuentra el fondo
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _getDefaultGradient(),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // 🔧 MASCOTA MÁS GRANDE
          AnimatedBuilder(
            animation: Listenable.merge([_bounceAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_bounceAnimation.value * 0.05),
                child: Container(
                  width: widget.size * 2.85, // 🔧 85% del contenedor (antes era 70%)
                  height: widget.size * 1.85, // 🔧 85% del contenedor
                  child: Image.asset(
                    _petImagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('🔧 Error loading pet: $_petImagePath');
                      debugPrint('🔧 Error details: $error');
                      // 🔧 PLACEHOLDER MEJORADO SIN HUELLA
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _getCompanionColor().withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getCompanionColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                _getCompanionIcon(),
                                size: 40,
                                color: _getCompanionColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.companion.displayName,
                              style: TextStyle(
                                fontSize: 14,
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
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Imagen no encontrada',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Corazones flotantes cuando recibe amor
          if (_showHearts)
            AnimatedBuilder(
              animation: _heartAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 20 - (_heartAnimation.value * 50),
                  child: Opacity(
                    opacity: 1.0 - _heartAnimation.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        return Transform.translate(
                          offset: Offset(
                            (index - 1) * 25.0,
                            sin(_heartAnimation.value * pi * 2 + index) * 15,
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20 + (_heartAnimation.value * 10),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  // 🔧 GRADIENTES POR DEFECTO SI NO HAY FONDO
  List<Color> _getDefaultGradient() {
    switch (widget.companion.type) {
      case CompanionType.dexter:
        return [Colors.brown[200]!, Colors.brown[400]!];
      case CompanionType.elly:
        return [Colors.green[200]!, Colors.green[400]!];
      case CompanionType.paxolotl:
        return [Colors.cyan[200]!, Colors.cyan[400]!];
      case CompanionType.yami:
        return [Colors.purple[200]!, Colors.purple[400]!];
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
  
  IconData _getCompanionIcon() {
    switch (widget.companion.type) {
      case CompanionType.dexter:
        return Icons.pets; // Perro
      case CompanionType.elly:
        return Icons.forest; // Panda (bosque)
      case CompanionType.paxolotl:
        return Icons.water; // Ajolote (agua)
      case CompanionType.yami:
        return Icons.nature; // Jaguar (naturaleza)
    }
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