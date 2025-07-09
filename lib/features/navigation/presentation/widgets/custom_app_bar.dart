import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDrawerButton;
  final VoidCallback? onBackPressed;
  final bool showEcoTip;
  final VoidCallback? onInfoPressed; // 🆕 CALLBACK PARA INFORMACIÓN
  final bool showInfoButton; // 🆕 MOSTRAR BOTÓN DE INFO

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showDrawerButton = true, 
    this.onBackPressed,
    this.showEcoTip = true,
    this.onInfoPressed, // 🆕
    this.showInfoButton = false, // 🆕
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.earthGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: showDrawerButton,
        leading: _buildLeading(context),
        title: Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: _buildActions(context),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    
    if (!showDrawerButton) {
      if (Navigator.of(context).canPop()) {
        return IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
          ),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        );
      }
      return null;
    }
    
    return Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            debugPrint('🔧 Intentando abrir drawer...');
            final scaffoldState = Scaffold.of(context);
            if (scaffoldState.hasDrawer) {
              debugPrint('✅ Drawer encontrado, abriendo...');
              scaffoldState.openDrawer();
            } else {
              debugPrint('❌ No se encontró drawer en el scaffold');
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actionsList = [];
    
    // 🆕 BOTÓN DE INFORMACIÓN ESPECÍFICA (DATOS CURIOSOS + DEDICATORIA)
    if (showInfoButton && onInfoPressed != null) {
      actionsList.add(
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: onInfoPressed,
        ),
      );
    }
    
    // BOTÓN ECO TIP GENERAL
    if (showEcoTip) {
      actionsList.add(
        IconButton(
          icon: const Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            _showEcoTipDialog(context);
          },
        ),
      );
    }
    
    if (actions != null) {
      actionsList.addAll(actions!);
    }
    
    return actionsList;
  }

  void _showEcoTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.earthGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Consejo de Xico',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                _getRandomEcoTip(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Gracias, Xico',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRandomEcoTip() {
    final tips = [
      '💡 Apaga luces y dispositivos que no uses. ¡Pequeños cambios, gran impacto!',
      '🚿 Cierra la llave mientras te cepillas los dientes. Ahorras hasta 6 litros por minuto.',
      '♻️ Separa tu basura: orgánica, inorgánica y reciclables. ¡La Tierra te lo agradece!',
      '🌱 Planta una semilla hoy. En el futuro será un árbol que purifique el aire.',
      '🚗 Camina, usa bici o transporte público. ¡Tu planeta y tu salud lo agradecerán!',
      '📱 Antes de comprar algo nuevo, pregúntate: ¿realmente lo necesito?',
      '🌊 Usa una botella reutilizable. Evitas comprar 1,460 botellas de plástico al año.',
      '🍎 Come más frutas y verduras locales. Reducirás tu huella de carbono.',
    ];
    
    return tips[(DateTime.now().millisecond / 100).floor() % tips.length];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}