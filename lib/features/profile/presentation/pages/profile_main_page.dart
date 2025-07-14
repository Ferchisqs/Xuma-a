// lib/features/profile/presentation/pages/profile_main_page.dart - LAYOUT CORREGIDO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../cubit/profile_cubit.dart';

class ProfileMainPage extends StatelessWidget {
  const ProfileMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) {
            final authCubit = getIt<AuthCubit>();
            authCubit.validateCurrentToken();
            return authCubit;
          },
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => getIt<ProfileCubit>(),
        ),
        BlocProvider.value(
          value: context.read<NavigationCubit>(),
        ),
      ],
      child: const _ProfileMainContent(),
    );
  }
}

class _ProfileMainContent extends StatelessWidget {
  const _ProfileMainContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToLogin(context);
          });
        } else if (state is AuthError) {
          _showErrorSnackBar(context, state.message);
        } else if (state is AuthAuthenticated) {
          print('🔍 Usuario autenticado, cargando perfil completo para: ${state.user.id}');
          context.read<ProfileCubit>().loadUserProfile(state.user.id);
        }
      },
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: const SideNavBar(),
          appBar: const CustomAppBar(
            title: 'Mi Perfil',
            showDrawerButton: true,
          ),
          body: SafeArea( // 🆕 AGREGADO SafeArea
            child: _buildBody(context, authState),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AuthState authState) {
    if (authState is AuthLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (authState is AuthAuthenticated) {
      return BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          if (profileState is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (profileState is ProfileError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // 🆕 AGREGADO
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error cargando perfil',
                      style: AppTextStyles.h4.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profileState.message,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ProfileCubit>().loadUserProfile(authState.user.id);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (profileState is ProfileLoaded || profileState is ProfileUpdated) {
            final profile = profileState is ProfileLoaded 
                ? profileState.profile 
                : (profileState as ProfileUpdated).profile;
            
            return _buildProfileContent(context, profile);
          }

          return _buildProfileContent(context, authState.user, isBasicData: true);
        },
      );
    }

    return _buildNotAuthenticatedContent(context);
  }

  Widget _buildProfileContent(BuildContext context, dynamic user, {bool isBasicData = false}) {
    return LayoutBuilder( // 🆕 USAR LayoutBuilder PARA RESPONSIVE
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16), // 🆕 REDUCIDO PADDING
          child: ConstrainedBox( // 🆕 CONSTRAINEDBOX PARA EVITAR OVERFLOW
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32, // Menos padding
            ),
            child: Column(
              children: [
                // Banner informativo si usamos datos básicos
                if (isBasicData) 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cargando información completa del perfil...',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),

                // User Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20), // 🆕 REDUCIDO PADDING
                  decoration: BoxDecoration(
                    gradient: AppColors.earthGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 🆕 AGREGADO
                    children: [
                      // Profile Picture
                      _buildProfilePictureSection(context, user),
                      
                      const SizedBox(height: 16),
                      
                      // User Info
                      _buildUserInfoSection(user),
                      
                      const SizedBox(height: 12),
                      
                      // Member since
                      Text(
                        'Miembro desde ${_formatDate(_getCreatedAt(user))}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20), // 🆕 REDUCIDO ESPACIO
                
                // Stats Cards - 🆕 HACER MÁS COMPACTO
                _buildStatsSection(user),
                
                const SizedBox(height: 20), // 🆕 REDUCIDO ESPACIO
                
                // Account Information Section
                _buildAccountInfoSection(context, user),
                
                const SizedBox(height: 20), // 🆕 REDUCIDO ESPACIO
                
                // Menu Options - 🆕 HACER MÁS COMPACTO
                _buildMenuSection(context),
                
                const SizedBox(height: 20), // 🆕 REDUCIDO ESPACIO
                
                // Logout Button
                _buildLogoutSection(context),
                
                const SizedBox(height: 20), // 🆕 ESPACIO FINAL PEQUEÑO
              ],
            ),
          ),
        );
      },
    );
  }

  // 🆕 MÉTODOS SEPARADOS PARA MEJOR ORGANIZACIÓN
  Widget _buildProfilePictureSection(BuildContext context, dynamic user) {
    return GestureDetector(
      onTap: () => _showProfilePictureOptions(context),
      child: Stack(
        children: [
          Container(
            width: 80, // 🆕 REDUCIDO TAMAÑO
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: _buildProfileImage(user),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
                size: 14, // 🆕 REDUCIDO TAMAÑO
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(dynamic user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getFullName(user),
          style: AppTextStyles.h4.copyWith( // 🆕 REDUCIDO TAMAÑO DE FUENTE
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _getEmail(user),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${_getAge(user)} años',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        // Level Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 🆕 REDUCIDO PADDING
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 14, // 🆕 REDUCIDO TAMAÑO
              ),
              const SizedBox(width: 4),
              Text(
                _getUserLevel(user),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(dynamic user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.stars_rounded,
                title: 'Puntos',
                value: _getEcoPoints(user).toString(),
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12), // 🆕 REDUCIDO ESPACIO
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events_rounded,
                title: 'Logros',
                value: _getAchievements(user).toString(),
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // 🆕 REDUCIDO ESPACIO
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.school_rounded,
                title: 'Lecciones',
                value: _getLessonsCompleted(user).toString(),
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12), // 🆕 REDUCIDO ESPACIO
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_rounded,
                title: 'Días activo',
                value: _getDaysActive(user).toString(),
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountInfoSection(BuildContext context, dynamic user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Información de la Cuenta'),
        const SizedBox(height: 8),
        _buildInfoCard(user),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Configuración'),
        const SizedBox(height: 8),
        _buildCompactMenuOption(
          icon: Icons.edit_rounded,
          title: 'Editar Perfil',
          onTap: () => _showSnackBar(context, 'Función de edición próximamente'),
        ),
        const SizedBox(height: 8),
        _buildCompactMenuOption(
          icon: Icons.notifications_rounded,
          title: 'Notificaciones',
          onTap: () => _showSnackBar(context, 'Función de notificaciones próximamente'),
        ),
        const SizedBox(height: 8),
        _buildCompactMenuOption(
          icon: Icons.help_outline_rounded,
          title: 'Ayuda',
          onTap: () {
            try {
              context.read<NavigationCubit>().goToContact();
            } catch (e) {
              _showSnackBar(context, 'Función de ayuda próximamente');
            }
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14), // 🆕 REDUCIDO PADDING
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // 🆕 REDUCIDO PADDING
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 18, // 🆕 REDUCIDO TAMAÑO
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cerrar Sesión',
                  style: AppTextStyles.bodyMedium.copyWith( // 🆕 REDUCIDO TAMAÑO
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.error,
                size: 14, // 🆕 REDUCIDO TAMAÑO
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 VERSIÓN COMPACTA DEL MENU OPTION
  Widget _buildCompactMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // 🆕 COMPACTO
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20, // 🆕 REDUCIDO TAMAÑO
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint,
                size: 14, // 🆕 REDUCIDO TAMAÑO
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 RESTO DE MÉTODOS HELPER (SIN CAMBIOS PERO MÁS COMPACTOS)
  Widget _buildProfileImage(dynamic user) {
    String? imageUrl = user.profilePicture ?? user.avatarUrl;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }
    
    return const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 40,
    );
  }

  // Helper methods para obtener datos del usuario
  String _getFullName(dynamic user) {
    if (user.fullName != null) return user.fullName;
    return '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
  }

  String _getEmail(dynamic user) => user.email ?? '';
  int _getAge(dynamic user) => user.age ?? 18;
  String _getUserLevel(dynamic user) {
    if (user.level != null) return user.level;
    int age = _getAge(user);
    if (age < 13) return 'Eco Explorer';
    if (age < 18) return 'Eco Guardian';
    if (age < 25) return 'Eco Warrior';
    return 'Eco Master';
  }
  DateTime _getCreatedAt(dynamic user) => user.createdAt ?? DateTime.now();
  int _getEcoPoints(dynamic user) => user.ecoPoints ?? 0;
  int _getAchievements(dynamic user) => user.achievementsCount ?? 0;
  int _getLessonsCompleted(dynamic user) => user.lessonsCompleted ?? 0;
  int _getDaysActive(dynamic user) {
    DateTime createdAt = _getCreatedAt(user);
    return DateTime.now().difference(createdAt).inDays;
  }

  Widget _buildNotAuthenticatedContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // 🆕 AGREGADO
          children: [
            Container(
              width: 80, // 🆕 REDUCIDO TAMAÑO
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 40, // 🆕 REDUCIDO TAMAÑO
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay sesión activa',
              style: AppTextStyles.h4.copyWith( // 🆕 REDUCIDO TAMAÑO
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor inicia sesión para ver tu perfil',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToLogin(context),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Iniciar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 🆕 REDUCIDO PADDING
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith( // 🆕 REDUCIDO TAMAÑO
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // 🆕 REDUCIDO PADDING
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🆕 AGREGADO
        children: [
          _buildInfoRow('Nombre', _getFullName(user)),
          const SizedBox(height: 8),
          _buildInfoRow('Email', _getEmail(user)),
          const SizedBox(height: 8),
          _buildInfoRow('Edad', '${_getAge(user)} años'),
          if (user.needsParentalConsent == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Consentimiento', 'Requerido', isWarning: true),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith( // 🆕 REDUCIDO TAMAÑO
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith( // 🆕 REDUCIDO TAMAÑO
              color: isWarning ? AppColors.warning : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // 🆕 REDUCIDO PADDING
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🆕 AGREGADO
        children: [
          Icon(
            icon,
            color: color,
            size: 20, // 🆕 REDUCIDO TAMAÑO
          ),
          const SizedBox(height: 6), // 🆕 REDUCIDO ESPACIO
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith( // 🆕 REDUCIDO TAMAÑO
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilePictureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20), // 🆕 REDUCIDO PADDING
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cambiar foto de perfil',
              style: AppTextStyles.bodyLarge.copyWith( // 🆕 REDUCIDO TAMAÑO
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoOption(
                    icon: Icons.camera_alt_rounded,
                    title: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar(context, 'Función de cámara próximamente');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoOption(
                    icon: Icons.photo_library_rounded,
                    title: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar(context, 'Función de galería próximamente');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12), // 🆕 REDUCIDO PADDING
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🆕 AGREGADO
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24, // 🆕 REDUCIDO TAMAÑO
            ),
            const SizedBox(height: 6), // 🆕 REDUCIDO ESPACIO
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith( // 🆕 REDUCIDO TAMAÑO
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20, // 🆕 REDUCIDO TAMAÑO
              ),
              const SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: AppTextStyles.bodyLarge.copyWith( // 🆕 REDUCIDO TAMAÑO
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state is AuthLoading ? null : () {
                    Navigator.of(dialogContext).pop();
                    _performLogout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: state is AuthLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Cerrar Sesión',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _performLogout(BuildContext context) {
    print('🔍 Performing logout...');
    context.read<AuthCubit>().logout();
  }

  void _navigateToLogin(BuildContext context) {
    print('🔍 Navigating to login...');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }
}