// lib/features/challenges/presentation/widgets/evidence_submission_button.dart - NUEVO WIDGET
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/challenge_entity.dart';
import '../pages/evidence_submission_page.dart';

class EvidenceSubmissionButton extends StatelessWidget {
  final ChallengeEntity challenge;
  final String userChallengeId;
  final VoidCallback? onEvidenceSubmitted;

  const EvidenceSubmissionButton({
    Key? key,
    required this.challenge,
    required this.userChallengeId,
    this.onEvidenceSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () => _navigateToEvidenceSubmission(context),
        icon: const Icon(
          Icons.upload_file,
          color: Colors.white,
        ),
        label: Text(
          'Subir Evidencia',
          style: AppTextStyles.buttonLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppColors.success.withOpacity(0.4),
        ),
      ),
    );
  }

  Future<void> _navigateToEvidenceSubmission(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenceSubmissionPage(
          challenge: challenge,
          userChallengeId: userChallengeId,
        ),
      ),
    );

    // Si se envió evidencia exitosamente, ejecutar callback
    if (result == true && onEvidenceSubmitted != null) {
      onEvidenceSubmitted!();
    }
  }
}

// ==================== WIDGET DE ESTADO DE EVIDENCIA ====================

class EvidenceStatusWidget extends StatelessWidget {
  final String status; // 'pending', 'approved', 'rejected'
  final String? message;
  final DateTime? submissionDate;

  const EvidenceStatusWidget({
    Key? key,
    required this.status,
    this.message,
    this.submissionDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getStatusTitle(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (submissionDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Enviado: ${_formatDate(submissionDate!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case 'pending':
        return 'Evidencia en Revisión';
      case 'approved':
        return 'Evidencia Aprobada';
      case 'rejected':
        return 'Evidencia Rechazada';
      default:
        return 'Estado Desconocido';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== WIDGET DE PROGRESO DE EVIDENCIA ====================

class EvidenceProgressWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String message;
  final bool showCancel;
  final VoidCallback? onCancel;

  const EvidenceProgressWidget({
    Key? key,
    required this.progress,
    required this.message,
    this.showCancel = false,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showCancel && onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'Cancelar',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% completado',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGET DE INSTRUCCIONES DE EVIDENCIA ====================

class EvidenceInstructionsWidget extends StatelessWidget {
  final ChallengeEntity challenge;

  const EvidenceInstructionsWidget({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Instrucciones para la Evidencia',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_getInstructionsForCategory(challenge.category)).map((instruction) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instruction,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  List<String> _getInstructionsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'reciclaje':
        return [
          'Toma fotos claras de los materiales antes del reciclaje',
          'Muestra el contenedor o centro de reciclaje donde los depositaste',
          'Incluye una foto con los materiales separados por tipo',
          'Si es posible, agrega datos de peso o cantidad'
        ];
      case 'compostaje':
        return [
          'Fotografía los residuos orgánicos que vas a compostar',
          'Muestra el área o contenedor de compostaje',
          'Toma una foto del proceso (mezclado, volteo, etc.)',
          'Incluye mediciones si tienes (peso, volumen)'
        ];
      case 'energia':
        return [
          'Captura pantallas de medidores de energía antes y después',
          'Fotografía los dispositivos o cambios realizados',
          'Muestra facturas o lecturas de consumo si es posible',
          'Documenta las acciones específicas tomadas'
        ];
      case 'agua':
        return [
          'Toma fotos de medidores de agua o dispositivos de ahorro',
          'Muestra las acciones realizadas (reparaciones, instalaciones)',
          'Incluye mediciones de consumo si están disponibles',
          'Documenta el antes y después de las mejoras'
        ];
      default:
        return [
          'Toma fotos claras que muestren la actividad realizada',
          'Incluye múltiples ángulos para mejor documentación',
          'Agrega descripción detallada de lo que hiciste',
          'Si es posible, incluye datos cuantitativos (cantidad, peso, tiempo)'
        ];
    }
  }
}

// ==================== WIDGET DE TIPS PARA FOTOS ====================

class PhotoTipsWidget extends StatelessWidget {
  const PhotoTipsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tips para Mejores Fotos',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._photoTips.map((tip) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  static const List<String> _photoTips = [
    'Asegúrate de tener buena iluminación',
    'Mantén la cámara estable para evitar fotos borrosas',
    'Incluye objetos de referencia para mostrar tamaño',
    'Toma múltiples ángulos del mismo objeto',
    'Evita fotos con demasiado fondo distractor',
  ];
}