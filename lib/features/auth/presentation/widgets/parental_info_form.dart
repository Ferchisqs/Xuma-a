// lib/features/auth/presentation/widgets/parental_info_form.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/parental_info.dart';
import 'auth_text_field.dart';
import 'custom_button.dart';

class ParentalInfoForm extends StatefulWidget {
  final Function(ParentalInfo) onSubmit;
  final VoidCallback onCancel;

  const ParentalInfoForm({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ParentalInfoForm> createState() => _ParentalInfoFormState();
}

class _ParentalInfoFormState extends State<ParentalInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _guardianNameController = TextEditingController();
  final _guardianEmailController = TextEditingController();
  
  String _selectedRelationship = 'Padre';
  
  final List<String> _relationships = [
    'Padre',
    'Madre',
    'Abuelo',
    'Abuela',
    'Tutor Legal',
    'Otro'
  ];

  @override
  void dispose() {
    _guardianNameController.dispose();
    _guardianEmailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final parentalInfo = ParentalInfo(
        guardianName: _guardianNameController.text.trim(),
        relationship: _selectedRelationship,
        guardianEmail: _guardianEmailController.text.trim(),
      );
      widget.onSubmit(parentalInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text(
              'Información del Tutor',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtítulo explicativo
            Text(
              'Se requiere el consentimiento de un tutor para menores de 13 años',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Nombre del tutor
            AuthTextField(
              controller: _guardianNameController,
              hint: 'Nombre completo del tutor',
              label: 'Nombre del Tutor',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del tutor';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Relación parental
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relación Parental',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedRelationship,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _relationships.map((String relationship) {
                      return DropdownMenuItem<String>(
                        value: relationship,
                        child: Text(
                          relationship,
                          style: AppTextStyles.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRelationship = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email del tutor
            AuthTextField(
              controller: _guardianEmailController,
              hint: 'ejemplo@correo.com',
              label: 'Correo Electrónico del Tutor',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el correo electrónico';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                  return 'Por favor ingresa un correo electrónico válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    onPressed: widget.onCancel,
                    backgroundColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Continuar',
                    onPressed: _handleSubmit,
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}