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
      onWillPop: () async => true, // 🔧 Permitir cerrar con back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // 🔧 Padding ajustado
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85, // 🔧 Altura máxima del 85%
                maxWidth: MediaQuery.of(context).size.width * 0.9,   // 🔧 Ancho máximo del 90%
              ),
              child: Container(
                padding: const EdgeInsets.all(20), // 🔧 Padding reducido
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
                child: Stack( // 🔧 Stack para el botón X
                  children: [
                    // Botón cerrar (X)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          debugPrint('❌ [WELCOME_DIALOG] Usuario cerró el diálogo sin adoptar');
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    
                    // Contenido principal
                    SingleChildScrollView( // 🔧 Scroll si es necesario
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12), // 🔧 Espacio para el botón X
                          
                          // Efectos de brillos
                          _buildSparkleEffects(),
                          
                          // Título de bienvenida
                          _buildWelcomeTitle(),
                          
                          const SizedBox(height: 16), // 🔧 Espaciado reducido
                          
                          // Imagen de Dexter baby
                          _buildDexterImage(),
                          
                          const SizedBox(height: 16), // 🔧 Espaciado reducido
                          
                          // Mensaje de bienvenida
                          _buildWelcomeMessage(),
                          
                          const SizedBox(height: 20), // 🔧 Espaciado reducido
                          
                          // Botones
                          _buildButtons(),
                          
                          const SizedBox(height: 8), // 🔧 Espacio extra inferior
                        ],
                      ),
                    ),
                  ],
                ),
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
          height: 40, // 🔧 Altura reducida
          child: Stack(
            children: List.generate(6, (index) {
              final angle = (index * pi * 2) / 6;
              final radius = 15 + (sin(_sparkleAnimation.value * pi * 2) * 8); // 🔧 Radio reducido
              return Positioned(
                left: MediaQuery.of(context).size.width * 0.4 + cos(angle + _sparkleAnimation.value * pi * 2) * radius,
                top: 20 + sin(angle + _sparkleAnimation.value * pi * 2) * radius,
                child: Transform.scale(
                  scale: 0.3 + (sin(_sparkleAnimation.value * pi * 4 + index) * 0.3), // 🔧 Escala reducida
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.yellow[300]!.withOpacity(0.9),
                    size: 14, // 🔧 Tamaño reducido
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
              size: 28, // 🔧 Tamaño reducido
            ),
            const SizedBox(width: 12),
            const Text(
              '¡BIENVENIDO!',
              style: TextStyle(
                fontSize: 24, // 🔧 Tamaño reducido
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.celebration,
              color: Colors.yellow[300],
              size: 28, // 🔧 Tamaño reducido
            ),
          ],
        ),
        
        const SizedBox(height: 6), // 🔧 Espaciado reducido
        
        Text(
          'Has recibido tu primer compañero',
          style: TextStyle(
            fontSize: 14, // 🔧 Tamaño reducido
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDexterImage() {
    return Container(
      height: 140, // 🔧 Altura reducida
      width: 140,  // 🔧 Ancho reducido
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
          size: 120, // 🔧 Tamaño reducido
          isInteracting: false,
        ),
      ),
    );
  }
  
  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(14), // 🔧 Padding reducido
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
                size: 18, // 🔧 Tamaño reducido
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.dexterBaby.displayName} Bebé',
                style: const TextStyle(
                  fontSize: 18, // 🔧 Tamaño reducido
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6), // 🔧 Espaciado reducido
          
          Text(
            'Chihuahua', // 🔧 Descripción más corta
            style: TextStyle(
              fontSize: 13, // 🔧 Tamaño reducido
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 10), // 🔧 Espaciado reducido
          
          // Mensaje especial
          Container(
            padding: const EdgeInsets.all(10), // 🔧 Padding reducido
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
                      size: 14, // 🔧 Tamaño reducido
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Características especiales:',
                        style: TextStyle(
                          fontSize: 11, // 🔧 Tamaño reducido
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6), // 🔧 Espaciado reducido
                
                Wrap(
                  spacing: 4, // 🔧 Espaciado reducido
                  runSpacing: 3, // 🔧 Espaciado reducido
                  children: [
                    _buildFeatureChip('Gratuito'),
                    _buildFeatureChip('Fácil cuidado'),
                    _buildFeatureChip('Tu primer amigo'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10), // 🔧 Espaciado reducido
          
          Text(
            '¡${widget.dexterBaby.displayName} será tu compañero en esta aventura!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, // 🔧 Tamaño reducido
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // 🔧 Padding reducido
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10), // 🔧 Border radius reducido
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9, // 🔧 Tamaño reducido
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildButtons() {
    return Column(
      children: [
        // Botón principal - Conocer a Dexter
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              debugPrint('🎉 [WELCOME_DIALOG] Usuario continuó después de bienvenida');
              Navigator.of(context).pop();
              widget.onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
            ),
            icon: Icon(
              Icons.arrow_forward,
              size: 18,
              color: Colors.green[600],
            ),
            label: Text(
              '¡Conocer a ${widget.dexterBaby.displayName}!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Botón secundario - Ahora no
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton(
            onPressed: () {
              debugPrint('⏭️ [WELCOME_DIALOG] Usuario saltó la bienvenida');
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Ahora no, gracias',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
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