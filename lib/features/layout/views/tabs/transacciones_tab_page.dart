import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/views/transacciones_view.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

// TAB CONTAINER: Este tab llama al módulo de transacciones funcional
class TransaccionesTabPage extends ConsumerWidget {
  const TransaccionesTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    // Llamar directamente al módulo de transacciones
    return TransaccionesView(idUsuario: userId);
  }
}
