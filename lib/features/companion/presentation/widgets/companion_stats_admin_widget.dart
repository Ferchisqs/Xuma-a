// lib/features/companion/presentation/widgets/companion_stats_admin_widget.dart
// 🔧 WIDGET PARA ADMINISTRAR ESTADÍSTICAS (TESTING)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/companion_entity.dart';
import '../cubit/companion_actions_cubit.dart';

class CompanionStatsAdminWidget extends StatelessWidget {
  final CompanionEntity companion;
  
  const CompanionStatsAdminWidget({
    Key? key,
    required this.companion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del panel
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.blue[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panel de Administración',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                    Text(
                      'Gestionar estadísticas de ${companion.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Estadísticas actuales
          _buildCurrentStats(),
          
          const SizedBox(height: 20),
          
          // Controles de administración
          _buildAdminControls(context),
          
          const SizedBox(height: 16),
          
          // Acciones rápidas
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildCurrentStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas Actuales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Barras de estadísticas
          _buildStatBar('Felicidad', companion.happiness, Colors.pink),
          const SizedBox(height: 8),
          _buildStatBar('Salud', companion.hunger, Colors.green),
          const SizedBox(height: 8),
          _buildStatBar('Energía', companion.energy, Colors.blue),
          
          const SizedBox(height: 12),
          
          // Info adicional
          Row(
            children: [
              _buildStatChip('Nivel ${companion.level}', Colors.purple),
              const SizedBox(width: 8),
              _buildStatChip('EXP: ${companion.experience}', Colors.orange),
              const SizedBox(width: 8),
              _buildStatChip(companion.currentMood.name.toUpperCase(), Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
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
              '$value/100',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
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

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAdminControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Controles Manuales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Botones de reducir estadísticas
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context,
                  'Reducir Felicidad (-10)',
                  Icons.sentiment_dissatisfied,
                  Colors.red,
                  () => context.read<CompanionActionsCubit>().decreaseCompanionStats(
                    companion,
                    happiness: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  context,
                  'Reducir Salud (-15)',
                  Icons.health_and_safety,
                  Colors.red,
                  () => context.read<CompanionActionsCubit>().decreaseCompanionStats(
                    companion,
                    health: 15,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Botones de aumentar estadísticas
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  context,
                  'Aumentar Felicidad (+10)',
                  Icons.sentiment_very_satisfied,
                  Colors.green,
                  () => context.read<CompanionActionsCubit>().increaseCompanionStats(
                    companion,
                    happiness: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  context,
                  'Aumentar Salud (+15)',
                  Icons.local_hospital,
                  Colors.green,
                  () => context.read<CompanionActionsCubit>().increaseCompanionStats(
                    companion,
                    health: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Simular Tiempo',
            Icons.schedule,
            Colors.blue,
            () => context.read<CompanionActionsCubit>().simulateTimePassage(companion),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Alimentar API',
            Icons.restaurant,
            Colors.orange,
            () => context.read<CompanionActionsCubit>().feedCompanionViaApi(companion),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Amor API',
            Icons.favorite,
            Colors.pink,
            () => context.read<CompanionActionsCubit>().loveCompanionViaApi(companion),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔧 EJEMPLO DE CÓMO USAR EL WIDGET EN UNA PÁGINA

class CompanionStatsTestPage extends StatelessWidget {
  final CompanionEntity companion;
  
  const CompanionStatsTestPage({
    Key? key,
    required this.companion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing - Estadísticas'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: BlocListener<CompanionActionsCubit, CompanionActionsState>(
        listener: (context, state) {
          if (state is CompanionActionsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CompanionActionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Panel de administración
              CompanionStatsAdminWidget(companion: companion),
              
              // Información adicional
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Información de Testing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Use "Simular Tiempo" para reducir las estadísticas y poder probar alimentar/amor\n'
                      '• Los botones de control manual permiten ajustar stats específicas\n'
                      '• "Alimentar API" y "Amor API" usan los endpoints reales de tu backend\n'
                      '• Las estadísticas se actualizan automáticamente tras cada acción',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}