import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xuma_a/features/companion/presentation/cubit/companion_shop_cubit.dart';
import '../../../../di/injection.dart';

class AdoptionTestWidget extends StatelessWidget {
  const AdoptionTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Test de Adopción - API Real',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Prueba la adopción con tu API real usando el Pet ID correcto:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón de test con Pet ID real
          _buildTestButton(
            context,
            'Test Dexter Baby',
            '51a56248-17b5-4861-af11-335f9724f9eb', // 🔧 TU PET ID REAL
            Colors.brown,
          ),
          
          const SizedBox(height: 8),
          
          // Más botones de test para otros pets
          _buildTestButton(
            context,
            'Test Pet Genérico',
            'afdfcdfa-aed6-4320-a8e5-51debbd1bccf', // Pet ID de tu CURL
            Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          // Información de debugging
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Info:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Endpoint: /api/gamification/pets/{petId}/adopt',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  '• Método: POST',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  '• Body: {"petId": "...", "nickname": "..."}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  '• Header: Authorization: Bearer {token}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String label,
    String petId,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _testAdoption(context, petId, label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.pets, size: 18),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'ID: ${petId.substring(0, 8)}...',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testAdoption(BuildContext context, String petId, String label) {
    debugPrint('🧪 [TEST_WIDGET] === INICIANDO TEST DE ADOPCIÓN ===');
    debugPrint('🧪 [TEST_WIDGET] Label: $label');
    debugPrint('🧪 [TEST_WIDGET] Pet ID: $petId');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.science, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Test de Adopción'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Probar adopción con tu API real?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pet ID:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    petId,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esto hará una petición POST real a tu API de gamificación.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // 🚀 EJECUTAR TEST REAL
              debugPrint('🚀 [TEST_WIDGET] Ejecutando test real...');
              
              // Crear el cubit para testing
              final shopCubit = getIt<CompanionShopCubit>();
              shopCubit.testAdoptionWithRealApi(petId);
              
              // Mostrar resultado
              _showTestResult(context, label, petId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Probar'),
          ),
        ],
      ),
    );
  }

  void _showTestResult(BuildContext context, String label, String petId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider(
        create: (context) => getIt<CompanionShopCubit>()..testAdoptionWithRealApi(petId),
        child: BlocConsumer<CompanionShopCubit, CompanionShopState>(
          listener: (context, state) {
            if (state is CompanionShopPurchaseSuccess) {
              // Auto-cerrar después de éxito
              Future.delayed(const Duration(seconds: 3), () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
            } else if (state is CompanionShopError) {
              // Mantener abierto para ver el error
            }
          },
          builder: (context, state) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    _getStateIcon(state),
                    color: _getStateColor(state),
                  ),
                  const SizedBox(width: 8),
                  Text('Resultado: $label'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state is CompanionShopLoading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Enviando petición a la API...'),
                    const SizedBox(height: 8),
                    Text(
                      'POST /api/gamification/pets/$petId/adopt',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ] else if (state is CompanionShopPurchaseSuccess) ...[
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '¡Adopción Exitosa!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 8),
                    Text(
                      'Mascota: ${state.purchasedCompanion.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ] else if (state is CompanionShopError) ...[
                    Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error en Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                  ],
                ],
              ),
              actions: [
                if (state is! CompanionShopLoading)
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
  }

  IconData _getStateIcon(CompanionShopState state) {
    if (state is CompanionShopLoading) return Icons.hourglass_empty;
    if (state is CompanionShopPurchaseSuccess) return Icons.check_circle;
    if (state is CompanionShopError) return Icons.error;
    return Icons.help;
  }

  Color _getStateColor(CompanionShopState state) {
    if (state is CompanionShopLoading) return Colors.blue;
    if (state is CompanionShopPurchaseSuccess) return Colors.green;
    if (state is CompanionShopError) return Colors.red;
    return Colors.grey;
  }
}