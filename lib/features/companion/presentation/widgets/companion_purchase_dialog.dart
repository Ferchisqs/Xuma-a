// lib/features/companion/presentation/widgets/companion_purchase_dialog.dart
// 🔥 SECCIÓN CORREGIDA: Mensajes más claros para tipos adoptados

import 'package:flutter/material.dart';
import '../../domain/entities/companion_entity.dart';

class CompanionPurchaseDialog extends StatelessWidget {
  final CompanionEntity companion;
  final int userPoints;
  final VoidCallback onConfirm;
  final bool typeAlreadyOwned; // 🔥 NUEVO: Indicador si el tipo ya fue adoptado
  
  const CompanionPurchaseDialog({
    Key? key,
    required this.companion,
    required this.userPoints,
    required this.onConfirm,
    this.typeAlreadyOwned = false, // 🔥 NUEVO PARÁMETRO
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canAfford = userPoints >= companion.purchasePrice;
    final remainingPoints = userPoints - companion.purchasePrice;
    
    // 🔥 VALIDACIÓN MEJORADA: Verificar si el tipo ya fue adoptado
    final canPurchase = canAfford && !companion.isOwned && !typeAlreadyOwned;
    
    debugPrint('🛒 [PURCHASE_DIALOG] === MOSTRANDO DIÁLOGO MEJORADO ===');
    debugPrint('🛒 [PURCHASE_DIALOG] Companion: ${companion.displayName}');
    debugPrint('💰 [PURCHASE_DIALOG] Puntos usuario: $userPoints, Precio: ${companion.purchasePrice}');
    debugPrint('✅ [PURCHASE_DIALOG] Puede comprar: $canAfford, Ya poseído: ${companion.isOwned}');
    debugPrint('🐾 [PURCHASE_DIALOG] Tipo ya adoptado: $typeAlreadyOwned');
    debugPrint('🎯 [PURCHASE_DIALOG] Puede proceder: $canPurchase');
    
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
            
            // 🔥 INFORMACIÓN DE LA COMPRA MEJORADA
            _buildPurchaseInfo(canAfford, remainingPoints, typeAlreadyOwned),
            
            const SizedBox(height: 24),
            
            // 🔥 BOTONES DE ACCIÓN MEJORADOS
            _buildActionButtons(context, canPurchase, typeAlreadyOwned),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // 🔧 IMAGEN DEL COMPAÑERO CON FALLBACK MEJORADO
        Container(
          width: 120,
          height: 120,
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
            child: Stack(
              children: [
                // 🔧 FONDO CON GRADIENTE
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCompanionColor().withOpacity(0.8),
                        _getCompanionColor(),
                      ],
                    ),
                  ),
                ),
                // 🔧 IMAGEN DE LA MASCOTA
                Image.asset(
                  _getPetImagePath(),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('🔧 Error cargando imagen en diálogo: ${_getPetImagePath()}');
                    return Container(
                      color: _getCompanionColor().withOpacity(0.2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCompanionIcon(),
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            companion.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 🔥 TÍTULO MEJORADO
        Text(
          typeAlreadyOwned 
            ? '⚠️ Tipo ya adoptado'
            : companion.isOwned
              ? '✅ Ya adoptado'
              : '¿Adoptar a ${companion.displayName}?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: typeAlreadyOwned || companion.isOwned 
              ? Colors.orange[700]
              : _getCompanionColor(),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // 🔧 MÉTODO PARA OBTENER LA RUTA CORRECTA DE LA IMAGEN
  String _getPetImagePath() {
    final name = '${companion.type.name}_${companion.stage.name}';
    final path = 'assets/images/companions/$name.png';
    debugPrint('🖼️ Intentando cargar imagen: $path');
    return path;
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
  
  // 🔥 INFORMACIÓN DE COMPRA MEJORADA
  Widget _buildPurchaseInfo(bool canAfford, int remainingPoints, bool typeAlreadyOwned) {
    Color containerColor;
    Color borderColor;
    
    if (typeAlreadyOwned || companion.isOwned) {
      containerColor = Colors.orange[50]!;
      borderColor = Colors.orange;
    } else if (canAfford) {
      containerColor = Colors.green[50]!;
      borderColor = Colors.green;
    } else {
      containerColor = Colors.red[50]!;
      borderColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          // 🔥 MENSAJE PRINCIPAL MEJORADO
          if (typeAlreadyOwned) ...[
            _buildTypeAlreadyOwnedInfo(),
          ] else if (companion.isOwned) ...[
            _buildAlreadyOwnedInfo(),
          ] else ...[
            _buildRegularPurchaseInfo(canAfford, remainingPoints),
          ],
        ],
      ),
    );
  }
  
  // 🔥 NUEVO: Info para tipo ya adoptado
  Widget _buildTypeAlreadyOwnedInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ya tienes una mascota ${companion.typeDescription}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solo puedes adoptar una mascota de cada tipo. Tu ${companion.typeDescription} actual puede evolucionar a diferentes etapas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 Consejo: Usa alimentar y dar amor para que tu ${companion.typeDescription} evolucione.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Info para mascota específica ya adoptada
  Widget _buildAlreadyOwnedInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.blue[700],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ya tienes a ${companion.displayName} ${companion.stage.name} en tu colección.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Info para compra regular
  Widget _buildRegularPurchaseInfo(bool canAfford, int remainingPoints) {
    return Column(
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
    );
  }
  
  // 🔥 BOTONES DE ACCIÓN MEJORADOS
  Widget _buildActionButtons(BuildContext context, bool canPurchase, bool typeAlreadyOwned) {
    return Row(
      children: [
        // Botón cancelar
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              debugPrint('❌ Usuario canceló la compra de: ${companion.displayName}');
              Navigator.of(context).pop();
            },
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
        
        // 🔥 BOTÓN PRINCIPAL MEJORADO
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (typeAlreadyOwned || companion.isOwned) {
                debugPrint('❌ Botón presionado pero tipo/mascota ya adoptado');
                Navigator.of(context).pop();
              } else if (canPurchase) {
                debugPrint('✅ Usuario CONFIRMÓ compra de: ${companion.displayName}');
                onConfirm();
              } else {
                debugPrint('❌ Botón adoptar presionado pero no puede comprar');
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(canPurchase, typeAlreadyOwned),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              _getButtonText(canPurchase, typeAlreadyOwned),
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
  
  // 🔥 HELPERS PARA BOTÓN MEJORADOS
  Color _getButtonColor(bool canPurchase, bool typeAlreadyOwned) {
    if (typeAlreadyOwned || companion.isOwned) {
      return Colors.orange;
    } else if (canPurchase) {
      return _getCompanionColor();
    } else {
      return Colors.grey;
    }
  }
  
  String _getButtonText(bool canPurchase, bool typeAlreadyOwned) {
    if (typeAlreadyOwned) {
      return 'Entendido';
    } else if (companion.isOwned) {
      return 'Ya lo tengo';
    } else if (canPurchase) {
      return 'Adoptar';
    } else {
      return 'Sin puntos';
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
}