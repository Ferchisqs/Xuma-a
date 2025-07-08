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
    
    return GestureDetector(
      onTap: canAfford ? onPurchase : null,
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
                  _buildStadgeBadge(),
                  
                  // Imagen del compañero
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _buildCompanionImage(),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Información del compañero
                  _buildCompanionInfo(),
                  
                  const SizedBox(height: 8),
                  
                  // Precio y botón
                  _buildPriceSection(canAfford),
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
  
  Widget _buildStadgeBadge() {
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
  
  Widget _buildCompanionImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.asset(
          companion.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.pets,
                size: 40,
                color: Colors.grey[600],
              ),
            );
          },
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
  
  Widget _buildPriceSection(bool canAfford) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Precio
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.yellow[300],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${companion.purchasePrice}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          // Botón de compra
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: canAfford ? Colors.white : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              canAfford ? 'COMPRAR' : 'BLOQUEADO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: canAfford ? _getCompanionColor() : Colors.white,
              ),
            ),
          ),
        ],
      ),
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