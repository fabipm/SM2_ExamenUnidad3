import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/categoria_model.dart';
import '../viewmodels/categoria_viewmodel.dart';

// Provider para el ViewModel de categorías
final categoriaViewModelProvider = ChangeNotifierProvider<CategoriaViewModel>(
  (ref) => CategoriaViewModel(),
);

class GestionarCategoriasView extends ConsumerStatefulWidget {
  final String idUsuario;
  final TipoCategoria tipo;

  const GestionarCategoriasView({
    Key? key,
    required this.idUsuario,
    required this.tipo,
  }) : super(key: key);

  @override
  ConsumerState<GestionarCategoriasView> createState() =>
      _GestionarCategoriasViewState();
}

class _GestionarCategoriasViewState
    extends ConsumerState<GestionarCategoriasView> {
  @override
  void initState() {
    super.initState();
    // Cargar TODAS las categorías al iniciar (por defecto + personalizadas)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(categoriaViewModelProvider)
          .cargarCategorias(widget.idUsuario, widget.tipo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(categoriaViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestionar ${widget.tipo == TipoCategoria.ingreso ? 'Ingresos' : 'Egresos'}',
        ),
        backgroundColor: widget.tipo == TipoCategoria.ingreso
            ? Colors.green
            : Colors.deepOrange,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Sección para agregar nueva categoría
          _buildAgregarCategoriaSection(context, viewModel),

          const Divider(height: 1),

          // Lista de categorías personalizadas
          Expanded(child: _buildListaCategorias(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildAgregarCategoriaSection(
    BuildContext context,
    CategoriaViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar Nueva Categoría',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.tipo == TipoCategoria.ingreso
                  ? Colors.green[700]
                  : Colors.deepOrange[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: viewModel.nombreCategoriaController,
                  decoration: InputDecoration(
                    hintText: 'Nombre de la categoría',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: widget.tipo == TipoCategoria.ingreso
                          ? Colors.green
                          : Colors.deepOrange,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.tipo == TipoCategoria.ingreso
                            ? Colors.green
                            : Colors.deepOrange,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _agregarCategoria(context, viewModel),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: viewModel.isLoading
                    ? null
                    : () => _agregarCategoria(context, viewModel),
                icon: viewModel.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add, size: 20),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.tipo == TipoCategoria.ingreso
                      ? Colors.green
                      : Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (viewModel.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListaCategorias(
    BuildContext context,
    CategoriaViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.categorias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.categorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes categorías',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega una nueva categoría arriba',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.categorias.length,
      itemBuilder: (context, index) {
        final categoria = viewModel.categorias[index];
        return _buildCategoriaItem(context, viewModel, categoria, index);
      },
    );
  }

  Widget _buildCategoriaItem(
    BuildContext context,
    CategoriaViewModel viewModel,
    CategoriaModel categoria,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                (widget.tipo == TipoCategoria.ingreso
                        ? Colors.green
                        : Colors.deepOrange)
                    .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: widget.tipo == TipoCategoria.ingreso
                ? Colors.green
                : Colors.deepOrange,
            size: 20,
          ),
        ),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          categoria.esPersonalizada ? 'Personalizada' : 'Por defecto',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontStyle: categoria.esPersonalizada ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editarCategoria(context, viewModel, categoria),
              icon: Icon(
                Icons.edit_outlined,
                color: Colors.blue[600],
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed: () =>
                  _confirmarEliminar(context, viewModel, categoria),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _agregarCategoria(
    BuildContext context,
    CategoriaViewModel viewModel,
  ) async {
    final resultado = await viewModel.agregarCategoriaPersonalizada(
      widget.idUsuario,
      widget.tipo,
    );

    if (resultado && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Categoría agregada correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Limpiar el error después del éxito
      viewModel.limpiarError();
    }
  }

  Future<void> _editarCategoria(
    BuildContext context,
    CategoriaViewModel viewModel,
    CategoriaModel categoria,
  ) async {
    viewModel.editarCategoriaController.text = categoria.nombre;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoría'),
        content: TextField(
          controller: viewModel.editarCategoriaController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await viewModel.editarCategoriaPersonalizada(
                categoria.id,
                widget.idUsuario,
                widget.tipo,
              );
              Navigator.of(context).pop(success);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Categoría editada correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    CategoriaViewModel viewModel,
    CategoriaModel categoria,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${categoria.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final resultado = await viewModel.eliminarCategoriaPersonalizada(
        categoria.id,
        widget.idUsuario,
        widget.tipo,
      );

      if (resultado && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Categoría eliminada correctamente'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
