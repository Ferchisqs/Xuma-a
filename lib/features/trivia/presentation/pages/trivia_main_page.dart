import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../di/injection.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../navigation/presentation/widgets/custom_app_bar.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../cubit/trivia_cubit.dart';
import '../widgets/trivia_category_grid.dart';
import '../widgets/trivia_header_widget.dart';

class TriviaMainPage extends StatelessWidget {
  const TriviaMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<NavigationCubit>(),
      child: BlocProvider(
        create: (_) => getIt<TriviaCubit>()..loadCategories(),
        child: const _TriviaMainContent(),
      ),
    );
  }
}

class _TriviaMainContent extends StatelessWidget {
  const _TriviaMainContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SideNavBar(),
      appBar: const CustomAppBar(
        title: 'Trivias',
        showDrawerButton: true,
        showEcoTip: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<TriviaCubit>().refreshCategories();
        },
        child: BlocBuilder<TriviaCubit, TriviaState>(
          builder: (context, state) {
            if (state is TriviaLoading) {
              return const Center(
                child: EcoLoadingWidget(
                  message: 'Cargando trivias...',
                ),
              );
            }

            if (state is TriviaError) {
              return Center(
                child: EcoErrorWidget(
                  message: state.message,
                  onRetry: () {
                    context.read<TriviaCubit>().loadCategories();
                  },
                ),
              );
            }

            if (state is TriviaLoaded) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con información
                    const TriviaHeaderWidget(),
                    
                    const SizedBox(height: 24),
                    
                    // Título de sección
                    Text(
                      'Selecciona la Categoría',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid de categorías
                    TriviaCategoryGrid(categories: state.categories),
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