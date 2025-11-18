import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reports/views/dashboard_view.dart';

// TAB CONTAINER: Muestra el dashboard financiero con análisis y reportes
class ReportesTabPage extends ConsumerWidget {
  const ReportesTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Llamar al dashboard view con estadísticas y gráficos
    return const DashboardView();
  }
}
