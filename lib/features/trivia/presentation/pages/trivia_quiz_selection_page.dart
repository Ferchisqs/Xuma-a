// lib/features/trivia/presentation/pages/trivia_quiz_selection_page.dart - CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart' as core_styles;
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../cubit/trivia_cubit.dart';
import 'trivia_quiz_game_page.dart';

class TriviaQuizSelectionPage extends StatelessWidget {
  final String topicId;
  final String categoryTitle;

  const TriviaQuizSelectionPage({
    Key? key,
    required this.topicId,
    required this.categoryTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TriviaCubit>()..loadQuizzesByTopic(topicId),
      child: _TriviaQuizSelectionContent(
        topicId: topicId,
        categoryTitle: categoryTitle,
      ),
    );
  }
}

class _TriviaQuizSelectionContent extends StatefulWidget {
  final String topicId;
  final String categoryTitle;

  const _TriviaQuizSelectionContent({
    required this.topicId,
    required this.categoryTitle,
  });

  @override
  State<_TriviaQuizSelectionContent> createState() => 
      _TriviaQuizSelectionContentState();
}

class _TriviaQuizSelectionContentState extends State<_TriviaQuizSelectionContent> {
  @override
  void initState() {
    super.initState();
    print('🎯 [QUIZ SELECTION] Initializing for topic: ${widget.topicId}');
    print('🎯 [QUIZ SELECTION] Category: ${widget.categoryTitle}');
    
    // Debug: Mostrar información de configuración
    _debugApiConfiguration();
  }

