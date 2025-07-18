// lib/features/navigation/presentation/widgets/custom_app_bar.dart - VERSIÓN MEJORADA CON TIPS
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../tips/presentation/cubit/tips_cubit.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDrawerButton;
  final VoidCallback? onBackPressed;
  final bool showEcoTip;
  final VoidCallback? onInfoPressed;
  final bool showInfoButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showDrawerButton = true, 
    this.onBackPressed,
    this.showEcoTip = true,
    this.onInfoPressed,
    this.showInfoButton = false,
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
        leading: leading ?? (showDrawerButton ? null : _buildBackButton(context)),
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

  Widget? _buildBackButton(BuildContext context) {
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

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actionsList = [];
    
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
    
    // 🔧 BOTÓN ECO TIP MEJORADO
    if (showEcoTip) {
      actionsList.add(
        IconButton(
          icon: const Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            _showImprovedEcoTipDialog(context);
          },
        ),
      );
    }
    
    if (actions != null) {
      actionsList.addAll(actions!);
    }
    
    return actionsList;
  }

  void _showImprovedEcoTipDialog(BuildContext context) {
    try {
      final tipsCubit = getIt<TipsCubit>();
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => BlocProvider.value(
          value: tipsCubit,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: BlocBuilder<TipsCubit, TipsState>(
                builder: (context, state) {
                  return _buildImprovedTipContent(context, state);
                },
              ),
            ),
          ),
        ),
      );
      
      tipsCubit.getRandomTip();
    } catch (e) {
      print('❌ Error showing eco tip dialog: $e');
      _showNoTipDialog(context);
    }
  }

  // 🆕 CONTENIDO MEJORADO DEL DIÁLOGO
  Widget _buildImprovedTipContent(BuildContext context, TipsState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header con título e icono de lamparita
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consejo de Xico',
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tu compañero ecológico',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        
        // Contenido del tip
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildTipContentBody(state),
        ),
        
        // Botones de acción
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _buildTipActions(context, state),
        ),
      ],
    );
  }

  // 🆕 CUERPO DEL CONTENIDO DEL TIP
  Widget _buildTipContentBody(TipsState state) {
    if (state is TipsLoading) {
      return Container(
        height: 120,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 12),
              Text(
                'Xico está preparando un consejo...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (state is TipsLoaded && state.currentTip != null) {
      final tip = state.currentTip!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🆕 TÍTULO DEL CONSEJO
          Row(
            children: [
              Text(
                tip.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip.title,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 🆕 DESCRIPCIÓN DEL CONSEJO
          Text(
            tip.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 🆕 CATEGORÍA
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              tip.category.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mensaje motivacional fijo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡Pequeños cambios, gran impacto!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    if (state is TipsError) {
      return Container(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.textHint,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin consejos disponibles',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Intenta más tarde',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox(height: 120);
  }

  // 🆕 BOTONES DE ACCIÓN
  Widget _buildTipActions(BuildContext context, TipsState state) {
    return Row(
      children: [
        // Botón para otro consejo
  
        if (state is TipsLoaded && state.currentTip != null)
          const SizedBox(width: 12),
        
        // Botón cerrar
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Entendido'),
          ),
        ),
      ],
    );
  }

  // DIÁLOGO SIMPLE CUANDO NO HAY SERVICIO
  void _showNoTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consejo de Xico'),
        content: const Text('Sin consejos disponibles en este momento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}