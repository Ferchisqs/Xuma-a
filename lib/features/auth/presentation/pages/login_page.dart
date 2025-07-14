// lib/features/auth/presentation/pages/login_page.dart - VERSIÓN SIMPLIFICADA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/utils/token_debug_helper.dart'; // 🆕 IMPORT HELPER
import '../../../../di/injection.dart';
import '../../../navigation/presentation/pages/main_wrapper_page.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_header.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: const _LoginPageContent(),
    );
  }
}

class _LoginPageContent extends StatefulWidget {
  const _LoginPageContent();

  @override
  State<_LoginPageContent> createState() => _LoginPageContentState();
}

class _LoginPageContentState extends State<_LoginPageContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _showDebug = false; // 🆕 CONTROL PARA MOSTRAR DEBUG
  Map<String, dynamic> _tokenInfo = {}; // 🆕 INFO DE TOKENS

  @override
  void initState() {
    super.initState();
    _loadTokenInfo(); // 🆕 CARGAR INFO AL INICIO
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🆕 CARGAR INFORMACIÓN DE TOKENS
  Future<void> _loadTokenInfo() async {
    if (_showDebug) {
      final info = await TokenDebugHelper.getTokenInfo();
      setState(() {
        _tokenInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _showErrorSnackBar(context, state.message);
            } else if (state is AuthAuthenticated) {
              _showSuccessSnackBar(context, '¡Bienvenido a XUMA\'A!');
              _navigateToHome(context);
            } else if (state is AuthEmailVerificationRequired) {
              _showEmailVerificationRequired(context, state.user);
            } else if (state is AuthParentalConsentPending) {
              _showParentalConsentPending(context, state.user, state.parentEmail);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo y header
                  const LogoHeader(
                    title: 'Inicio de Sesión',
                    subtitle: '¡Hola! Me da mucho gusto verte por aquí',
                  ),

                  const SizedBox(height: 48),

                  // 🆕 CONTROL DE DEBUG MEJORADO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bug_report, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Modo Debug:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _showDebug,
                              onChanged: (value) {
                                setState(() => _showDebug = value);
                                if (value) _loadTokenInfo();
                              },
                              activeColor: AppColors.warning,
                            ),
                          ],
                        ),
                        
                        if (_showDebug) ...[
                          const SizedBox(height: 16),
                          _buildTokenInfoCard(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await TokenDebugHelper.debugTokens();
                                    _showSnackBar(context, 'Debug info en consola');
                                  },
                                  icon: const Icon(Icons.terminal, size: 16),
                                  label: const Text('Debug'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await TokenDebugHelper.clearAllTokens();
                                    await _loadTokenInfo();
                                    _showSnackBar(context, 'Tokens eliminados');
                                  },
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Limpiar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _loadTokenInfo,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Actualizar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Email field
                  AuthTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    hint: 'Ingresa tu email',
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidationUtils.validateEmail,
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hint: 'Ingresa tu contraseña',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) => ValidationUtils.validateRequired(value, 'La contraseña'),
                  ),

                  const SizedBox(height: 24),

                  // Login button
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Iniciar Sesión',
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          _handleLogin();
                          // Recargar info de tokens después del login
                          if (_showDebug) {
                            Future.delayed(const Duration(seconds: 2), _loadTokenInfo);
                          }
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🆕 BOTÓN DE TESTING SI DEBUG ESTÁ ACTIVO
                  if (_showDebug) ...[
                    CustomButton(
                      text: 'Test Login (test@example.com)',
                      backgroundColor: AppColors.info,
                      onPressed: () {
                        _emailController.text = 'test@example.com';
                        _passwordController.text = '123456';
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Regístrate acá',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Environment info card (solo si no está en debug)
                  if (!_showDebug) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.nature.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.nature.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: AppColors.nature,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Protector del Ambiente',
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Únete a la comunidad de conciencia ambiental y aprende a cuidar nuestro planeta junto a Xico.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 WIDGET PARA MOSTRAR INFO DE TOKENS
  Widget _buildTokenInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Estado de Tokens',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildTokenInfoRow('Access Token', _tokenInfo['hasAccessToken']?.toString() ?? 'false'),
          _buildTokenInfoRow('Refresh Token', _tokenInfo['hasRefreshToken']?.toString() ?? 'false'),
          _buildTokenInfoRow('Expirado', _tokenInfo['isExpired']?.toString() ?? 'unknown'),
          _buildTokenInfoRow('User ID', _tokenInfo['userId']?.toString() ?? 'null'),
        ],
      ),
    );
  }

  Widget _buildTokenInfoRow(String label, String value) {
    Color valueColor = AppColors.textSecondary;
    if (value == 'true') {
      valueColor = AppColors.success;
    } else if (value == 'false') {
      valueColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } else {
      _showErrorSnackBar(context, 'Por favor completa todos los campos correctamente');
    }
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainWrapperPage(),
      ),
      (route) => false,
    );
  }

  void _showEmailVerificationRequired(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            const Text('Verificación Pendiente'),
          ],
        ),
        content: Text(
          'Tu cuenta necesita verificación de email. Por favor revisa tu bandeja de entrada en ${user.email}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().sendEmailVerification(user.id);
            },
            child: const Text('Reenviar Email'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().checkEmailVerificationStatus(user.id);
            },
            child: const Text('Ya Verifiqué'),
          ),
        ],
      ),
    );
  }

  void _showParentalConsentPending(BuildContext context, dynamic user, String parentEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.family_restroom_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            const Text('Autorización Pendiente'),
          ],
        ),
        content: Text(
          'Tu cuenta está pendiente de autorización parental. Se envió un email a $parentEmail para aprobar tu cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().checkParentalConsentStatus(user.id);
            },
            child: const Text('Verificar Estado'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthCubit>().reset();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
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
}