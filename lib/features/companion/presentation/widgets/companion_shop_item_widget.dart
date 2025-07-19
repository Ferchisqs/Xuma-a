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
                  
                  // 🔧 SOLO MASCOTA PNG - SIN FONDO NI DECORACIONES
                  Expanded(
                    flex: 3,
                    child: _buildCompanionImageOnly(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Información del compañero
                  _buildCompanionInfo(),
                  
                  const SizedBox(height: 8),
                  
                  // Botón de compra
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
  
  // 🔧 NUEVO WIDGET PARA MOSTRAR SOLO LA MASCOTA PNG (SIN FONDOS)
  Widget _buildCompanionImageOnly() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            width: constraints.maxWidth * 0.85,
            height: constraints.maxHeight * 0.85,
            // 🔧 SOLO LA MASCOTA PNG - SIN FONDO DE COLORES NI IMÁGENES
            child: Image.asset(
              _getPetImagePath(),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('🔧 Error loading shop pet: ${_getPetImagePath()}');
                debugPrint('🔧 Error details: $error');
                // 🔧 PLACEHOLDER SIMPLE Y LIMPIO
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCompanionColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 8),
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
                          'PNG no encontrado',
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
        );
      },
    );
  }
  
  // 🔧 RUTA SIMPLE DE LA MASCOTA (SOLO PNG)
  String _getPetImagePath() {
    final name = '${companion.type.name}_${companion.stage.name}';
    final path = 'assets/images/companions/$name.png';
    debugPrint('🐾 Cargando mascota tienda: $path');
    return path;
  }
  
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