import 'package:flutter/material.dart';
import '../../domain/entities/companion_entity.dart';
import 'companion_animation_widget.dart';

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
        margin: const EdgeInsets.all(8),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con nombre y estado
              _buildHeader(),
              
              const SizedBox(height: 12),
              
              // Imagen del compañero con animación
              CompanionAnimationWidget(
                companion: companion,
                size: 120,
              ),
              
              const SizedBox(height: 12),
              
              // Información detallada (si showDetails es true)
              if (showDetails) ...[
                _buildCompanionInfo(),
                
                const SizedBox(height: 8),
                
                // Barras de estadísticas (solo si es propiedad del usuario)
                if (companion.isOwned && !isInShop)
                  _buildStatsSection(),
                
                // Información de precio (solo en tienda)
                if (isInShop && !companion.isOwned)
                  _buildPriceSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nombre y tipo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companion.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${companion.typeDescription} ${companion.stageDisplayName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        
        // Estado/Badges
        Column(
          children: [
            if (companion.isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ACTIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            if (companion.canEvolve)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '★ EVOLUCIÓN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCompanionInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            companion.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          if (companion.isOwned) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Nivel', companion.level.toString()),
                _buildStatItem('EXP', '${companion.experience}/${companion.experienceNeededForNextStage}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatsSection() {
    return Column(
      children: [
        // Barra de felicidad
        _buildStatBar(
          'Felicidad',
          companion.happiness,
          100,
          Colors.yellow,
          Icons.sentiment_very_satisfied,
        ),
        
        const SizedBox(height: 4),
        
        // Barra de hambre
        _buildStatBar(
          'Hambre',
          companion.hunger,
          100,
          Colors.orange,
          Icons.restaurant,
        ),
        
        const SizedBox(height: 4),
        
        // Barra de energía
        _buildStatBar(
          'Energía',
          companion.energy,
          100,
          Colors.blue,
          Icons.bolt,
        ),
      ],
    );
  }
  
  Widget _buildStatBar(String label, int value, int maxValue, Color color, IconData icon) {
    final percentage = value / maxValue;
    
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Precio:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.yellow,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${companion.purchasePrice}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'puntos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  List<Color> _getGradientColors() {
    if (!companion.isOwned && isInShop) {
      // Colores para compañeros no adquiridos en tienda
      return [
        Colors.grey[600]!,
        Colors.grey[800]!,
      ];
    }
    
    // Colores basados en el tipo de compañero
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