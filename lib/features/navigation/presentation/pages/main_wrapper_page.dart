// lib/features/navigation/presentation/pages/main_wrapper_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../cubit/navigation_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../learning/presentation/pages/learning_main_page.dart';
import '../../../challenges/presentation/pages/challenges_main_page.dart';
import '../../../trivia/presentation/pages/trivia_main_page.dart';
import '../../../companion/presentation/pages/companion_main_page.dart';
import '../../../contact/presentation/pages/contact_main_page.dart';
import '../../../profile/presentation/pages/profile_main_page.dart';
import '../widgets/side_nav_bar.dart';

class MainWrapperPage extends StatelessWidget {
  const MainWrapperPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 🆕 PROPORCIONAR AUTHCUBIT CON VALIDACIÓN AUTOMÁTICA
        BlocProvider<AuthCubit>(
          create: (context) {
            final authCubit = getIt<AuthCubit>();
            // Validar token automáticamente al iniciar
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authCubit.validateCurrentToken();
            });
            return authCubit;
          },
        ),
        // NAVIGATION CUBIT
        BlocProvider<NavigationCubit>(
          create: (_) => getIt<NavigationCubit>(),
        ),
      ],
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
          drawer: const SideNavBar(),
          body: _buildCurrentPage(context, state.currentTab),
        );
      },
    );
  }

  Widget _buildCurrentPage(BuildContext context, NavigationTab currentTab) {
    switch (currentTab) {
      case NavigationTab.home:
        return const HomePage();
      
      case NavigationTab.learn:
        return const LearningMainPage();
      
      case NavigationTab.companion:
        return const CompanionMainPage();
        
      case NavigationTab.trivia:
        return const TriviaMainPage();
        
      case NavigationTab.challenges:
        return const ChallengesMainPage();
        
      case NavigationTab.contact:
        return const ContactMainPage();
        
      case NavigationTab.profile:
        return const ProfileMainPage();
      
      default:
        return const HomePage();
    }
  }
}