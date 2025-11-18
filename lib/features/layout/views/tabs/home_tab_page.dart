import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/views/home_view.dart';

// TAB CONTAINER: Este tab llama al módulo de home funcional
class HomeTabPage extends ConsumerWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Llamar directamente a la vista de home
    return const HomeView();
  }
}
