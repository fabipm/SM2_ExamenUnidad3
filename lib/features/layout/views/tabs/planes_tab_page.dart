import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../financial_plans/views/financial_plans_page.dart';

// TAB CONTAINER: Solo llama al módulo de planes financieros
class PlanesTabPage extends ConsumerWidget {
  const PlanesTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Llamar directo al módulo - sin duplicar lógica
    return const FinancialPlansPage();
  }
}
