// lib/features/challenges/presentation/pages/evidence_submission_page.dart - CORREGIDO IMPORTS
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xuma_a/core/services/media_upload_service.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/usecases/submit_evidence_usecase.dart';
import '../cubit/evidence_submission_cubit.dart';

class EvidenceSubmissionPage extends StatelessWidget {
  final ChallengeEntity challenge;
  final String userChallengeId;

  const EvidenceSubmissionPage({
    Key? key,
    required this.challenge,
    required this.userChallengeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EvidenceSubmissionCubit>(),
      child: _EvidenceSubmissionContent(
        challenge: challenge,
        userChallengeId: userChallengeId,
      ),
    );
  }
}

class _EvidenceSubmissionContent extends StatefulWidget {
  final ChallengeEntity challenge;
  final String userChallengeId;

  const _EvidenceSubmissionContent({
    required this.challenge,
    required this.userChallengeId,
  });

  @override
  State<_EvidenceSubmissionContent> createState() =>
      _EvidenceSubmissionContentState();
}

class _EvidenceSubmissionContentState
    extends State<_EvidenceSubmissionContent> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedSubmissionType = 'photo';
  List<File> _selectedImages = [];
  bool _includeLocation = false;
  bool _includeMeasurements = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Subir Evidencia',
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocConsumer<EvidenceSubmissionCubit, EvidenceSubmissionState>(
        listener: (context, state) {
          if (state is EvidenceSubmissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '¡Evidencia enviada exitosamente! Espera la validación.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true); // Retornar true para indicar éxito
          } else if (state is EvidenceSubmissionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is EvidenceSubmissionLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del desafío
                  _buildChallengeHeader(),

                  const SizedBox(height: 24),

                  // Tipo de evidencia
                  _buildSubmissionTypeSelector(),

                  const SizedBox(height: 20),

                  // Descripción
                  _buildDescriptionField(),

                  const SizedBox(height: 20),

                  // Selección de imágenes
                  _buildImageSelection(),

                  const SizedBox(height: 20),

                  // Opciones adicionales
                  _buildAdditionalOptions(),

                  const SizedBox(height: 20),

                  // Campos condicionales
                  if (_includeMeasurements) _buildMeasurementFields(),
                  if (_includeLocation) _buildLocationField(),

                  const SizedBox(height: 32),

                  // Botón de envío
                  _buildSubmitButton(isLoading),

                  const SizedBox(height: 16),

                  // Información adicional
                  _buildSubmissionInfo(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconData(widget.challenge.iconCode,
                    fontFamily: 'MaterialIcons'),
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.challenge.title,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Progreso: ${widget.challenge.currentProgress}/${widget.challenge.targetProgress}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Evidencia',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildTypeOption('photo', 'Fotografía', Icons.camera_alt,
                  'Evidencia visual del desafío'),
              _buildTypeOption('measurement', 'Medición', Icons.straighten,
                  'Con datos de peso/volumen'),
              _buildTypeOption('activity', 'Actividad', Icons.directions_run,
                  'Actividad realizada'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(
      String value, String title, IconData icon, String description) {
    final isSelected = _selectedSubmissionType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubmissionType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          border: value != 'activity'
              ? Border(
                  bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                )
              : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedSubmissionType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubmissionType = newValue!;
                });
              },
              activeColor: AppColors.primary,
            ),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción de la Evidencia',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Describe qué hiciste para completar este desafío...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es requerida';
            }
            if (value.trim().length < 10) {
              return 'La descripción debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotos de Evidencia',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_selectedImages.length}/5',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Botones para agregar fotos
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length < 5
                    ? () => _pickImage(ImageSource.camera)
                    : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length < 5
                    ? () => _pickImage(ImageSource.gallery)
                    : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Previsualización de imágenes
        if (_selectedImages.isNotEmpty) _buildImagePreview(),

        // Mensaje si no hay imágenes
        if (_selectedImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_a_photo,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega al menos una foto de evidencia',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 140, // Altura aumentada para mostrar más info
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return FutureBuilder<Map<String, dynamic>>(
            future: getIt<MediaUploadService>().getFileInfo(_selectedImages[index]),
            builder: (context, snapshot) {
              final fileInfo = snapshot.data;
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Imagen
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Info del archivo
                        if (fileInfo != null) ...[
                          SizedBox(
                            width: 100,
                            child: Text(
                              fileInfo['sizeFormatted'] ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Botón eliminar
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // Indicador de validación
                    if (fileInfo != null && fileInfo['isValidImage'] == true)
                      Positioned(
                        bottom: 30,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Adicional',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Incluir mediciones'),
          subtitle: const Text('Peso, volumen, cantidad'),
          value: _includeMeasurements,
          onChanged: (bool? value) {
            setState(() {
              _includeMeasurements = value ?? false;
            });
          },
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Incluir ubicación'),
          subtitle: const Text('Dónde realizaste el desafío'),
          value: _includeLocation,
          onChanged: (bool? value) {
            setState(() {
              _includeLocation = value ?? false;
            });
          },
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildMeasurementFields() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mediciones',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso',
                    hintText: 'ej: 5kg',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _volumeController,
                  decoration: const InputDecoration(
                    labelText: 'Volumen',
                    hintText: 'ej: 10L',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              hintText: 'ej: 15 botellas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Nombre del lugar',
              hintText: 'ej: Centro de Reciclaje Municipal',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Usar ubicación actual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitEvidence,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Enviar Evidencia',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSubmissionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información Importante',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Tu evidencia será revisada por nuestro equipo\n'
            '• Recibirás una notificación cuando sea validada\n'
            '• Las fotos deben mostrar claramente la actividad realizada\n'
            '• El proceso de validación puede tomar hasta 24 horas',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MÉTODOS DE ACCIÓN ====================

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Verificar límite de fotos
      if (_selectedImages.length >= 5) {
        _showValidationError('Máximo 5 fotos permitidas');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (image != null) {
        final file = File(image.path);
        
        // Validar archivo antes de agregarlo
        final mediaUploadService = getIt<MediaUploadService>();
        final validation = mediaUploadService.validateFile(file);
        
        if (validation != null) {
          _showValidationError(validation);
          return;
        }

        // Verificar información del archivo
        final fileInfo = await mediaUploadService.getFileInfo(file);
        print('📷 [PHOTO SELECTION] File info: $fileInfo');

        setState(() {
          _selectedImages.add(file);
        });

        // Mostrar información del archivo seleccionado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto agregada: ${fileInfo['name']} (${fileInfo['sizeFormatted']})'
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [PHOTO SELECTION] Error selecting image: $e');
      _showValidationError('Error al seleccionar imagen: ${e.toString()}');
    }
  }


  void _getCurrentLocation() {
    // TODO: Implementar obtención de ubicación GPS
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de GPS próximamente disponible'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _submitEvidence() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos una foto de evidencia'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      print(
          '🎯 [EVIDENCE SUBMISSION] === STARTING EVIDENCE SUBMISSION WITH REAL PHOTOS ===');

      // 1. Primero subir las fotos al gamification service
      final mediaUploadService = getIt<MediaUploadService>();

      // Mostrar progreso de subida
      final cubit = context.read<EvidenceSubmissionCubit>();

      List<String> uploadedPhotoUrls = [];

      try {
        // Subir fotos con callback de progreso
        uploadedPhotoUrls = await mediaUploadService.uploadMultiplePhotos(
          photoFiles: _selectedImages,
          category: 'challenge_evidence',
          isPublic: true,
          uploadPurpose: 'challenge_evidence',
          onProgress: (current, total) {
            // Emitir estado de progreso
            final progress = current / total;
            // El cubit ya maneja esto internamente
          },
        );

        print(
            '✅ [EVIDENCE SUBMISSION] Photos uploaded successfully: ${uploadedPhotoUrls.length} URLs');
      } catch (uploadError) {
        print('❌ [EVIDENCE SUBMISSION] Photo upload failed: $uploadError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir las fotos: $uploadError'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 2. Crear parámetros de evidencia con URLs reales
      final evidenceParams =
          _buildEvidenceParamsWithRealUrls(uploadedPhotoUrls);

      // 3. Enviar evidencia al quiz service
      cubit.submitEvidence(evidenceParams);
    } catch (e) {
      print('❌ [EVIDENCE SUBMISSION] Unexpected error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  SubmitEvidenceParams _buildEvidenceParamsWithRealUrls(
      List<String> realPhotoUrls) {
    print(
        '🔧 [EVIDENCE SUBMISSION] Building evidence params with real photo URLs');
    print('🔧 [EVIDENCE SUBMISSION] Photo URLs: $realPhotoUrls');

    // Construir datos de ubicación
    Map<String, dynamic>? locationData;
    if (_includeLocation && _locationController.text.isNotEmpty) {
      locationData = {
        'locationName': _locationController.text,
        // TODO: Agregar coordenadas GPS reales cuando implementes geolocalización
        'latitude': 19.4326, // Ejemplo: Ciudad de México
        'longitude': -99.1332,
      };
    }

    // Construir datos de medición
    Map<String, dynamic>? measurementData;
    if (_includeMeasurements) {
      measurementData = {};
      if (_weightController.text.isNotEmpty) {
        measurementData['weight'] = _weightController.text.trim();
      }
      if (_volumeController.text.isNotEmpty) {
        measurementData['volume'] = _volumeController.text.trim();
      }
      if (_quantityController.text.isNotEmpty) {
        measurementData['quantity'] = _quantityController.text.trim();
      }
    }

    // Metadata adicional
    final metadata = {
      'submissionDate': DateTime.now().toIso8601String(),
      'challengeCategory': widget.challenge.category,
      'challengeTitle': widget.challenge.title,
      'challengeId': widget.challenge.id,
      'appVersion': '1.0.0',
      'platform': 'mobile',
      'totalPhotos': realPhotoUrls.length,
      'submissionMethod': 'mobile_app',
    };

    return SubmitEvidenceParams(
      userChallengeId: widget.userChallengeId,
      submissionType: _selectedSubmissionType,
      contentText: _descriptionController.text.trim(),
      mediaUrls: realPhotoUrls, // 🔧 USAR URLs REALES DE FOTOS SUBIDAS
      locationData: locationData,
      measurementData: measurementData,
      metadata: metadata,
    );
  }

 bool _validateSelectedImages() {
    if (_selectedImages.isEmpty) {
      _showValidationError('Debes seleccionar al menos una foto de evidencia');
      return false;
    }

    if (_selectedImages.length > 5) {
      _showValidationError('Máximo 5 fotos permitidas');
      return false;
    }

    // Validar cada archivo
    final mediaUploadService = getIt<MediaUploadService>();
    final validationErrors = mediaUploadService.validateMultipleFiles(_selectedImages);

    if (validationErrors.isNotEmpty) {
      _showValidationError(validationErrors.first);
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  SubmitEvidenceParams _buildEvidenceParams() {
    // Por ahora usamos URLs de ejemplo, en producción deberías subir las imágenes primero
    final mediaUrls = _selectedImages
        .map((file) =>
            'https://example.com/uploads/${file.path.split('/').last}')
        .toList();

    // Construir datos de ubicación
    Map<String, dynamic>? locationData;
    if (_includeLocation && _locationController.text.isNotEmpty) {
      locationData = {
        'locationName': _locationController.text,
        // TODO: Agregar coordenadas GPS reales
        'latitude': 19.4326, // Ejemplo: Ciudad de México
        'longitude': -99.1332,
      };
    }

    // Construir datos de medición
    Map<String, dynamic>? measurementData;
    if (_includeMeasurements) {
      measurementData = {};
      if (_weightController.text.isNotEmpty) {
        measurementData['weight'] = _weightController.text;
      }
      if (_volumeController.text.isNotEmpty) {
        measurementData['volume'] = _volumeController.text;
      }
      if (_quantityController.text.isNotEmpty) {
        measurementData['quantity'] = _quantityController.text;
      }
    }

    // Metadata adicional
    final metadata = {
      'submissionDate': DateTime.now().toIso8601String(),
      'challengeCategory': widget.challenge.category,
      'appVersion': '1.0.0',
      'platform': 'mobile',
    };

    return SubmitEvidenceParams(
      userChallengeId: widget.userChallengeId,
      submissionType: _selectedSubmissionType,
      contentText: _descriptionController.text.trim(),
      mediaUrls: mediaUrls,
      locationData: locationData,
      measurementData: measurementData,
      metadata: metadata,
    );
  }

  
void _removeImage(int index) {
  if (index >= 0 && index < _selectedImages.length) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto eliminada'),
        backgroundColor: AppColors.info,
        duration: Duration(seconds: 1),
      ),
    );
  }
}

}