  void _debugApiConfiguration() {
    print('🔧 [QUIZ SELECTION] === API CONFIGURATION DEBUG ===');
    print('🔧 [QUIZ SELECTION] Topics URL: https://content-service-xumaa-production.up.railway.app/api/content/topics');
    print('🔧 [QUIZ SELECTION] Quiz URL: https://quiz-challenge-service-production.up.railway.app/api/quiz');
    print('🔧 [QUIZ SELECTION] Expected endpoint: /api/quiz/by-topic/${widget.topicId}');
    print('🔧 [QUIZ SELECTION] =====================================');
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          'Quizzes: ${widget.categoryTitle}',
          style: core_styles.AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Debug manual
              _showDebugDialog(context);
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: BlocBuilder<TriviaCubit, TriviaState>(
        builder: (context, state) {
          print('🔍 [QUIZ SELECTION] Current state: ${state.runtimeType}');
          
          if (state is TriviaQuizzesLoading) {
            return const Center(
              child: EcoLoadingWidget(
                message: 'Cargando quizzes...',
              ),
            );
          }
          
          if (state is TriviaError) {
            return _buildErrorState(context, state.message);
          }
          
          if (state is TriviaQuizzesLoaded) {
            return _buildQuizzesList(context, state.quizzes);
          }
          
          // Estado inicial - Mostrar información de debugging
          return _buildInitialState(context);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar quizzes',
                    style: core_styles.AppTextStyles.h4.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: core_styles.AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Información de debugging
                  Container(
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
                          style: core_styles.AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Topic ID: ${widget.topicId}',
                          style: core_styles.AppTextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Category: ${widget.categoryTitle}',
                          style: core_styles.AppTextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Expected URL: /api/quiz/by-topic/${widget.topicId}',
                          style: core_styles.AppTextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    print('🔄 [QUIZ SELECTION] Retrying load quizzes for topic: ${widget.topicId}');
                    context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _showDebugDialog(context),
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Volver a categorías',
                style: core_styles.AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de carga
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Preparando quizzes',
              style: core_styles.AppTextStyles.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Categoría: ${widget.categoryTitle}',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Información del endpoint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Conectando con:',
                    style: core_styles.AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/api/quiz/by-topic/${widget.topicId}',
                    style: core_styles.AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () {
                context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Cargar Quizzes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: () => _showDebugDialog(context),
              icon: const Icon(Icons.settings),
              label: const Text('Configuración Debug'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesList(BuildContext context, List<Map<String, dynamic>> quizzes) {
    print('🎯 [QUIZ SELECTION] Building list with ${quizzes.length} quizzes');
    
    if (quizzes.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header informativo mejorado
          _buildSuccessHeader(quizzes.length),
          
          const SizedBox(height: 24),
          
          Text(
            'Quizzes Disponibles (${quizzes.length})',
            style: core_styles.AppTextStyles.h4.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de quizzes
          Expanded(
            child: ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return _buildQuizCard(context, quiz, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(int quizCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Quizzes cargados exitosamente!',
                  style: core_styles.AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Categoría: ${widget.categoryTitle} • $quizCount quizzes',
                  style: core_styles.AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '✓ Conectado',
              style: core_styles.AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Map<String, dynamic> quiz, int index) {
    // Extraer datos del quiz con fallbacks mejorados
    final quizId = quiz['id']?.toString() ?? 'quiz_${widget.topicId}_$index';
    final title = quiz['title']?.toString() ?? 
                  quiz['name']?.toString() ?? 
                  'Quiz ${index + 1}';
    final description = quiz['description']?.toString() ?? 
                       'Pon a prueba tus conocimientos sobre ${widget.categoryTitle}';
    final questionsCount = _extractInt(quiz['questionsCount']) ?? 
                          _extractInt(quiz['questions']) ?? 
                          _extractInt(quiz['totalQuestions']) ?? 
                          10;
    final duration = _extractInt(quiz['duration']) ?? 
                    _extractInt(quiz['estimatedTime']) ?? 
                    _extractInt(quiz['timeLimitMinutes']) ?? 
                    5;
    final points = _extractInt(quiz['points']) ?? 
                  _extractInt(quiz['totalPoints']) ?? 
                  _extractInt(quiz['pointsReward']) ?? 
                  questionsCount * 5;
    final difficulty = quiz['difficultyLevel']?.toString() ?? 'medium';
    final isPublished = quiz['isPublished'] ?? true;

    print('🔍 [QUIZ SELECTION] Quiz $index: ID=$quizId, Title=$title, Questions=$questionsCount, Published=$isPublished');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isPublished ? null : Border.all(
          color: AppColors.warning.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: isPublished ? AppColors.primaryGradient : LinearGradient(
              colors: [AppColors.warning, AppColors.warning.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: isPublished ? Text(
              '${index + 1}',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ) : const Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: core_styles.AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isPublished)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BORRADOR',
                  style: core_styles.AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: core_styles.AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip(
                  '$questionsCount preguntas',
                  Icons.quiz,
                  AppColors.info,
                ),
                _buildInfoChip(
                  '${duration} min',
                  Icons.timer,
                  AppColors.warning,
                ),
                _buildInfoChip(
                  '+$points pts',
                  Icons.eco,
                  AppColors.success,
                ),
                _buildDifficultyChip(difficulty),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPublished ? AppColors.primary.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isPublished ? 'JUGAR' : 'VISTA PREVIA',
            style: core_styles.AppTextStyles.bodySmall.copyWith(
              color: isPublished ? AppColors.primary : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          print('🎯 [QUIZ SELECTION] Starting quiz: $quizId (Published: $isPublished)');
          
          if (!isPublished) {
            // Mostrar advertencia para quizzes no publicados
            _showUnpublishedQuizDialog(context, title, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TriviaQuizGamePage(
                    quizId: quizId,
                    topicId: widget.topicId,
                  ),
                ),
              );
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TriviaQuizGamePage(
                  quizId: quizId,
                  topicId: widget.topicId,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: core_styles.AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color = AppColors.info;
    String label = difficulty;
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'fácil':
        color = AppColors.success;
        label = 'Fácil';
        break;
      case 'medium':
      case 'medio':
        color = AppColors.warning;
        label = 'Medio';
        break;
      case 'hard':
      case 'difícil':
        color = AppColors.error;
        label = 'Difícil';
        break;
    }
    
    return _buildInfoChip(label, Icons.bar_chart, color);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay quizzes disponibles',
              style: core_styles.AppTextStyles.h4.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron quizzes para "${widget.categoryTitle}".\n\nEsto puede ser porque:\n• El topic no tiene quizzes asignados\n• Los quizzes no están publicados\n• Hay un problema de conectividad',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TriviaCubit>().loadQuizzesByTopic(widget.topicId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showDebugDialog(context),
              icon: const Icon(Icons.bug_report),
              label: const Text('Ver Información Debug'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnpublishedQuizDialog(BuildContext context, String quizTitle, VoidCallback onContinue) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Quiz en desarrollo',
                style: core_styles.AppTextStyles.h4.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El quiz "$quizTitle" está en modo borrador y puede tener contenido incompleto o en desarrollo.\n\n¿Quieres continuar de todas formas?',
          style: core_styles.AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text(
              'Continuar',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Información Debug',
              style: core_styles.AppTextStyles.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebugItem('Topic ID', widget.topicId),
              _buildDebugItem('Category', widget.categoryTitle),
              _buildDebugItem('Expected Endpoint', '/api/quiz/by-topic/${widget.topicId}'),
              _buildDebugItem('Quiz Service URL', 'quiz-challenge-service-production.up.railway.app'),
              _buildDebugItem('Content Service URL', 'content-service-xumaa-production.up.railway.app'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Si continúas viendo errores, verifica:\n'
                  '1. Que el Topic ID existe en el backend\n'
                  '2. Que hay quizzes asignados a este topic\n'
                  '3. Que los servicios están ejecutándose\n'
                  '4. Que la autenticación es correcta',
                  style: core_styles.AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TriviaCubit>().debugCurrentState();
              context.read<TriviaCubit>().printFlowStatus();
            },
            child: Text(
              'Print Debug',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Cerrar',
              style: core_styles.AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: core_styles.AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: core_styles.AppTextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para extraer integers de forma segura
  int? _extractInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}