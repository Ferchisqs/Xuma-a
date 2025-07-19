// lib/features/navigation/presentation/pages/main_wrapper_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../cubit/navigation_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../learning/presentation/pages/learning_main_page.dart';
import '../../../challenges/presentation/pages/challenges_main_page.dart';
import '../../../trivia/presentation/pages/trivia_main_page.dart';
import '../../../companion/presentation/pages/companion_main_page.dart' as companion;
import '../../../contact/presentation/pages/contact_main_page.dart' as contact;
import '../../../profile/presentation/pages/profile_main_page.dart';
import '../../../news/presentation/pages/news_main_page.dart';
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
        // 🔧 SOLUCIÓN: Scaffold principal con drawer que se pasa a las páginas
        return Scaffold(
          // 🔧 MANTENER EL DRAWER EN EL SCAFFOLD PRINCIPAL
          drawer: const SideNavBar(),
          // 🔧 IMPORTANTE: NO poner body aquí, sino delegar a cada página
          body: _buildCurrentPageWithDrawer(context, state.currentTab),
          onDrawerChanged: (isOpened) {
            if (!isOpened) {
              context.read<NavigationCubit>().closeDrawer();
            } else {
              context.read<NavigationCubit>().openDrawer();
            }
          },
        );
      },
    );
  }

  // 🔧 CONSTRUIR PÁGINA ACTUAL PERO PASANDO EL CONTEXTO CON DRAWER
  Widget _buildCurrentPageWithDrawer(BuildContext context, NavigationTab currentTab) {
    // 🔧 CADA PÁGINA TENDRÁ ACCESO AL DRAWER A TRAVÉS DEL CONTEXTO
    switch (currentTab) {
      case NavigationTab.home:
        return const _PageWrapper(child: HomePage());
      
      case NavigationTab.learn:
        return const _PageWrapper(child: LearningMainPage());
      
      case NavigationTab.companion:
        return const _PageWrapper(child: companion.CompanionMainPage());
        
      case NavigationTab.trivia:
        return const _PageWrapper(child: TriviaMainPage());
        
      case NavigationTab.challenges:
        return const _PageWrapper(child: ChallengesMainPage());
        
      case NavigationTab.contact:
        return const _PageWrapper(child: contact.CompanionMainPage()); // Aquí probablemente debería ser ContactMainPage
        
      case NavigationTab.profile:
        return const _PageWrapper(child: ProfileMainPage());
      
      case NavigationTab.news:
        return const _PageWrapper(child: NewsMainPage());
      
      default:
        return const _PageWrapper(child: HomePage());
    }
  }
}

// 🔧 WRAPPER QUE ELIMINA SCAFFOLD DE LAS PÁGINAS PERO MANTIENE EL CONTENIDO
class _PageWrapper extends StatelessWidget {
  final Widget child;
  
  const _PageWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // 🔧 SI LA PÁGINA CHILD ES UN SCAFFOLD, EXTRAER SU CONTENIDO
    if (child is Scaffold) {
      final scaffold = child as Scaffold;
      
      return Column(
        children: [
          // AppBar de la página
          if (scaffold.appBar != null)
            PreferredSize(
              preferredSize: scaffold.appBar!.preferredSize,
              child: scaffold.appBar!,
            ),
          // Body de la página
          Expanded(
            child: scaffold.body ?? const SizedBox.shrink(),
          ),
        ],
      );
    }
    
    // Si no es Scaffold, devolver tal como está
    return child;
  }
}