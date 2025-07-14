// lib/features/profile/presentation/widgets/profile_debug_panel.dart - TEMPORAL
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ProfileDebugPanel extends StatelessWidget {
  const ProfileDebugPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                '🐛 DEBUG TEMPORAL - Datos del Usuario',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                final user = authState.user;
                final fullProfile = authState.fullProfile;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDebugSection('🔐 ESTADO', 'AuthAuthenticated'),
                    _buildDebugSection('🆔 USER ID', user.id ?? 'null'),
                    _buildDebugSection('📧 USER EMAIL', user.email ?? 'null'),
                    _buildDebugSection('👤 USER FIRST NAME', user.firstName ?? 'null'),
                    _buildDebugSection('👤 USER LAST NAME', user.lastName ?? 'null'),
                    _buildDebugSection('🎂 USER AGE', '${user.age ?? 'null'}'),
                    _buildDebugSection('📅 USER CREATED', user.createdAt?.toString() ?? 'null'),
                    
                    const Divider(color: Colors.red),
                    
                    if (fullProfile != null) ...[
                      _buildDebugSection('📋 PROFILE STATUS', 'LOADED ✅'),
                      _buildDebugSection('🆔 PROFILE ID', fullProfile.id),
                      _buildDebugSection('👤 PROFILE FIRST NAME', fullProfile.firstName),
                      _buildDebugSection('👤 PROFILE LAST NAME', fullProfile.lastName),
                      _buildDebugSection('🎂 PROFILE AGE', '${fullProfile.age}'),
                      _buildDebugSection('⭐ PROFILE POINTS', '${fullProfile.ecoPoints}'),
                      _buildDebugSection('🏆 PROFILE ACHIEVEMENTS', '${fullProfile.achievementsCount}'),
                      _buildDebugSection('📚 PROFILE LESSONS', '${fullProfile.lessonsCompleted}'),
                      _buildDebugSection('🎭 PROFILE LEVEL', fullProfile.level),
                      
                      // Verificar si hay datos placeholder
                      if (_isPlaceholder(fullProfile.firstName) || 
                          _isPlaceholder(fullProfile.lastName) || 
                          fullProfile.age == 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            '⚠️ PROBLEMA DETECTADO: El backend está devolviendo datos placeholder',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ] else if (authState.isProfileLoading) ...[
                      _buildDebugSection('📋 PROFILE STATUS', 'LOADING... ⏳'),
                    ] else ...[
                      _buildDebugSection('📋 PROFILE STATUS', 'NOT LOADED ❌'),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              print('🔧 [DEBUG] Manual profile refresh triggered');
                              context.read<AuthCubit>().refreshUserProfile();
                            },
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('Recargar Perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              print('🔧 [DEBUG] Force reload with user data triggered');
                              // Llamar al método que fuerza usar datos del usuario
                              final authCubit = context.read<AuthCubit>();
                              // authCubit.forceProfileReloadWithUserData(); // Descomenta cuando agregues el método
                              
                              // Por ahora, solo hacer refresh normal
                              authCubit.refreshUserProfile();
                            },
                            icon: Icon(Icons.build, size: 16),
                            label: Text('Usar Datos Usuario'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton.icon(
                      onPressed: () {
                        print('🔧 [DEBUG] Console log triggered');
                        print('=== MANUAL DEBUG LOG ===');
                        print('User: ${user.toString()}');
                        if (fullProfile != null) {
                          print('Profile: ${fullProfile.toString()}');
                        }
                        print('========================');
                      },
                      icon: Icon(Icons.terminal, size: 16),
                      label: Text('Log en Consola'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              }
              
              return _buildDebugSection('🔐 ESTADO', authState.runtimeType.toString());
            },
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 INSTRUCCIONES:\n'
              '1. Este panel muestra los datos exactos que tiene tu app\n'
              '2. Si ves "string", "user", "example" o age=0, el backend tiene datos placeholder\n'
              '3. Usa "Usar Datos Usuario" para forzar que use los datos del registro\n'
              '4. Elimina este widget cuando todo funcione bien',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.yellow[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDebugSection(String label, String value) {
    // Detectar si es un valor problemático
    bool isProblematic = false;
    if (value.toLowerCase() == 'string' || 
        value.toLowerCase() == 'user' || 
        value.toLowerCase() == 'example' ||
        value == '0' ||
        value == 'null') {
      isProblematic = true;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isProblematic ? Colors.orange[100] : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isProblematic ? Colors.orange : Colors.red[200]!,
                ),
              ),
              child: Row(
                children: [
                  if (isProblematic) ...[
                    Icon(Icons.warning, color: Colors.orange, size: 12),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isProblematic ? Colors.orange[800] : Colors.black87,
                        fontFamily: 'monospace',
                        fontWeight: isProblematic ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isPlaceholder(String value) {
    if (value.trim().isEmpty) return true;
    final lower = value.toLowerCase().trim();
    return lower == 'string' || 
           lower == 'user' || 
           lower == 'example';
  }
}