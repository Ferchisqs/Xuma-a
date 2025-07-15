// lib/features/navigation/presentation/widgets/custom_app_bar.dart - VERSIÓN ACTUALIZADA CON API
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
    
    // BOTÓN DE INFORMACIÓN ESPECÍFICA
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
    
    // 🆕 BOTÓN ECO TIP CON API
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

  // 🆕 MÉTODO ACTUALIZADO CON CUBIT DE TIPS
  void _showEcoTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => getIt<TipsCubit>()..getRandomTip(),
        child: Dialog(
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
            child: BlocBuilder<TipsCubit, TipsState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con estado dinámico
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.earthGradient,
                        shape: BoxShape.circle,
                      ),
                      child: _buildTipIcon(state),
                    ),
                    const SizedBox(height: 16),
                    
                    // Título
                    Text(
                      'Consejo de Xico',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 🆕 CONTENIDO DINÁMICO BASADO EN ESTADO
                    _buildTipContent(context, state),
                    
                    const SizedBox(height: 20),
                    
                    // Botones
                    _buildTipActions(context, state, dialogContext),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 CONSTRUIR ICONO SEGÚN ESTADO
  Widget _buildTipIcon(TipsState state) {
    if (state is TipsLoading) {
      return const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else if (state is TipsError) {
      return const Icon(
        Icons.warning_rounded,
        color: Colors.white,
        size: 30,
      );
    } else {
      return const Icon(
        Icons.pets,
        color: Colors.white,
        size: 30,
      );
    }
  }

  // 🆕 CONSTRUIR CONTENIDO SEGÚN ESTADO
  Widget _buildTipContent(BuildContext context, TipsState state) {
    if (state is TipsLoading) {
      return Column(
        children: [
          Text(
            state.message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      );
    } else if (state is TipsError) {
      return Column(
        children: [
          Text(
            'Ups, no pude obtener un consejo nuevo',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getFallbackTip(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (state is TipsLoaded && state.currentTip != null) {
      final tip = state.currentTip!;
      return Column(
        children: [
          // Mostrar categoría si está disponible
          if (tip.category.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tip.category.toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Contenido del tip
          Text(
            tip.formattedContent,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Indicador si hay más tips
          if (state.tips.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              '${state.currentIndex + 1} de ${state.tips.length}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      );
    } else {
      return Text(
        _getFallbackTip(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  // 🆕 CONSTRUIR ACCIONES SEGÚN ESTADO
  Widget _buildTipActions(BuildContext context, TipsState state, BuildContext dialogContext) {
    return Row(
      children: [
        // Botón para obtener otro tip
        if (state is TipsLoaded && state.tips.length > 1) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                context.read<TipsCubit>().nextTip();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Otro',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Botón para reintentar si hay error
        if (state is TipsError) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                context.read<TipsCubit>().getRandomTip();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Reintentar',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Botón principal
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
    );
  }

  // Tip de respaldo para cuando falla la API
  String _getFallbackTip() {
    final tips = [
      '💡 Apaga luces y dispositivos que no uses. ¡Pequeños cambios, gran impacto!',
      '🚿 Cierra la llave mientras te cepillas los dientes. Ahorras hasta 6 litros por minuto.',
      '♻️ Separa tu basura: orgánica, inorgánica y reciclables. ¡La Tierra te lo agradece!',
      '🌱 Planta una semilla hoy. En el futuro será un árbol que purifique el aire.',
      '🚗 Camina, usa bici o transporte público. ¡Tu planeta y tu salud lo agradecerán!',
    ];
    
    return tips[(DateTime.now().millisecond / 100).floor() % tips.length];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}