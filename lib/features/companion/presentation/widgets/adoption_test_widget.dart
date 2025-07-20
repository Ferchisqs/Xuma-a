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
      child: BlocBuilder<CompanionShopCubit, CompanionShopState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Test de Adopción - Pet IDs DINÁMICOS',
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
                'Prueba la adopción con Pet IDs reales obtenidos de tu API:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 🆕 BOTONES DINÁMICOS BASADOS EN LA API
              if (state is CompanionShopLoaded) ...[
                _buildDynamicTestButtons(context, state),
              ] else if (state is CompanionShopLoading) ...[
                _buildLoadingView(),
              ] else if (state is CompanionShopError) ...[
                _buildErrorView(context, state.message),
              ] else ...[
                _buildInitialView(context),
              ],
              
              const SizedBox(height: 16),
              
              // Información de debugging
              _buildDebugInfo(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicTestButtons(BuildContext context, CompanionShopLoaded state) {
    final availablePetIds = state.availablePetIds;
    
    if (availablePetIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(height: 8),
            Text(
              'No se encontraron Pet IDs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La API no devolvió Pet IDs válidos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Botón para test genérico con el primer Pet ID disponible
        _buildGenericTestButton(context, availablePetIds),
        
        const SizedBox(height: 12),
        
        // Lista de Pet IDs disponibles
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Pet IDs encontrados desde API:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              ...availablePetIds.entries.take(3).map((entry) {
                final localId = entry.key;
                final petId = entry.value;
                return _buildPetIdRow(context, localId, petId);
              }).toList(),
              
              if (availablePetIds.length > 3) ...[
                const SizedBox(height: 4),
                Text(
                  '... y ${availablePetIds.length - 3} más',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildGenericTestButton(BuildContext context, Map<String, String> availablePetIds) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _testWithDynamicPetId(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.science, size: 18),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test con Pet ID de la API',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${availablePetIds.length} Pet IDs disponibles',
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

  Widget _buildPetIdRow(BuildContext context, String localId, String petId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              localId,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              '${petId.substring(0, 8)}...',
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'monospace',
                color: Colors.green[600],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _testSpecificPetId(context, petId, localId),
            icon: Icon(
              Icons.play_arrow,
              size: 16,
              color: Colors.green[600],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Obteniendo Pet IDs desde la API...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error, color: Colors.red[600]),
          const SizedBox(height: 8),
          Text(
            'Error obteniendo Pet IDs',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<CompanionShopCubit>().loadShop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            'Carga la tienda primero',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Los Pet IDs se obtendrán dinámicamente',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<CompanionShopCubit>().loadShop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cargar Tienda',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo(CompanionShopState state) {
    return Container(
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
            '• Estado actual: ${state.runtimeType}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          Text(
            '• Endpoint: POST /api/gamification/pets/{petId}/adopt',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          Text(
            '• Pet IDs se obtienen dinámicamente desde /pets/available',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          if (state is CompanionShopLoaded) ...[
            Text(
              '• Pet IDs encontrados: ${state.availablePetIds.length}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ SOLUCIÓN APLICADA:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  'Pet IDs se obtienen dinámicamente de la API',
                  style: TextStyle(fontSize: 9, color: Colors.green[600]),
                ),
                Text(
                  'No más IDs hardcodeados',
                  style: TextStyle(fontSize: 9, color: Colors.green[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _testWithDynamicPetId(BuildContext context) {
    debugPrint('🧪 [TEST_WIDGET] === TESTING CON PET ID DINÁMICO ===');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.science, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Test con Pet ID Real'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Probar adopción con Pet ID obtenido dinámicamente de tu API?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ USANDO PET IDs DINÁMICOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los Pet IDs se obtienen desde /pets/available',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[600],
                    ),
                  ),
                  Text(
                    'Se usará el primer Pet ID disponible',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[600],
                    ),
                  ),
                ],
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
              
              debugPrint('🚀 [TEST_WIDGET] Ejecutando test con Pet ID dinámico');
              
              // 🔥 LLAMAR AL MÉTODO DE TEST DINÁMICO
              context.read<CompanionShopCubit>().testAdoptionWithRealApi();
              
              _showTestResult(context, 'Test Dinámico');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Probar'),
          ),
        ],
      ),
    );
  }

  void _testSpecificPetId(BuildContext context, String petId, String localId) {
    debugPrint('🧪 [TEST_WIDGET] === TESTING CON PET ID ESPECÍFICO ===');
    debugPrint('🧪 [TEST_WIDGET] Local ID: $localId');
    debugPrint('🧪 [TEST_WIDGET] Pet ID: $petId');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pets, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text('Test $localId'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Probar adopción de esta mascota específica?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mascota: $localId',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pet ID: $petId',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.blue[600],
                    ),
                  ),
                ],
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
              
              debugPrint('🚀 [TEST_WIDGET] Ejecutando test con Pet ID específico: $petId');
              
              // 🔥 LLAMAR AL MÉTODO DE TEST CON PET ID ESPECÍFICO
              context.read<CompanionShopCubit>().testAdoptionWithRealApi(
                specificPetId: petId,
              );
              
              _showTestResult(context, localId);
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

  void _showTestResult(BuildContext context, String label) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider(
        create: (context) => getIt<CompanionShopCubit>(),
        child: BlocConsumer<CompanionShopCubit, CompanionShopState>(
          listener: (context, state) {
            if (state is CompanionShopPurchaseSuccess) {
              Future.delayed(const Duration(seconds: 4), () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
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
                  Expanded(
                    child: Text(
                      'Resultado: $label',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state is CompanionShopLoading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Enviando petición con Pet ID dinámico...'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'POST /api/gamification/pets/{petId}/adopt',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ] else if (state is CompanionShopPurchaseSuccess) ...[
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '¡Adopción Exitosa! 🎉',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mascota: ${state.purchasedCompanion.displayName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '✅ Pet ID obtenido dinámicamente',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (state is! CompanionShopLoading)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                if (state is CompanionShopError)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _testWithDynamicPetId(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
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