import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/companion_entity.dart';
import '../cubit/companion_detail_cubit.dart';
import '../cubit/companion_actions_cubit.dart'; // 🆕 IMPORTAR ACTIONS CUBIT
import '../widgets/companion_animation_widget.dart';
import '../widgets/companion_evolution_dialog.dart';
import '../widgets/companion_info_dialog.dart';

class CompanionDetailPage extends StatelessWidget {
  final CompanionEntity companion;

  const CompanionDetailPage({
    Key? key,
    required this.companion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<CompanionDetailCubit>()..loadCompanion(companion),
        ),
        // 🆕 AGREGAR ACTIONS CUBIT PARA ACCIONES REALES
        BlocProvider(
          create: (context) => getIt<CompanionActionsCubit>(),
        ),
      ],
      child: _CompanionDetailView(companion: companion),
    );
  }
}

// 🔧 REEMPLAZAR _CompanionDetailView con listeners para ambos cubits
class _CompanionDetailView extends StatelessWidget {
  final CompanionEntity companion;

  const _CompanionDetailView({
    Key? key,
    required this.companion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener para CompanionDetailCubit (acciones locales)
        BlocListener<CompanionDetailCubit, CompanionDetailState>(
          listener: (context, state) {
            if (state is CompanionDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is CompanionDetailSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );

              if (state.message.contains('evolucionado')) {
                _showEvolutionDialog(context, state.companion);
              }
            }
          },
        ),
        // 🆕 Listener para CompanionActionsCubit (acciones API)
        BlocListener<CompanionActionsCubit, CompanionActionsState>(
          listener: (context, state) {
            if (state is CompanionActionsSuccess) {
              debugPrint('✅ [DETAIL] Acción API exitosa: ${state.action}');
              
              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(_getActionIcon(state.action), color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              // Actualizar el companion en DetailCubit
              context.read<CompanionDetailCubit>().loadCompanion(state.companion);
              
              // Mostrar diálogo de evolución si aplica
              if (state.action == 'evolving') {
                _showEvolutionDialog(context, state.companion);
              }
              
            } else if (state is CompanionActionsError) {
              debugPrint('❌ [DETAIL] Error API: ${state.message}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<CompanionDetailCubit, CompanionDetailState>(
          builder: (context, state) {
            final currentCompanion = _getCurrentCompanion(state);
            final isLoading = state is CompanionDetailUpdating;
            final currentAction = state is CompanionDetailUpdating ? state.action : null;

            // 🔧 TAMBIÉN VERIFICAR SI ACTIONS CUBIT ESTÁ CARGANDO
            return BlocBuilder<CompanionActionsCubit, CompanionActionsState>(
              builder: (context, actionsState) {
                final isApiActionLoading = actionsState is CompanionActionsLoading;
                final apiCurrentAction = actionsState is CompanionActionsLoading 
                  ? actionsState.action 
                  : null;

                final finalIsLoading = isLoading || isApiActionLoading;
                final finalCurrentAction = currentAction ?? apiCurrentAction;

                return Stack(
                  children: [
                    Column(
                      children: [
                        // 🔧 APP BAR CON BOTÓN DE INFORMACIÓN
                        _buildCustomAppBar(context, currentCompanion),

                        // ÁREA PRINCIPAL DE LA MASCOTA
                        Expanded(
                          child: _buildPetMainArea(
                            currentCompanion, 
                            finalIsLoading, 
                            finalCurrentAction
                          ),
                        ),
                      ],
                    ),

                    // ACCIONES FLOTANTES EN LA PARTE INFERIOR
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildFloatingActions(
                        context, 
                        currentCompanion, 
                        finalIsLoading, 
                        finalCurrentAction
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(
      BuildContext context, CompanionEntity currentCompanion) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Botón back
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              const Spacer(),

              // Título
              Text(
                'COMPAÑERO',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const Spacer(),

              // 🆕 BOTÓN DE INFORMACIÓN CON DATOS CURIOSOS Y DEDICATORIA
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.info_outline,
                      color: Colors.blue, size: 20),
                  onPressed: () =>
                      _showCompanionInfo(context, currentCompanion),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetMainArea(
      CompanionEntity currentCompanion, bool isLoading, String? currentAction) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // 🔧 YA NO HAY GRADIENTE, SE USA TU IMAGEN DE FONDO
      ),
      child: Stack(
        children: [
          // Badge con nombre en la parte superior
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentCompanion.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Puntos en la esquina superior derecha
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '100',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.star, color: Colors.yellow[600], size: 16),
                ],
              ),
            ),
          ),

          // 🔧 MASCOTA CON TU FONDO DE IMAGEN
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 20),
              child: BlocBuilder<CompanionDetailCubit, CompanionDetailState>(
                builder: (context, state) {
                  final isInteracting = state is CompanionDetailUpdating;
                  final currentAction =
                      state is CompanionDetailUpdating ? state.action : null;

                  return CompanionAnimationWidget(
                    companion: currentCompanion,
                    size: MediaQuery.of(context).size.width * 0.8,
                    isInteracting: isInteracting,
                    currentAction: currentAction,
                    showBackground:
                        true, // 🆕 CON FONDO EN LA PÁGINA DE DETALLE
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 ACCIONES FLOTANTES USANDO ACTIONS CUBIT REAL
  Widget _buildFloatingActions(BuildContext context,
      CompanionEntity currentCompanion, bool isLoading, String? currentAction) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón Alimentar (LOCAL)
          _buildActionButton(
            icon: Icons.restaurant,
            color: Colors.green,
            onPressed: currentCompanion.needsFood && !isLoading
                ? () => context
                    .read<CompanionDetailCubit>()
                    .feedCompanion(currentCompanion)
                : null,
            isActive: currentAction == 'feeding',
            disabled: !currentCompanion.needsFood, // Added disabled property based on needsFood
          ),

          // Botón Dar Amor (LOCAL)
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.green,
            onPressed: currentCompanion.needsLove && !isLoading
                ? () => context
                    .read<CompanionDetailCubit>()
                    .loveCompanion(currentCompanion)
                : null,
            isActive: currentAction == 'loving',
            disabled: !currentCompanion.needsLove, // Added disabled property based on needsLove
          ),

          // 🔥 Botón Evolucionar (API REAL)
          _buildActionButton(
            icon: Icons.auto_awesome,
            color: Colors.purple,
            onPressed: currentCompanion.canEvolve && !isLoading
                ? () => context
                    .read<CompanionActionsCubit>()
                    .evolveCompanion(currentCompanion)
                : null,
            isActive: currentAction == 'evolving',
            disabled: !currentCompanion.canEvolve,
          ),

          // 🆕 Botón Activar/Destacar (API REAL)
          _buildActionButton(
            icon: currentCompanion.isSelected ? Icons.star : Icons.star_outline,
            color: Colors.orange,
            onPressed: !isLoading
                ? () => context
                    .read<CompanionActionsCubit>()
                    .featureCompanion(currentCompanion)
                : null,
            isActive: currentAction == 'featuring',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isActive = false,
    bool disabled = false, // Added disabled parameter
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: disabled
            ? Colors.grey[300] // Grey out if disabled
            : isActive
                ? color.withOpacity(0.8)
                : color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: isActive
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }

  // Helper methods
  IconData _getActionIcon(String action) {
    switch (action) {
      case 'feeding':
        return Icons.restaurant;
      case 'loving':
        return Icons.favorite;
      case 'evolving':
        return Icons.auto_awesome;
      case 'featuring':
        return Icons.star;
      default:
        return Icons.check;
    }
  }

  // 🆕 MOSTRAR INFORMACIÓN DE LA MASCOTA
  void _showCompanionInfo(BuildContext context, CompanionEntity companion) {
    showDialog(
      context: context,
      builder: (context) => CompanionInfoDialog(companion: companion),
    );
  }

  CompanionEntity _getCurrentCompanion(CompanionDetailState state) {
    if (state is CompanionDetailLoaded) return state.companion;
    if (state is CompanionDetailUpdating) return state.companion;
    if (state is CompanionDetailSuccess) return state.companion;
    if (state is CompanionDetailError && state.companion != null)
      return state.companion!;
    return companion;
  }

  void _showEvolutionDialog(
      BuildContext context, CompanionEntity evolvedCompanion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompanionEvolutionDialog(
        companion: evolvedCompanion,
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }
}