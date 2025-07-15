// lib/features/navigation/presentation/widgets/custom_app_bar.dart - SIN CONSEJOS POR DEFECTO
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
    
    // BOTÓN ECO TIP CON API
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

  // MÉTODO SIMPLIFICADO SIN FALLBACK
  void _showEcoTipDialog(BuildContext context) {
    try {
      // Obtener el TipsCubit del inyector de dependencias
      final tipsCubit = getIt<TipsCubit>();
      
      showDialog(
        context: context,
        builder: (context) => BlocProvider.value(
          value: tipsCubit,
          child: BlocBuilder<TipsCubit, TipsState>(
            builder: (context, state) {
              return AlertDialog(
                title: const Text('Consejo de Xico'),
                content: _buildTipContent(state),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          ),
        ),
      );
      
      // Cargar un tip aleatorio al mostrar el diálogo
      tipsCubit.getRandomTip();
    } catch (e) {
      print('❌ Error showing eco tip dialog: $e');
      // Mostrar diálogo simple sin consejo
      _showNoTipDialog(context);
    }
  }

  // DIÁLOGO SIMPLE CUANDO NO HAY SERVICIO
  void _showNoTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consejo de Xico'),
        content: const Text('Sin consejos del día'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // CONSTRUIR CONTENIDO SEGÚN ESTADO
  Widget _buildTipContent(TipsState state) {
    if (state is TipsLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (state is TipsLoaded && state.currentTip != null) {
      final tip = state.currentTip!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(tip.formattedContent),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tip.category.toUpperCase(),
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
    
    if (state is TipsError) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 48),
          SizedBox(height: 8),
          Text(
            'Sin consejos del día',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
    
    return const Text('Cargando consejo...');
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}