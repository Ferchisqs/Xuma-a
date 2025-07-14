import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xuma_a/features/auth/domain/usecases/register_usecase.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../di/injection.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/logo_header.dart';
import '../widgets/parental_info_form.dart';
import '../widgets/parental_consent_dialog.dart';
import '../widgets/email_verification_page.dart';
import '../../domain/entities/parental_info.dart';
import 'login_page.dart';

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
  bool _showingSuccessDialog = false; // 🆕 NUEVO FLAG

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
  }

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
              _showErrorSnackBar(context, state.message);
            } else if (state is AuthAuthenticated) {
              // 🆕 ACTIVAR FLAG ANTES DE MOSTRAR EL DIÁLOGO
              _showingSuccessDialog = true;
              _showRegistrationSuccessDialog(context, state.user);
            } else if (state is AuthParentalConsentPending) {
              _showParentalConsentDialog(context, state.user, state.parentEmail);
            } else if (state is AuthEmailVerificationRequired) {
              _showEmailVerificationDialog(context, state.user);
            } else if (state is AuthEmailVerificationSent) {
              _showEmailSentMessage(context, state.email);
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              // 🆕 SI SE ESTÁ MOSTRANDO EL DIÁLOGO DE ÉXITO, MOSTRAR PANTALLA DE CARGA
              if (_showingSuccessDialog || state is AuthAuthenticated) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Finalizando registro...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

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

              // Mostrar pantalla de verificación de email
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

              // Mostrar pantalla de email enviado
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
                        validator: (value) => ValidationUtils.validateName(value, 'El nombre'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Apellido field
                      AuthTextField(
                        controller: _lastNameController,
                        label: 'Apellido',
                        hint: 'Ingresa tu apellido',
                        keyboardType: TextInputType.name,
                        validator: (value) => ValidationUtils.validateName(value, 'El apellido'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Edad field
                      AuthTextField(
                        controller: _ageController,
                        label: 'Edad',
                        hint: 'Ingresa tu edad',
                        keyboardType: TextInputType.number,
                        validator: ValidationUtils.validateAge,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email field
                      AuthTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        hint: 'Ingresa tu email',
                        keyboardType: TextInputType.emailAddress,
                        validator: ValidationUtils.validateEmail,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password field con indicador de fuerza
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
                        validator: ValidationUtils.validatePassword,
                      ),
                      
                      // Mostrar indicador de fuerza de contraseña
                      if (_passwordController.text.isNotEmpty)
                        _buildPasswordStrengthIndicator(),
                      
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
                        validator: (value) => ValidationUtils.validateConfirmPassword(value, _passwordController.text),
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

  // 🆕 DIÁLOGO DE ÉXITO MEJORADO
  void _showRegistrationSuccessDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // 🆕 PREVENIR CIERRE CON BACK BUTTON
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de éxito animado
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.earthGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Título
                Text(
                  '¡Registro Exitoso! 🎉',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de bienvenida personalizado
                Text(
                  '¡Hola ${user.firstName}!',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Información
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_circle_rounded,
                        color: AppColors.success,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu cuenta ha sido creada exitosamente. Ahora puedes iniciar sesión con tu email y contraseña.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Botón para ir al login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Cerrar diálogo
                      _navigateToLogin(context); // Ir al login
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Mensaje adicional
                Text(
                  'Bienvenido a la comunidad XUMA\'A 🌱',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 MÉTODO PARA NAVEGAR AL LOGIN MEJORADO
  void _navigateToLogin(BuildContext context) {
    // Limpiar el estado del AuthCubit antes de navegar
    context.read<AuthCubit>().reset();
    
    // Navegar al login reemplazando toda la pila de navegación
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // Widget para mostrar fuerza de contraseña en tiempo real
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = ValidationUtils.calculatePasswordStrength(password);
    final strengthText = ValidationUtils.getPasswordStrengthText(password);
    
    Color strengthColor;
    if (strength < 2) {
      strengthColor = AppColors.error;
    } else if (strength < 3) {
      strengthColor = AppColors.warning;
    } else if (strength < 4) {
      strengthColor = AppColors.info;
    } else {
      strengthColor = AppColors.success;
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: strengthColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de fuerza
          Row(
            children: [
              Text(
                'Fuerza: ',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                strengthText,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (strength / 4).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: strengthColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          
          // Requisitos
          Text(
            'Requisitos:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          _buildRequirement('Mínimo 6 caracteres', password.length >= 6),
          _buildRequirement('Al menos una mayúscula', password.contains(RegExp(r'[A-Z]'))),
          _buildRequirement('Al menos una minúscula', password.contains(RegExp(r'[a-z]'))),
          _buildRequirement('Al menos un número', password.contains(RegExp(r'[0-9]'))),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isMet ? AppColors.success : AppColors.textHint,
              ),
            ),
          ),
        ],
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
      print('🔍 [REGISTER] Registering user with data:');
      print('   - FirstName: ${_firstNameController.text.trim()}');
      print('   - LastName: ${_lastNameController.text.trim()}');
      print('   - Email: ${_emailController.text.trim()}');
      print('   - Age: ${_ageController.text}');
      
      context.read<AuthCubit>().register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        age: int.parse(_ageController.text),
      );
    } else {
      _showErrorSnackBar(context, 'Por favor corrige los errores en el formulario');
    }
  }

  void _showParentalConsentDialog(BuildContext context, dynamic user, String parentEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ParentalConsentDialog(
        user: user,
        parentEmail: parentEmail,
        onAccept: () {
          Navigator.of(context).pop();
          context.read<AuthCubit>().acknowledgeParentalConsent();
          _navigateToLogin(context);
        },
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

  void _showEmailSentMessage(BuildContext context, String email) {
    _showSuccessSnackBar(context, '📧 Email de verificación enviado a $email');
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
}