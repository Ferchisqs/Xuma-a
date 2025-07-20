// lib/features/companion/presentation/widgets/companion_shop_item_widget.dart - CORREGIDO
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
    // 🔧 VERIFICAR SI ES DEXTER JOVEN (YA DESBLOQUEADO)
    final isDexterYoung = _isDexterYoung(companion);
    final canAfford = userPoints >= companion.purchasePrice;
    final isAlreadyOwned = companion.isOwned;
    
    debugPrint('🏪 [SHOP_ITEM] Renderizando: ${companion.displayName}');
    debugPrint('🔧 [SHOP_ITEM] Es Dexter joven: $isDexterYoung');
    debugPrint('💰 [SHOP_ITEM] Puntos usuario: $userPoints, Precio: ${companion.purchasePrice}');
    debugPrint('✅ [SHOP_ITEM] Puede comprar: $canAfford, Ya poseído: $isAlreadyOwned');
    
    return GestureDetector(
      onTap: () {
        if (isDexterYoung) {
          debugPrint('🔧 [SHOP_ITEM] Dexter joven tocado - ya desbloqueado');
          _showAlreadyUnlockedMessage(context);
        } else if (isAlreadyOwned) {
          debugPrint('✅ [SHOP_ITEM] Companion ya poseído');
          _showAlreadyOwnedMessage(context);
        } else if (canAfford) {
          debugPrint('👆 [SHOP_ITEM] Usuario tocó item: ${companion.displayName}');
          debugPrint('🎯 [SHOP_ITEM] Ejecutando onPurchase callback...');
          onPurchase();
        } else {
          debugPrint('❌ [SHOP_ITEM] Usuario tocó item pero no puede comprarlo');
          final faltantes = companion.purchasePrice - userPoints;
          debugPrint('💸 [SHOP_ITEM] Necesita $faltantes puntos más');
          _showInsufficientPointsMessage(context, faltantes);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(isDexterYoung, canAfford, isAlreadyOwned),
          ),
          boxShadow: [
            BoxShadow(
              color: _getShadowColor(isDexterYoung, canAfford, isAlreadyOwned),
              blurRadius: isDexterYoung || canAfford ? 10 : 5,
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
                  _buildStageBadge(isDexterYoung),
                  
                  // Imagen del companion
                  Expanded(
                    flex: 3,
                    child: _buildCompanionImageOnly(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Información del companion
                  _buildCompanionInfo(),
                  
                  const SizedBox(height: 8),
                  
                  // Botón de acción
                  _buildActionButton(context, isDexterYoung, canAfford, isAlreadyOwned),
                ],
              ),
            ),
            
            // Overlays especiales
            ..._buildOverlays(isDexterYoung, canAfford, isAlreadyOwned),
          ],
        ),
      ),
    );
  }
  
  /// Verificar si es Dexter joven
  bool _isDexterYoung(CompanionEntity companion) {
    return companion.type == CompanionType.dexter && 
           companion.stage == CompanionStage.young;
  }
  
  /// Widget para mostrar solo la imagen del companion
  Widget _buildCompanionImageOnly() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            width: constraints.maxWidth * 0.85,
            height: constraints.maxHeight * 0.85,
            child: Image.asset(
              _getPetImagePath(),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('🔧 [SHOP_ITEM] Error loading pet: ${_getPetImagePath()}');
                return _buildPlaceholder();
              },
            ),
          ),
        );
      },
    );
  }
  
  /// Placeholder cuando no se encuentra la imagen
  Widget _buildPlaceholder() {
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
        ],
      ),
    );
  }
  
  /// Badge de etapa con indicadores especiales
  Widget _buildStageBadge(bool isDexterYoung) {
    if (isDexterYoung) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'INICIAL',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
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
  
  /// Información básica del companion
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
  
  /// Botón de acción principal
  Widget _buildActionButton(BuildContext context, bool isDexterYoung, bool canAfford, bool isAlreadyOwned) {
    String buttonText;
    IconData buttonIcon;
    Color? buttonColor;
    
    if (isDexterYoung) {
      buttonText = '¡YA TIENES!';
      buttonIcon = Icons.star;
      buttonColor = Colors.green;
    } else if (isAlreadyOwned) {
      buttonText = 'YA TUYO';
      buttonIcon = Icons.check_circle;
      buttonColor = Colors.blue;
    } else if (canAfford) {
      buttonText = 'ADOPTAR ${companion.purchasePrice}★';
      buttonIcon = Icons.pets;
      buttonColor = _getCompanionColor();
    } else {
      buttonText = 'SIN PUNTOS';
      buttonIcon = Icons.lock;
      buttonColor = Colors.grey[400];
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (isDexterYoung) {
            debugPrint('🔧 [SHOP_ITEM] Botón Dexter joven presionado');
            _showAlreadyUnlockedMessage(context);
          } else if (isAlreadyOwned) {
            debugPrint('✅ [SHOP_ITEM] Botón companion ya poseído presionado');
            _showAlreadyOwnedMessage(context);
          } else if (canAfford) {
            debugPrint('🎯 [SHOP_ITEM] BOTÓN DE COMPRA PRESIONADO: ${companion.displayName}');
            onPurchase();
          } else {
            debugPrint('❌ [SHOP_ITEM] Botón bloqueado presionado: ${companion.displayName}');
            final faltantes = companion.purchasePrice - userPoints;
            _showInsufficientPointsMessage(context, faltantes);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isDexterYoung || canAfford ? 4 : 1,
        ),
        icon: Icon(
          buttonIcon,
          size: 16,
          color: Colors.white,
        ),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  /// Overlays especiales para diferentes estados
  List<Widget> _buildOverlays(bool isDexterYoung, bool canAfford, bool isAlreadyOwned) {
    final overlays = <Widget>[];
    
    // Overlay para Dexter joven (ya desbloqueado)
    if (isDexterYoung) {
      overlays.add(
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  'GRATIS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Overlay para ya poseído
    else if (isAlreadyOwned) {
      overlays.add(
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }
    
    // Overlay para puntos insuficientes
    else if (!canAfford) {
      overlays.add(
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
      );
    }
    
    return overlays;
  }
  
  /// Obtener colores del gradiente según el estado
  List<Color> _getGradientColors(bool isDexterYoung, bool canAfford, bool isAlreadyOwned) {
    if (isDexterYoung) {
      return [Colors.green[300]!, Colors.green[600]!];
    } else if (isAlreadyOwned) {
      return [Colors.blue[300]!, Colors.blue[600]!];
    } else if (canAfford) {
      final baseColor = _getCompanionColor();
      return [baseColor.withOpacity(0.8), baseColor];
    } else {
      return [Colors.grey[400]!, Colors.grey[600]!];
    }
  }
  
  /// Obtener color de sombra según el estado
  Color _getShadowColor(bool isDexterYoung, bool canAfford, bool isAlreadyOwned) {
    if (isDexterYoung) {
      return Colors.green.withOpacity(0.3);
    } else if (isAlreadyOwned) {
      return Colors.blue.withOpacity(0.3);
    } else if (canAfford) {
      return Colors.black.withOpacity(0.15);
    } else {
      return Colors.black.withOpacity(0.05);
    }
  }
  
  /// Mostrar mensaje para Dexter joven
  void _showAlreadyUnlockedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.star, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡${companion.displayName} es tu primer compañero! Ya lo tienes desbloqueado.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Mostrar mensaje para companion ya poseído
  void _showAlreadyOwnedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ya tienes a ${companion.displayName} en tu colección.'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Mostrar mensaje de puntos insuficientes
  void _showInsufficientPointsMessage(BuildContext context, int faltantes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Te faltan $faltantes puntos para adoptar a ${companion.displayName}.',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Métodos helper para estilos
  String _getPetImagePath() {
    final name = '${companion.type.name}_${companion.stage.name}';
    return 'assets/images/companions/$name.png';
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
}