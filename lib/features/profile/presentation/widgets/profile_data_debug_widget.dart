// lib/features/profile/presentation/widgets/profile_data_debug_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';

class ProfileDataDebugWidget extends StatelessWidget {
  const ProfileDataDebugWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                '🐛 DEBUG: Datos del Perfil',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebugSection('🔐 AUTH STATE', authState.runtimeType.toString()),
                  
                  if (authState is AuthAuthenticated) ...[
                    _buildDebugSection('👤 USER ID', authState.user.id ?? 'null'),
                    _buildDebugSection('📧 USER EMAIL', authState.user.email ?? 'null'),
                    _buildDebugSection('👨 USER FIRST NAME', authState.user.firstName ?? 'null'),
                    _buildDebugSection('👨 USER LAST NAME', authState.user.lastName ?? 'null'),
                    _buildDebugSection('🎂 USER AGE', '${authState.user.age ?? 'null'}'),
                    _buildDebugSection('📅 USER CREATED', authState.user.createdAt?.toString() ?? 'null'),
                    
                    if (authState.fullProfile != null) ...[
                      const Divider(),
                      _buildDebugSection('📋 FULL PROFILE ID', authState.fullProfile!.id),
                      _buildDebugSection('👤 PROFILE FIRST NAME', authState.fullProfile!.firstName),
                      _buildDebugSection('👤 PROFILE LAST NAME', authState.fullProfile!.lastName),
                      _buildDebugSection('🎂 PROFILE AGE', '${authState.fullProfile!.age}'),
                      _buildDebugSection('📅 PROFILE CREATED', authState.fullProfile!.createdAt.toString()),
                      _buildDebugSection('⭐ PROFILE POINTS', '${authState.fullProfile!.ecoPoints}'),
                      _buildDebugSection('🏆 PROFILE ACHIEVEMENTS', '${authState.fullProfile!.achievementsCount}'),
                      _buildDebugSection('📚 PROFILE LESSONS', '${authState.fullProfile!.lessonsCompleted}'),
                      _buildDebugSection('🎭 PROFILE LEVEL', authState.fullProfile!.level),
                    ] else ...[
                      const Divider(),
                      _buildDebugSection('📋 FULL PROFILE', 'NULL - No se ha cargado'),
                    ],
                  ],
                ],
              );
            },
          ),
          
          const Divider(),
          
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebugSection('🔄 PROFILE CUBIT STATE', profileState.runtimeType.toString()),
                  
                  if (profileState is ProfileLoaded) ...[
                    _buildDebugSection('📋 LOADED PROFILE ID', profileState.profile.id),
                    _buildDebugSection('👤 LOADED FIRST NAME', profileState.profile.firstName),
                    _buildDebugSection('👤 LOADED LAST NAME', profileState.profile.lastName),
                    _buildDebugSection('🎂 LOADED AGE', '${profileState.profile.age}'),
                    _buildDebugSection('📅 LOADED CREATED', profileState.profile.createdAt.toString()),
                  ] else if (profileState is ProfileError) ...[
                    _buildDebugSection('❌ PROFILE ERROR', profileState.message),
                  ],
                ],
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is AuthAuthenticated) {
                      context.read<ProfileCubit>().loadUserProfile(authState.user.id!);
                    }
                  },
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Recargar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('🔍 === MANUAL DEBUG TRIGGER ===');
                    print('🔍 AuthState: ${context.read<AuthCubit>().state.runtimeType}');
                    print('🔍 ProfileState: ${context.read<ProfileCubit>().state.runtimeType}');
                    
                    final authState = context.read<AuthCubit>().state;
                    if (authState is AuthAuthenticated) {
                      print('🔍 User Data: ${authState.user.toString()}');
                      if (authState.fullProfile != null) {
                        print('🔍 Full Profile: ${authState.fullProfile.toString()}');
                      }
                    }
                  },
                  icon: Icon(Icons.terminal, size: 16),
                  label: Text('Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDebugSection(String label, String value) {
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
                color: Colors.orange[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.black87,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}