import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estados posibles para la navegación en el Layout Principal
/// NOTA: Análisis IA está en el centro (posición 2) para mayor prominencia
enum LayoutNavigationTab {
  home(0, 'Inicio'),
  financialPlans(1, 'Planes'),
  analysis(2, 'Análisis IA'), // ✨ CENTRO - Característica innovadora
  transactions(3, 'Registro'),
  reports(4, 'Reportes');

  const LayoutNavigationTab(this.tabIndex, this.title);
  final int tabIndex;
  final String title;
}

/// ViewModel para manejar el estado del Layout Principal
class LayoutViewModel extends StateNotifier<LayoutNavigationTab> {
  LayoutViewModel() : super(LayoutNavigationTab.home);

  /// Cambiar a un tab específico
  void navigateToTab(LayoutNavigationTab tab) {
    state = tab;
  }

  /// Cambiar por índice
  void navigateToIndex(int index) {
    final tab = LayoutNavigationTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => LayoutNavigationTab.home,
    );
    state = tab;
  }

  /// Getter para verificar si el FAB debería mostrarse
  bool get shouldShowFab {
    return true; // Mostrar el FAB en todos los tabs
  }

  /// Getter para obtener el título del AppBar
  String get appBarTitle {
    return state.title;
  }
}

/// Provider para el LayoutViewModel
final layoutViewModelProvider =
    StateNotifierProvider<LayoutViewModel, LayoutNavigationTab>(
      (ref) => LayoutViewModel(),
    );
