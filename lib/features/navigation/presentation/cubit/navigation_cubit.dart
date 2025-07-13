import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

enum NavigationTab {
  home,
  companion,
  learn,
  trivia,
  challenges,
  contact,
  profile    // 🆕 AGREGADO PERFIL
}

// Navigation State - Simplificada y más consistente
class NavigationState extends Equatable {
  final NavigationTab currentTab;
  final bool isDrawerOpen;
  
  const NavigationState({
    required this.currentTab,
    this.isDrawerOpen = false,
  });
  
  @override
  List<Object> get props => [currentTab, isDrawerOpen];

  // Helper method para crear copias del estado
  NavigationState copyWith({
    NavigationTab? currentTab,
    bool? isDrawerOpen,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
    );
  }
}

// Navigation Cubit
@injectable
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState(currentTab: NavigationTab.home));

  void changeTab(NavigationTab tab) {
    if (state.currentTab != tab) {
      emit(state.copyWith(currentTab: tab, isDrawerOpen: false));
    }
  }

  void toggleDrawer() {
    emit(state.copyWith(isDrawerOpen: !state.isDrawerOpen));
  }

  void closeDrawer() {
    if (state.isDrawerOpen) {
      emit(state.copyWith(isDrawerOpen: false));
    }
  }

  void openDrawer() {
    if (!state.isDrawerOpen) {
      emit(state.copyWith(isDrawerOpen: true));
    }
  }

  // Navigation methods actualizados
  void goToHome() => changeTab(NavigationTab.home);
  void goToCompanion() => changeTab(NavigationTab.companion);
  void goToLearn() => changeTab(NavigationTab.learn);
  void goToTrivia() => changeTab(NavigationTab.trivia);
  void goToChallenges() => changeTab(NavigationTab.challenges);
  void goToContact() => changeTab(NavigationTab.contact);
  void goToProfile() => changeTab(NavigationTab.profile); // 🆕 NUEVO

  // Helper methods para verificar el estado actual
  bool get isHome => state.currentTab == NavigationTab.home;
  bool get isCompanion => state.currentTab == NavigationTab.companion;
  bool get isLearn => state.currentTab == NavigationTab.learn;
  bool get isTrivia => state.currentTab == NavigationTab.trivia;
  bool get isChallenges => state.currentTab == NavigationTab.challenges;
  bool get isContact => state.currentTab == NavigationTab.contact;
  bool get isProfile => state.currentTab == NavigationTab.profile; // 🆕 NUEVO

  // Method para debugging
  void debugCurrentState() {
    print('📍 Current Navigation State:');
    print('   - Tab: ${state.currentTab}');
    print('   - Drawer Open: ${state.isDrawerOpen}');
  }
}