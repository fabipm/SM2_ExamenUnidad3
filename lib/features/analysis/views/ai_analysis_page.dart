import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../financial_plans/services/financial_plans_service.dart';
import '../plan_analyzer.dart';

class AiAnalysisPage extends ConsumerWidget {
  const AiAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis con IA'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                'Análisis inteligente de tus finanzas',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Botones principales en Wrap para evitar overflow
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inicia sesión para ejecutar el análisis')),
                        );
                        return;
                      }

                      final analyzer = PlanAnalyzer();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final result = await analyzer.analyzeUserOverview(user.uid);
                        if (context.mounted) Navigator.of(context).pop();

                        // Evitar bloqueo del Navigator: mostrar bottom sheet en el siguiente frame
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildAnalysisBottomSheet(context, result),
                            ),
                          );
                        });
                      } catch (e) {
                        if (context.mounted) Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al ejecutar análisis: $e')));
                      }
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('Ejecutar análisis'),
                  ),

                  ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inicia sesión para ejecutar el análisis')),
                        );
                        return;
                      }

                      final fps = FinancialPlansService();
                      final now = DateTime.now();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final plan = await fps.getPlanByMonth(userId: user.uid, year: now.year, month: now.month);
                        if (context.mounted) Navigator.of(context).pop();
                        if (plan == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No hay un plan activo para el mes actual')),
                          );
                          return;
                        }

                        final analyzer = PlanAnalyzer();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        final planResult = await analyzer.analyzePlan(plan);
                        if (context.mounted) Navigator.of(context).pop();

                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Análisis del Plan: ${planResult['planName']}'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Uso del presupuesto: ${ (planResult['usagePercentage'] as double).toStringAsFixed(1) }%'),
                                  Text('Gastado total: \$${ (planResult['totalSpent'] as double).toStringAsFixed(2) } / \$${ (planResult['totalBudget'] as double).toStringAsFixed(2) }'),
                                  const SizedBox(height: 8),
                                  const Text('Categorías (resumen):'),
                                  ...((planResult['categories'] as List).map((c) => Text('- ${c['categoryName']}: gastado \$${(c['spent'] as double).toStringAsFixed(2)} / presupuesto \$${(c['budget'] as double).toStringAsFixed(2)} ${ (c['isOverBudget'] as bool) ? "(Sobre presupuesto)" : "" }'))),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al analizar plan: $e')));
                      }
                    },
                    icon: const Icon(Icons.event_note),
                    label: const Text('Analizar plan actual'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Estamos desarrollando un sistema de análisis inteligente que te dará insights personalizados sobre tus finanzas usando inteligencia artificial.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Lista de características próximas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Características que vienen:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(context, Icons.trending_up, 'Análisis de patrones de gasto'),
                    _buildFeatureItem(context, Icons.lightbulb, 'Recomendaciones personalizadas'),
                    _buildFeatureItem(context, Icons.timeline, 'Predicciones financieras'),
                    _buildFeatureItem(context, Icons.insights, 'Insights inteligentes automáticos'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisBottomSheet(BuildContext context, Map<String, dynamic> result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen de Análisis', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Balance'),
            subtitle: Text('\$${(result['balance'] as double).toStringAsFixed(2)}'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('Gastos totales'),
            subtitle: Text('\$${(result['totalGastos'] as double).toStringAsFixed(2)}'),
          ),
        ),
        const SizedBox(height: 8),
        Text('Top categorías', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        ...((result['topCategories'] as List).map((t) => Card(
              child: ListTile(
                leading: const Icon(Icons.label),
                title: Text(t['category']),
                trailing: Text('\$${(t['amount'] as double).toStringAsFixed(2)}'),
              ),
            ))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                // Re-ejecutar el análisis manualmente desde el bottom sheet
                final analyzer = PlanAnalyzer();
                final user = FirebaseAuth.instance.currentUser!;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  final newResult = await analyzer.analyzeUserOverview(user.uid);
                  if (context.mounted) Navigator.of(context).pop(); // cerrar dialog

                  // Reemplazar el bottom sheet con el nuevo resultado
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildAnalysisBottomSheet(context, newResult),
                        ),
                      );
                    });
                  }
                } catch (e) {
                  if (context.mounted) Navigator.of(context).pop();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al ejecutar análisis: $e')));
                }
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Hacer Análisis'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash-exp');
                  final prompt = 'Resume los hallazgos financieros y sugiere 3 acciones concretas para mejorar el balance. Datos: ${result}';
                  final content = [Content.multi([TextPart(prompt)])];
                  final resp = await model.generateContent(content);
                  final text = resp.text ?? 'Sin respuesta';
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Explicación IA'),
                        content: SingleChildScrollView(child: Text(text)),
                        actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cerrar'))],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al generar explicación: $e')));
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Explicar con IA'),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}