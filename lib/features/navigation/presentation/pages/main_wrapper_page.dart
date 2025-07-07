import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../cubit/navigation_cubit.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../learning/presentation/pages/learning_main_page.dart';
// import '../../../challenges/presentation/pages/challenges_page.dart'; // 🔄 IMPORT REAL
import '../../../shared/pages/placeholder_pages.dart';

class MainWrapperPage extends StatelessWidget {
  const MainWrapperPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NavigationCubit>(),
      child: const _MainWrapperContent(),
    );
  }
}

class _MainWrapperContent extends StatelessWidget {
  const _MainWrapperContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          // 🔄 NO DRAWER AQUÍ - cada página maneja su propio drawer
          body: _buildCurrentPage(state.currentTab),
        );
      },
    );
  }

  Widget _buildCurrentPage(NavigationTab currentTab) {
    switch (currentTab) {
      case NavigationTab.home:
        return const HomePage();
      
      case NavigationTab.learn:
        return const LearningMainPage();
      
      // case NavigationTab.companion: // 🔄 Nuevo tab
      //   return const CompanionPage();
        
      // case NavigationTab.trivia: // 🔄 Nuevo tab
      //   return const TriviaPage();
        
      case NavigationTab.challenges: // 🔄 USAR IMPLEMENTACIÓN REAL
        return const ChallengesPage();
        
      case NavigationTab.contact:
        return const ContactPage();
      
      default:
        return const HomePage();
    }
  }
}