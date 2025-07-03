import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

enum NavigationTab {
  home,
  news,
  learn,
  projects,
  challenges,
  community,
  contact
}

// Navigation State
abstract class NavigationState extends Equatable {
  final NavigationTab currentTab;
  final bool isDrawerOpen;
  
  const NavigationState({
    required this.currentTab,
    this.isDrawerOpen = false,
  });
  
  @override
  List<Object> get props => [currentTab, isDrawerOpen];
}

class NavigationInitial extends NavigationState {
  const NavigationInitial({
    required NavigationTab currentTab,
    bool isDrawerOpen = false,
  }) : super(currentTab: currentTab, isDrawerOpen: isDrawerOpen);
}

class NavigationChanged extends NavigationState {
  const NavigationChanged({
    required NavigationTab currentTab,
    bool isDrawerOpen = false,
  }) : super(currentTab: currentTab, isDrawerOpen: isDrawerOpen);
}

// Navigation Cubit
@injectable
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationInitial(currentTab: NavigationTab.home));

  void changeTab(NavigationTab tab) {
    if (state.currentTab != tab) {
      emit(NavigationChanged(currentTab: tab, isDrawerOpen: false));
    }
  }

  void toggleDrawer() {
    emit(NavigationChanged(
      currentTab: state.currentTab,
      isDrawerOpen: !state.isDrawerOpen,
    ));
  }

  void closeDrawer() {
    if (state.isDrawerOpen) {
      emit(NavigationChanged(
        currentTab: state.currentTab,
        isDrawerOpen: false,
      ));
    }
  }

  // Navigation methods
  void goToHome() => changeTab(NavigationTab.home);
  void goToNews() => changeTab(NavigationTab.news);
  void goToLearn() => changeTab(NavigationTab.learn);
  void goToProjects() => changeTab(NavigationTab.projects);
  void goToChallenges() => changeTab(NavigationTab.challenges);
  void goToCommunity() => changeTab(NavigationTab.community);
  void goToContact() => changeTab(NavigationTab.contact);
}