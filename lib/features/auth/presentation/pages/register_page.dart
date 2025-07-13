// lib/features/auth/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xuma_a/features/auth/domain/usecases/register_usecase.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../navigation/presentation/pages/main_wrapper_page.dart'; // 🆕 Para navegación
import '../cubit/auth_cubit.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_header.dart';
import '../widgets/parental_info_form.dart';
import '../widgets/parental_consent_dialog.dart';
import '../widgets/email_verification_page.dart'; // 🆕 Widget para verificación
import '../../domain/entities/parental_info.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: const _RegisterPageContent(),
    );
  }
}

class _RegisterPageContent extends StatefulWidget {
  const _RegisterPageContent();

  @override
  State<_RegisterPageContent> createState() => _RegisterPageContentState();
}

class _RegisterPageContentState extends State<_RegisterPageContent> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleParentalInfo(ParentalInfo parentalInfo, RegisterParams baseParams) {
    context.read<AuthCubit>().registerWithParentalInfo(
      baseParams: baseParams,
      parentalInfo: parentalInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Registro exitoso! Bienvenido a XUMA\'A!'),
                  backgroundColor: AppColors.success,
                ),
              );
              // 🆕 Navegar al home después del registro exitoso
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainWrapperPage(),
                ),
                (route) => false,
              );
            } else if (state is AuthParentalConsentPending) { // 🔄 Cambio de nombre
              _showParentalConsentDialog(context, state.user, state.parentEmail);
            } else if (state is AuthEmailVerificationRequired) { // 🆕 Nuevo estado
              _showEmailVerificationDialog(context, state.user);
            } else if (state is AuthEmailVerificationSent) { // 🆕 Nuevo estado
              _showEmailSentMessage(context, state.email);
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              // Mostrar formulario de información parental
              if (state is AuthParentalInfoRequired) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ParentalInfoForm(
                      onSubmit: (parentalInfo) => _handleParentalInfo(parentalInfo, state.baseParams),
                      onCancel: () => context.read<AuthCubit>().cancelParentalProcess(),
                    ),
                  ),
                );
              }

              // 🆕 Mostrar pantalla de verificación de email
              if (state is AuthEmailVerificationRequired) {
                return EmailVerificationPage(
                  user: state.user,
                  onResendEmail: () {
                    context.read<AuthCubit>().sendEmailVerification(state.user.id);
                  },
                  onCheckStatus: () {
                    context.read<AuthCubit>().checkEmailVerificationStatus(state.user.id);
                  },
                );
              }

              // 🆕 Mostrar pantalla de email enviado
              if (state is AuthEmailVerificationSent) {
                return EmailVerificationSentPage(
                  user: state.user,
                  email: state.email,
                  onResendEmail: () {
                    context.read<AuthCubit>().resendEmailVerification(state.email);
                  },
                  onCheckStatus: () {
                    context.read<AuthCubit>().checkEmailVerificationStatus(state.user.id);
                  },
                );
              }

              // Formulario de registro normal
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Logo y header
                      const LogoHeader(
                        title: 'Registrarse',
                        subtitle: 'Únete a la comunidad verde de XUMA\'A',
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Nombre field
                      AuthTextField(
                        controller: _firstNameController,
                        label: 'Nombre',
                        hint: 'Ingresa tu nombre',
                        keyboardType: TextInputType.name,
                        validator: _validateFirstName,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Apellido field
                      AuthTextField(
                        controller: _lastNameController,
                        label: 'Apellido',
                        hint: 'Ingresa tu apellido',
                        keyboardType: TextInputType.name,
                        validator: _validateLastName,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Edad field
                      AuthTextField(
                        controller: _ageController,
                        label: 'Edad',
                        hint: 'Ingresa tu edad',
                        keyboardType: TextInputType.number,
                        validator: _validateAge,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email field
                      AuthTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        hint: 'Ingresa tu email',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password field
                      AuthTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: 'Crea una contraseña segura',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: _validatePassword,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Confirm Password field
                      AuthTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar Contraseña',
                        hint: 'Confirma tu contraseña',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: _validateConfirmPassword,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Age warning for minors
                      if (_showAgeWarning()) _buildAgeWarning(),
                      
                      const SizedBox(height: 32),
                      
                      // Register button
                      CustomButton(
                        text: 'Registrarse',
                        isLoading: state is AuthLoading,
                        onPressed: _handleRegister,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta?',
                            style: AppTextStyles.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Inicia sesión acá',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Environment awareness section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.earthGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.nature_people_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Juntos por el planeta',
                              style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Al registrarte, te unes a una comunidad comprometida con el cuidado del medio ambiente y la sostenibilidad.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _showAgeWarning() {
    final ageText = _ageController.text;
    if (ageText.isEmpty) return false;
    final age = int.tryParse(ageText);
    return age != null && age <= 13;
  }

  Widget _buildAgeWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autorización Parental Requerida',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Para menores de 13 años, se requiere autorización de los padres o tutores.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        age: int.parse(_ageController.text),
      );
    }
  }

  // 🔄 Método actualizado con nuevo parámetro
  void _showParentalConsentDialog(BuildContext context, dynamic user, String parentEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ParentalConsentDialog(
        user: user,
        onAccept: () {
          Navigator.of(context).pop();
          context.read<AuthCubit>().acknowledgeParentalConsent();
          Navigator.of(context).pop(); // Volver al login
        },
      ),
    );
  }

  // 🆕 Método para mostrar diálogo de verificación de email
  void _showEmailVerificationDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📧 Verificación de Email'),
        content: Text(
          'Hemos enviado un email de verificación a ${user.email}. Por favor revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
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

  // 🆕 Método para mostrar mensaje de email enviado
  void _showEmailSentMessage(BuildContext context, String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📧 Email de verificación enviado a $email'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El apellido es requerido';
    }
    if (value.trim().length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'La edad es requerida';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Ingresa una edad válida';
    }
    if (age < 1 || age > 120) {
      return 'Ingresa una edad válida (1-120)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    // 🆕 Validación mejorada de contraseña
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}