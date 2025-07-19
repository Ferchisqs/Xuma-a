import 'package:flutter/material.dart';
import '../../domain/entities/companion_entity.dart';

class CompanionCardWidget extends StatelessWidget {
  final CompanionEntity companion;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showDetails;
  final bool isInShop;
  
  const CompanionCardWidget({
    Key? key,
    required this.companion,
    this.onTap,
    this.isSelected = false,
    this.showDetails = true,
    this.isInShop = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.blue.withOpacity(0.4) : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected 
            ? Border.all(color: Colors.blue, width: 3)
            : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header compacto
                  _buildCompactHeader(),
                  
                  // 🔧 SOLO MASCOTA PNG - SIN FONDO
                  Expanded(
                    flex: 4,
                    child: _buildPetOnly(),
                  ),
                  
                  if (showDetails)
                    Expanded(
                      flex: 1,
                      child: _buildCompactInfo(),
                    ),
                ],
              ),
            ),
            
            // Badges flotantes
            ..._buildFloatingBadges(),
          ],
        ),
      ),
    );
  }
  
  // 🔧 NUEVO WIDGET PARA MOSTRAR SOLO LA MASCOTA PNG
  Widget _buildPetOnly() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            width: constraints.maxWidth * 0.9,
            height: constraints.maxHeight * 0.9,
            // 🔧 SIN FONDO - SOLO LA MASCOTA
            child: Image.asset(
              _getPetImagePath(),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('🔧 Error loading companion image: ${_getPetImagePath()}');
                // 🔧 PLACEHOLDER SIMPLE PARA LA MASCOTA
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCompanionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getCompanionIcon(),
                          size: 24,
                          color: _getCompanionColor(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        companion.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getCompanionColor(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PNG no encontrado',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
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
    debugPrint('🐾 Loading companion PNG: $path');
    return path;
  }
  
  Widget _buildCompactHeader() {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Text(
              companion.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          // Badge de etapa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStageColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              companion.stageDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactInfo() {
    if (isInShop && !companion.isOwned) {
      return _buildPriceInfo();
    }
    
    if (companion.isOwned) {
      return _buildOwnerInfo();
    }
    
    return const SizedBox.shrink();
  }
  
  Widget _buildPriceInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Precio:',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: Colors.yellow,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                '${companion.purchasePrice}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOwnerInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatBadge('Nv${companion.level}', Colors.blue),
        _buildStatBadge('${companion.happiness}❤️', Colors.red),
        if (companion.canEvolve)
          _buildStatBadge('EVO', Colors.orange),
      ],
    );
  }
  
  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  List<Widget> _buildFloatingBadges() {
    List<Widget> badges = [];
    
    // Badge "ACTIVO" si está seleccionado
    if (companion.isSelected) {
      badges.add(
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'ACTIVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    
    // Indicadores de necesidades en la parte inferior
    if (companion.isOwned) {
      if (companion.needsFood || companion.needsLove) {
        badges.add(
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                if (companion.needsFood)
                  _buildNeedIndicator(Icons.restaurant, Colors.orange),
                if (companion.needsFood && companion.needsLove)
                  const SizedBox(width: 4),
                if (companion.needsLove)
                  _buildNeedIndicator(Icons.favorite, Colors.pink),
              ],
            ),
          ),
        );
      }
    }
    
    return badges;
  }
  
  Widget _buildNeedIndicator(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 12,
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
    if (!companion.isOwned && isInShop) {
      return [
        Colors.grey[600]!,
        Colors.grey[800]!,
      ];
    }
    
    switch (companion.type) {
      case CompanionType.dexter:
        return [Colors.brown[300]!, Colors.brown[600]!];
      case CompanionType.elly:
        return [Colors.green[300]!, Colors.green[600]!];
      case CompanionType.paxolotl:
        return [Colors.cyan[300]!, Colors.cyan[600]!];
      case CompanionType.yami:
        return [Colors.purple[300]!, Colors.purple[600]!];
    }
  }
}