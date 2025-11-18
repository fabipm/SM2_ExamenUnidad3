import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/layout_viewmodel.dart';
import 'tabs/home_tab_page.dart';
import 'tabs/planes_tab_page.dart';
import 'tabs/transacciones_tab_page.dart';
import 'tabs/reportes_tab_page.dart';
import 'tabs/analysis_tab_page.dart';
import 'widgets/profile_drawer.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

// LAYOUT PRINCIPAL - Solo contiene la estructura de navegación
class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  // Colores específicos para cada tab
  Color _getTabColor(int index) {
    switch (index) {
      case 0: // Home - Inicio
        return AppColors.redCoral;
      case 1: // Planes
        return AppColors.greenJade;
      case 2: // Análisis IA
        return AppColors.blackGrey;
      case 3: // Transacciones
        return AppColors.pinkPastel;
      case 4: // Reportes
        return AppColors.yellowPastel;
      default:
        return AppColors.blueClassic;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(layoutViewModelProvider);

    // Lista de páginas para IndexedStack - PATRÓN CONSISTENTE DE TABS
    // Reordenadas para poner Análisis IA en el centro (posición 2)
    final pages = [
      const HomeTabPage(), // ✅ REAL: Tab que llama a HomeView
      const PlanesTabPage(), // ❌ PLACEHOLDER: Tab con contenido temporal
      const AnalysisTabPage(), // ✅ REAL: Tab de análisis IA - CENTRO
      const TransaccionesTabPage(), // ✅ REAL: Tab que llama a TransaccionesView
      const ReportesTabPage(), // ❌ PLACEHOLDER: Tab con contenido temporal
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTab.title),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.blackGrey,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implementar búsqueda
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Búsqueda próximamente'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const ProfileDrawer(),
      body: IndexedStack(index: currentTab.tabIndex, children: pages),
      bottomNavigationBar: _buildCustomBottomNavigationBar(
        context,
        ref,
        currentTab.tabIndex,
      ),
      floatingActionButton: _buildAICenterButton(
        context,
        ref,
        currentTab.tabIndex,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Botón flotante central para Análisis IA - Diseño premium minimalista
  Widget _buildAICenterButton(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    final isAISelected = currentIndex == 2;
    final aiColor = _getTabColor(2);

    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        gradient: isAISelected
            ? LinearGradient(
                colors: [aiColor, aiColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isAISelected ? null : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAISelected
              ? Colors.transparent
              : AppColors.greyMedium.withOpacity(0.3),
          width: isAISelected ? 0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isAISelected
                ? aiColor.withOpacity(0.4)
                : AppColors.blackGrey.withOpacity(0.08),
            blurRadius: isAISelected ? 16 : 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(layoutViewModelProvider.notifier).navigateToIndex(2);
          },
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SvgPicture.asset(
              'assets/gemini-color.svg',
              width: 28,
              height: 28,
              colorFilter: isAISelected
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  // Barra de navegación personalizada con diseño premium minimalista
  Widget _buildCustomBottomNavigationBar(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      elevation: 0,
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.greyMedium.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                context,
                ref,
                0,
                Icons.home_outlined,
                Icons.home_rounded,
                AppStrings.navHome,
                currentIndex,
                _getTabColor(0),
              ),
            ),
            Expanded(
              child: _buildNavItem(
                context,
                ref,
                1,
                Icons.savings_outlined,
                Icons.savings_rounded,
                AppStrings.navPlanes,
                currentIndex,
                _getTabColor(1),
              ),
            ),
            const SizedBox(width: 64), // Espacio para el FAB central
            Expanded(
              child: _buildNavItem(
                context,
                ref,
                3,
                Icons.add_circle_outline_rounded,
                Icons.add_circle_rounded,
                AppStrings.navTransactions,
                currentIndex,
                _getTabColor(3),
              ),
            ),
            Expanded(
              child: _buildNavItem(
                context,
                ref,
                4,
                Icons.analytics_outlined,
                Icons.analytics_rounded,
                AppStrings.navReports,
                currentIndex,
                _getTabColor(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget individual para cada item de navegación - Diseño iOS minimalista
  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int currentIndex,
    Color tabColor,
  ) {
    final isSelected = currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(layoutViewModelProvider.notifier).navigateToIndex(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador superior minimalista
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.5,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: tabColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),

              // Icono con animación
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  key: ValueKey(isSelected),
                  color: isSelected ? tabColor : AppColors.greyDark,
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),

              // Texto con animación - AJUSTADO PARA NO OVERFLOW
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? tabColor : AppColors.greyDark,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.0,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
