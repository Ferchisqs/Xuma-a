// lib/features/learning/presentation/pages/new_learning_main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../cubit/content_cubit.dart';
import '../widgets/topic_grid_widget.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';

class NewLearningMainPage extends StatelessWidget {
  const NewLearningMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContentCubit>()..loadTopics(),
      child: const _NewLearningMainContent(),
    );
  }
}

class _NewLearningMainContent extends StatelessWidget {
  const _NewLearningMainContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SideNavBar(),
      appBar: const CustomAppBar(
        title: 'Aprendamos',
        showDrawerButton: true,
        showEcoTip: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ContentCubit>().refreshTopics();
        },
        child: BlocBuilder<ContentCubit, ContentState>(
          builder: (context, state) {
            print('🎯 [LEARNING PAGE] State: $state');
            
            if (state is ContentLoading) {
              return const Center(
                child: EcoLoadingWidget(
                  message: 'Cargando temas...',
                ),
              );
            }

            if (state is ContentError) {
              return Center(
                child: EcoErrorWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<ContentCubit>().loadTopics();
                  },
                ),
              );
            }

            if (state is TopicsLoaded) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con información
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.earthGradient,
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¡Aprende y protege!',
                                      style: AppTextStyles.h3.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Descubre cómo cuidar nuestro planeta',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.topics.length} temas disponibles',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Título de temas
                    Text(
                      'Temas',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid de temas
                    TopicGridWidget(topics: state.topics),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}