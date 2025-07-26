// lib/features/companion/presentation/pages/companion_detail_page.dart - ACTUALIZADO

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/companion_entity.dart';
import '../cubit/companion_detail_cubit.dart';
import '../cubit/companion_actions_cubit.dart'; 
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
        BlocProvider(
          create: (context) => getIt<CompanionActionsCubit>(),
        ),
      ],
      child: _CompanionDetailView(companion: companion),
    );
  }
}

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
        BlocListener<CompanionActionsCubit, CompanionActionsState>(
          listener: (context, state) {
            if (state is CompanionActionsSuccess) {
              debugPrint('✅ [DETAIL] Acción API exitosa: ${state.action}');
              
              // Mostrar mensaje de éxito con icono específico
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(_getActionIcon(state.action), color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: _getActionColor(state.action),
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
                        // APP BAR CON BOTÓN DE INFORMACIÓN
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

              // 🆕 BOTÓN DE SIMULAR TIEMPO
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.schedule,
                      color: Colors.orange, size: 20),
                  onPressed: () => _showTimeSimulationDialog(context, currentCompanion),
                  tooltip: 'Simular Tiempo',
                ),
              ),
              
              const SizedBox(width: 8),

              // BOTÓN DE INFORMACIÓN
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
      ),
      child: Stack(
        children: [
          // Badge con nombre y estadísticas en la parte superior
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge con nombre
                Container(
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
                
                // 🆕 ESTADÍSTICAS DETALLADAS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Felicidad
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatColor(currentCompanion.happiness),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${currentCompanion.happiness}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Salud/Hambre
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatColor(currentCompanion.hunger),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${currentCompanion.hunger}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // MASCOTA CON FONDO
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 20),
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
                    showBackground: true,
                  );
                },
              ),
            ),
          ),
          
          // 🆕 INDICADOR DE ESTADO EN LA PARTE INFERIOR
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: _buildStatusIndicator(currentCompanion),
          ),
        ],
      ),
    );
  }

  // 🆕 INDICADOR DE ESTADO DE LA MASCOTA
  Widget _buildStatusIndicator(CompanionEntity companion) {
    String statusMessage;
    Color statusColor;
    IconData statusIcon;
    
    if (companion.needsFood && companion.needsLove) {
      statusMessage = '${companion.displayName} necesita comida y amor';
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (companion.needsFood) {
      statusMessage = '${companion.displayName} tiene hambre';
      statusColor = Colors.orange;
      statusIcon = Icons.restaurant;
    } else if (companion.needsLove) {
      statusMessage = '${companion.displayName} necesita cariño';
      statusColor = Colors.pink;
      statusIcon = Icons.favorite_border;
    } else if (companion.canEvolve) {
      statusMessage = '¡${companion.displayName} puede evolucionar!';
      statusColor = Colors.purple;
      statusIcon = Icons.auto_awesome;
    } else {
      statusMessage = '${companion.displayName} está feliz';
      statusColor = Colors.green;
      statusIcon = Icons.sentiment_very_satisfied;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ACCIONES FLOTANTES ACTUALIZADAS
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
        // 🔥 Botón Alimentar CORREGIDO
        _buildActionButton(
          icon: Icons.restaurant,
          color: Colors.green,
          onPressed: (currentCompanion.hunger < 95) && !isLoading  // ✅ CAMBIAR DE 90 A 95
              ? () {
                  debugPrint('🍎 [DETAIL] Alimentando via API - Salud actual: ${currentCompanion.hunger}');
                  context
                      .read<CompanionActionsCubit>()
                      .feedCompanionViaApi(currentCompanion);
                }
              : null,
          isActive: currentAction == 'feeding',
          disabled: currentCompanion.hunger >= 95, // ✅ CAMBIAR VALIDACIÓN
          label: 'Alimentar',
        ),

        // 🔥 Botón Dar Amor CORREGIDO
        _buildActionButton(
          icon: Icons.favorite,
          color: Colors.pink,
          onPressed: (currentCompanion.happiness < 95) && !isLoading  // ✅ CAMBIAR DE 90 A 95
              ? () {
                  debugPrint('💖 [DETAIL] Dando amor via API - Felicidad actual: ${currentCompanion.happiness}');
                  context
                      .read<CompanionActionsCubit>()
                      .loveCompanionViaApi(currentCompanion);
                }
              : null,
          isActive: currentAction == 'loving',
          disabled: currentCompanion.happiness >= 95, // ✅ CAMBIAR VALIDACIÓN
          label: 'Amor',
        ),

        // Botón Evolucionar (mantener igual)
        _buildActionButton(
          icon: Icons.auto_awesome,
          color: Colors.purple,
          onPressed: currentCompanion.canEvolve && !isLoading
              ? () {
                  debugPrint('🦋 [DETAIL] Evolucionando via API');
                  context
                      .read<CompanionActionsCubit>()
                      .evolveCompanion(currentCompanion);
                }
              : null,
          isActive: currentAction == 'evolving',
          disabled: !currentCompanion.canEvolve,
          label: 'Evolucionar',
        ),

        // Botón Activar/Destacar (mantener igual)
        _buildActionButton(
          icon: currentCompanion.isSelected ? Icons.star : Icons.star_outline,
          color: Colors.orange,
          onPressed: !isLoading
              ? () {
                  debugPrint('⭐ [DETAIL] Destacando via API');
                  context
                      .read<CompanionActionsCubit>()
                      .featureCompanion(currentCompanion);
                }
              : null,
          isActive: currentAction == 'featuring',
          label: 'Activar',
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
    bool disabled = false,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: disabled
                ? Colors.grey[300]
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
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: disabled ? Colors.grey[600] : color,
          ),
        ),
      ],
    );
  }

  // 🆕 DIÁLOGO DE SIMULACIÓN DE TIEMPO
  void _showTimeSimulationDialog(BuildContext context, CompanionEntity companion) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Simular Tiempo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esto reducirá las estadísticas de ${companion.displayName} para simular el paso del tiempo.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cambios:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Felicidad: ${companion.happiness} → ${(companion.happiness - 5).clamp(10, 100)}'),
                  Text('• Salud: ${companion.hunger} → ${(companion.hunger - 8).clamp(10, 100)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
         
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatColor(int value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    if (value >= 40) return Colors.red[400]!;
    return Colors.red;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'feeding':
        return Colors.green;
      case 'loving':
        return Colors.pink;
      case 'evolving':
        return Colors.purple;
      case 'featuring':
        return Colors.orange;
      case 'simulating':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

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
      case 'simulating':
        return Icons.schedule;
      default:
        return Icons.check;
    }
  }

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