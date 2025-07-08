import 'package:flutter/material.dart';
import '../../domain/entities/companion_entity.dart';

class CompanionPurchaseDialog extends StatelessWidget {
  final CompanionEntity companion;
  final int userPoints;
  final VoidCallback onConfirm;
  
  const CompanionPurchaseDialog({
    Key? key,
    required this.companion,
    required this.userPoints,
    required this.onConfirm,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final canAfford = userPoints >= companion.purchasePrice;
    final remainingPoints = userPoints - companion.purchasePrice;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCompanionColor().withOpacity(0.1),
              _getCompanionColor().withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con imagen del compañero
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // Información del compañero
            _buildCompanionInfo(),
            
            const SizedBox(height: 20),
            
            // Información de la compra
            _buildPurchaseInfo(canAfford, remainingPoints),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(context, canAfford),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Imagen del compañero
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _getCompanionColor().withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.pets,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Título
        Text(
          '¿Adoptar a ${companion.displayName}?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getCompanionColor(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompanionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCompanionColor().withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tipo:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                companion.typeDescription,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Etapa:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStageColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  companion.stageDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            companion.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPurchaseInfo(bool canAfford, int remainingPoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canAfford ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Costo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Costo:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow[600],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${companion.purchasePrice}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' puntos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Puntos actuales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tus puntos:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '$userPoints puntos',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          if (canAfford) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Puntos restantes:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$remainingPoints puntos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Mensaje de estado
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: canAfford ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  canAfford ? Icons.check_circle : Icons.error,
                  color: canAfford ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canAfford
                        ? '¡Puedes adoptar a ${companion.displayName}!'
                        : 'Necesitas ${companion.purchasePrice - userPoints} puntos más',
                    style: TextStyle(
                      fontSize: 12,
                      color: canAfford ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, bool canAfford) {
    return Row(
      children: [
        // Botón cancelar
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Botón confirmar
        Expanded(
          child: ElevatedButton(
            onPressed: canAfford ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? _getCompanionColor() : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              canAfford ? 'Adoptar' : 'Insuficiente',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
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
}