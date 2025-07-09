import 'package:flutter/material.dart';
import '../../domain/entities/companion_entity.dart';

class CompanionShopItemWidget extends StatelessWidget {
  final CompanionEntity companion;
  final int userPoints;
  final VoidCallback onPurchase;
  
  const CompanionShopItemWidget({
    Key? key,
    required this.companion,
    required this.userPoints,
    required this.onPurchase,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final canAfford = userPoints >= companion.purchasePrice;
    
    // 🧪 DEBUG: Log cuando se renderiza cada item
    debugPrint('🏪 Renderizando item: ${companion.displayName}');
    debugPrint('💰 Puntos usuario: $userPoints, Precio: ${companion.purchasePrice}, Puede comprar: $canAfford');
    
    return GestureDetector(
      onTap: canAfford ? () {
        debugPrint('👆 Usuario tocó item: ${companion.displayName}');
        debugPrint('🎯 Ejecutando onPurchase callback...');
        onPurchase();
      } : () {
        debugPrint('❌ Usuario tocó item pero no puede comprarlo: ${companion.displayName}');
        debugPrint('💸 Necesita ${companion.purchasePrice - userPoints} puntos más');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: canAfford ? _getGradientColors() : _getDisabledColors(),
          ),
          boxShadow: [
            BoxShadow(
              color: canAfford 
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
              blurRadius: canAfford ? 10 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de etapa
                  _buildStageBadge(),
                  
                  // 🔧 ÁREA DE IMAGEN CON FONDO + MASCOTA
                  Expanded(
                    flex: 3,
                    child: _buildCompanionImageWithBackground(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Información del compañero
                  _buildCompanionInfo(),
                  
                  const SizedBox(height: 8),
                  
                  // 🧪 BOTÓN DE COMPRA MÁS VISIBLE CON DEBUG
                  _buildPurchaseButton(canAfford),
                ],
              ),
            ),
            
            // Overlay si no se puede comprar
            if (!canAfford)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Puntos\nInsuficientes',
                        textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
  
  // 🧪 BOTÓN DE COMPRA MEJORADO CON DEBUG
  Widget _buildPurchaseButton(bool canAfford) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAfford ? () {
          debugPrint('🎯 BOTÓN DE COMPRA PRESIONADO: ${companion.displayName}');
          debugPrint('💰 Precio: ${companion.purchasePrice}, Puntos usuario: $userPoints');
          debugPrint('🚀 Ejecutando callback onPurchase...');
          onPurchase();
        } : () {
          debugPrint('❌ Botón bloqueado presionado: ${companion.displayName}');
          debugPrint('💸 Faltan ${companion.purchasePrice - userPoints} puntos');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford ? _getCompanionColor() : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: canAfford ? 4 : 1,
        ),
        icon: Icon(
          canAfford ? Icons.pets : Icons.lock,
          size: 16,
          color: Colors.white,
        ),
        label: Text(
          canAfford ? 'ADOPTAR ${companion.purchasePrice}★' : 'SIN PUNTOS',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  // 🔧 NUEVO WIDGET PARA MOSTRAR FONDO + MASCOTA EN LA TIENDA
  Widget _buildCompanionImageWithBackground() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 🔧 FONDO ESPECÍFICO POR TIPO DE MASCOTA
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  _getBackgroundImagePath(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('🔧 Error loading shop background: ${_getBackgroundImagePath()}');
                    debugPrint('🔧 Error details: $error');
                    // Gradiente de respaldo
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _getDefaultGradient(),
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 🔧 MASCOTA SUPERPUESTA
            Container(
              width: constraints.maxWidth * 0.8,
              height: constraints.maxHeight * 0.8,
              child: Image.asset(
                _getPetImagePath(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('🔧 Error loading shop pet: ${_getPetImagePath()}');
                  debugPrint('🔧 Error details: $error');
                  // Placeholder mejorado
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCompanionColor().withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getCompanionColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            _getCompanionIcon(),
                            size: 30,
                            color: _getCompanionColor(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          companion.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getCompanionColor(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Imagen no encontrada',
                            style: TextStyle(
                              fontSize: 8,
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
          ],
        );
      },
    );
  }
  
  // 🔧 RUTAS DE IMÁGENES PARA LA TIENDA
  String _getBackgroundImagePath() {
    final path = 'assets/images/companions/backgrounds/${companion.type.name}_bg.png';
    debugPrint('🏞️ Cargando fondo: $path');
    return path;
  }
  
  String _getPetImagePath() {
    final name = '${companion.type.name}_${companion.stage.name}';
    final path = 'assets/images/companions/$name.png';
    debugPrint('🐾 Cargando mascota: $path');
    return path;
  }
  
  Widget _buildStageBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStageColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        companion.stageDisplayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildCompanionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          companion.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          companion.typeDescription,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Color _getStageColor() {
    switch (companion.stage) {
      case CompanionStage.baby:
        return Colors.green;
      case CompanionStage.young:
        return Colors.orange;
      case CompanionStage.adult:
        return Colors.red;
    }
  }
  
  Color _getCompanionColor() {
    switch (companion.type) {
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
    switch (companion.type) {
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
  
  List<Color> _getDefaultGradient() {
    switch (companion.type) {
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
  
  List<Color> _getGradientColors() {
    final baseColor = _getCompanionColor();
    return [
      baseColor.withOpacity(0.8),
      baseColor,
    ];
  }
  
  List<Color> _getDisabledColors() {
    return [
      Colors.grey[400]!,
      Colors.grey[600]!,
    ];
  }
}