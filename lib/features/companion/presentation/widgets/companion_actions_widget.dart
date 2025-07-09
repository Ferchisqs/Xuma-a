import 'package:flutter/material.dart';
import '../../domain/entities/companion_entity.dart';

class CompanionActionsWidget extends StatelessWidget {
  final CompanionEntity companion;
  final VoidCallback? onFeed;
  final VoidCallback? onLove;
  final VoidCallback? onEvolve;
  final bool isLoading;
  final String? currentAction;
  
  const CompanionActionsWidget({
    Key? key,
    required this.companion,
    this.onFeed,
    this.onLove,
    this.onEvolve,
    this.isLoading = false,
    this.currentAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual para indicar que se puede deslizar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Título
          Text(
            'Cuidar a ${companion.displayName}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Botones de acción en fila
          Row(
            children: [
              // Botón Alimentar
              Expanded(
                child: _buildActionButton(
                  label: 'Alimentar',
                  icon: Icons.restaurant,
                  color: Colors.orange,
                  onPressed: companion.needsFood || !isLoading ? onFeed : null,
                  isActive: currentAction == 'feeding',
                  needsAttention: companion.needsFood,
                  description: companion.needsFood 
                    ? '¡Tiene hambre!' 
                    : 'Hambre: ${companion.hunger}/100',
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón Amor
              Expanded(
                child: _buildActionButton(
                  label: 'Dar Amor',
                  icon: Icons.favorite,
                  color: Colors.pink,
                  onPressed: companion.needsLove || !isLoading ? onLove : null,
                  isActive: currentAction == 'loving',
                  needsAttention: companion.needsLove,
                  description: companion.needsLove 
                    ? '¡Necesita cariño!' 
                    : 'Felicidad: ${companion.happiness}/100',
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón Evolucionar
              Expanded(
                child: _buildActionButton(
                  label: 'Evolucionar',
                  icon: Icons.auto_awesome,
                  color: Colors.purple,
                  onPressed: companion.canEvolve && !isLoading ? onEvolve : null,
                  isActive: currentAction == 'evolving',
                  needsAttention: companion.canEvolve,
                  description: companion.canEvolve 
                    ? '¡Listo para evolucionar!' 
                    : 'EXP: ${companion.experience}/${companion.experienceNeededForNextStage}',
                  disabled: !companion.canEvolve,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información adicional
          if (isLoading)
            _buildLoadingInfo()
          else
            _buildCompanionStatus(),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String description,
    bool isActive = false,
    bool needsAttention = false,
    bool disabled = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: disabled 
                  ? Colors.grey[300]
                  : isActive 
                    ? color.withOpacity(0.8)
                    : needsAttention 
                      ? color
                      : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: needsAttention 
                  ? Border.all(color: color, width: 2)
                  : null,
                boxShadow: needsAttention ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isActive)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          disabled ? Colors.grey : Colors.white,
                        ),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: disabled 
                        ? Colors.grey[600]
                        : needsAttention || isActive 
                          ? Colors.white 
                          : color,
                      size: 28,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: disabled 
                        ? Colors.grey[600]
                        : needsAttention || isActive 
                          ? Colors.white 
                          : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: needsAttention ? color : Colors.grey[600],
              fontWeight: needsAttention ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingInfo() {
    String message = '';
    switch (currentAction) {
      case 'feeding':
        message = '${companion.displayName} está comiendo...';
        break;
      case 'loving':
        message = '${companion.displayName} se siente feliz...';
        break;
      case 'evolving':
        message = '${companion.displayName} está evolucionando...';
        break;
      default:
        message = 'Procesando...';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompanionStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusMessage(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    if (companion.needsFood || companion.needsLove) {
      return Colors.orange;
    } else if (companion.canEvolve) {
      return Colors.green;
    } else if (companion.isHappy) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
  
  IconData _getStatusIcon() {
    if (companion.needsFood) {
      return Icons.restaurant;
    } else if (companion.needsLove) {
      return Icons.favorite_border;
    } else if (companion.canEvolve) {
      return Icons.star;
    } else if (companion.isHappy) {
      return Icons.sentiment_very_satisfied;
    } else {
      return Icons.sentiment_neutral;
    }
  }
  
  String _getStatusMessage() {
    if (companion.needsFood && companion.needsLove) {
      return '${companion.displayName} tiene hambre y necesita cariño';
    } else if (companion.needsFood) {
      return '${companion.displayName} tiene hambre';
    } else if (companion.needsLove) {
      return '${companion.displayName} necesita cariño';
    } else if (companion.canEvolve) {
      return '¡${companion.displayName} puede evolucionar!';
    } else if (companion.isHappy) {
      return '${companion.displayName} está muy feliz';
    } else {
      return '${companion.displayName} está bien';
    }
  }
}