import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import  '../../../../di/injection.dart';
import '../../domain/entities/companion_entity.dart';
import '../cubit/companion_detail_cubit.dart';
import '../widgets/companion_animation_widget.dart';
import '../widgets/companion_actions_widget.dart';
import '../widgets/companion_evolution_dialog.dart';

class CompanionDetailPage extends StatelessWidget {
  final CompanionEntity companion;
  
  const CompanionDetailPage({
    Key? key,
    required this.companion,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CompanionDetailCubit>()..loadCompanion(companion),
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
    return Scaffold(
      body: BlocConsumer<CompanionDetailCubit, CompanionDetailState>(
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
            
            // Mostrar diálogo de evolución si evolucionó
            if (state.message.contains('evolucionado')) {
              _showEvolutionDialog(context, state.companion);
            }
          }
        },
        builder: (context, state) {
          final currentCompanion = _getCurrentCompanion(state);
          final isLoading = state is CompanionDetailUpdating;
          final currentAction = state is CompanionDetailUpdating ? state.action : null;
          
          return CustomScrollView(
            slivers: [
              // App Bar con imagen de fondo
              _buildSliverAppBar(context, currentCompanion),
              
              // Contenido principal
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Información del compañero
                    _buildCompanionInfo(currentCompanion),
                    
                    // Estadísticas
                    _buildStatsSection(currentCompanion),
                    
                    // Información de evolución
                    if (currentCompanion.canEvolve)
                      _buildEvolutionInfo(currentCompanion),
                    
                    const SizedBox(height: 100), // Espacio para las acciones flotantes
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Acciones flotantes en la parte inferior
      bottomSheet: BlocBuilder<CompanionDetailCubit, CompanionDetailState>(
        builder: (context, state) {
          final currentCompanion = _getCurrentCompanion(state);
          final isLoading = state is CompanionDetailUpdating;
          final currentAction = state is CompanionDetailUpdating ? state.action : null;
          
          return CompanionActionsWidget(
            companion: currentCompanion,
            isLoading: isLoading,
            currentAction: currentAction,
            onFeed: () => context.read<CompanionDetailCubit>().feedCompanion(currentCompanion),
            onLove: () => context.read<CompanionDetailCubit>().loveCompanion(currentCompanion),
            onEvolve: () => context.read<CompanionDetailCubit>().evolveCompanion(currentCompanion),
          );
        },
      ),
    );
  }
  
  CompanionEntity _getCurrentCompanion(CompanionDetailState state) {
    if (state is CompanionDetailLoaded) return state.companion;
    if (state is CompanionDetailUpdating) return state.companion;
    if (state is CompanionDetailSuccess) return state.companion;
    if (state is CompanionDetailError && state.companion != null) return state.companion!;
    return companion;
  }
  
  Widget _buildSliverAppBar(BuildContext context, CompanionEntity currentCompanion) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: _getCompanionColor(currentCompanion.type),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          currentCompanion.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getCompanionColor(currentCompanion.type),
                _getCompanionColor(currentCompanion.type).withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: BlocBuilder<CompanionDetailCubit, CompanionDetailState>(
              builder: (context, state) {
                final isInteracting = state is CompanionDetailUpdating;
                final currentAction = state is CompanionDetailUpdating ? state.action : null;
                
                return CompanionAnimationWidget(
                  companion: currentCompanion,
                  size: 180,
                  isInteracting: isInteracting,
                  currentAction: currentAction,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompanionInfo(CompanionEntity currentCompanion) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentCompanion.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currentCompanion.typeDescription} ${currentCompanion.stageDisplayName}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMoodColor(currentCompanion.currentMood),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMoodIcon(currentCompanion.currentMood),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getMoodText(currentCompanion.currentMood),
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
          
          const SizedBox(height: 16),
          
          Text(
            currentCompanion.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información de nivel y experiencia
          Row(
            children: [
              _buildInfoChip('Nivel', currentCompanion.level.toString(), Icons.star),
              const SizedBox(width: 12),
              _buildInfoChip(
                'Experiencia', 
                '${currentCompanion.experience}/${currentCompanion.experienceNeededForNextStage}',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(CompanionEntity currentCompanion) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildStatBar('Felicidad', currentCompanion.happiness, 100, Colors.yellow),
          const SizedBox(height: 12),
          _buildStatBar('Hambre', currentCompanion.hunger, 100, Colors.orange),
          const SizedBox(height: 12),
          _buildStatBar('Energía', currentCompanion.energy, 100, Colors.blue),
        ],
      ),
    );
  }
  
  Widget _buildStatBar(String label, int value, int maxValue, Color color) {
    final percentage = value / maxValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value/$maxValue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEvolutionInfo(CompanionEntity currentCompanion) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[100]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              const Text(
                '¡Listo para evolucionar!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Tu ${currentCompanion.displayName} ha ganado suficiente experiencia y puede evolucionar a ${currentCompanion.nextStage?.name ?? "la siguiente etapa"}.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.purple[700],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEvolutionDialog(BuildContext context, CompanionEntity evolvedCompanion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompanionEvolutionDialog(
        companion: evolvedCompanion,
        onContinue: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  Color _getCompanionColor(CompanionType type) {
    switch (type) {
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
  
  Color _getMoodColor(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.happy:
        return Colors.green;
      case CompanionMood.excited:
        return Colors.orange;
      case CompanionMood.sad:
        return Colors.blue;
      case CompanionMood.hungry:
        return Colors.red;
      case CompanionMood.sleepy:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getMoodIcon(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.happy:
        return Icons.sentiment_very_satisfied;
      case CompanionMood.excited:
        return Icons.celebration;
      case CompanionMood.sad:
        return Icons.sentiment_dissatisfied;
      case CompanionMood.hungry:
        return Icons.restaurant;
      case CompanionMood.sleepy:
        return Icons.bedtime;
      default:
        return Icons.sentiment_neutral;
    }
  }
  
  String _getMoodText(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.happy:
        return 'Feliz';
      case CompanionMood.excited:
        return 'Emocionado';
      case CompanionMood.sad:
        return 'Triste';
      case CompanionMood.hungry:
        return 'Hambriento';
      case CompanionMood.sleepy:
        return 'Somnoliento';
      default:
        return 'Normal';
    }
  }
}