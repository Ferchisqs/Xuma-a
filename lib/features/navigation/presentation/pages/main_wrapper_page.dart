import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../cubit/navigation_cubit.dart';
import '../widgets/side_nav_bar.dart';
import '../../../home/presentation/pages/home_page.dart';
// import '../../../shared/pages/placeholder_pages.dart';

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
          drawer: const SideNavBar(),
          body: _buildCurrentPage(state.currentTab),
        );
      },
    );
  }

  Widget _buildCurrentPage(NavigationTab currentTab) {
    switch (currentTab) {
      case NavigationTab.home:
        return const HomePage();
      
       default:
      return const SizedBox.shrink();
      // case NavigationTab.news:
      //   return const NewsPage();
      // case NavigationTab.learn:
      //   return const LearnPage();
      // case NavigationTab.projects:
      //   return const ProjectsPage();
      // case NavigationTab.challenges:
      //   return const ChallengesPage();
      // case NavigationTab.community:
      //   return const CommunityPage();
      // case NavigationTab.contact:
      //   return const ContactPage();
    }
  }
}