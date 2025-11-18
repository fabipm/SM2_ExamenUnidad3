import '../viewmodels/Ver_transacciones_viewmodel.dart';

/// Enumeración para los tipos de filtros disponibles
enum TipoFiltro {
  todos,
  ingresos,
  gastos,
}

/// Enumeración para el criterio de ordenamiento
enum CriterioOrden {
  fechaReciente,
  fechaAntigua,
  categoria,
}

/// Clase para encapsular los criterios de búsqueda y filtros
class CriteriosBusqueda {
  final TipoFiltro tipoFiltro;
  final String? categoriaFiltro;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final CriterioOrden criterioOrden;

  const CriteriosBusqueda({
    this.tipoFiltro = TipoFiltro.todos,
    this.categoriaFiltro,
    this.fechaInicio,
    this.fechaFin,
    this.criterioOrden = CriterioOrden.fechaReciente,
  });

  /// Copia el criterio actual con modificaciones
  CriteriosBusqueda copyWith({
    TipoFiltro? tipoFiltro,
    String? categoriaFiltro,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    CriterioOrden? criterioOrden,
    bool? limpiarCategoria,
    bool? limpiarFechaInicio,
    bool? limpiarFechaFin,
  }) {
    return CriteriosBusqueda(
      tipoFiltro: tipoFiltro ?? this.tipoFiltro,
      categoriaFiltro: limpiarCategoria == true ? null : (categoriaFiltro ?? this.categoriaFiltro),
      fechaInicio: limpiarFechaInicio == true ? null : (fechaInicio ?? this.fechaInicio),
      fechaFin: limpiarFechaFin == true ? null : (fechaFin ?? this.fechaFin),
      criterioOrden: criterioOrden ?? this.criterioOrden,
    );
  }

  /// Verifica si hay filtros activos
  bool get tienesFiltrosActivos {
    return tipoFiltro != TipoFiltro.todos ||
        categoriaFiltro?.isNotEmpty == true ||
        fechaInicio != null ||
        fechaFin != null;
  }

  /// Cuenta la cantidad de filtros activos
  int get cantidadFiltrosActivos {
    int count = 0;
    if (tipoFiltro != TipoFiltro.todos) count++;
    if (categoriaFiltro?.isNotEmpty == true) count++;
    if (fechaInicio != null || fechaFin != null) count++;
    return count;
  }

  /// Limpia todos los filtros
  CriteriosBusqueda limpiarFiltros() {
    return const CriteriosBusqueda();
  }
}

/// Servicio de búsqueda y filtros para transacciones
class ServicioBusquedaTransacciones {
  
  /// Filtra una lista de transacciones según los criterios especificados
  List<TransaccionItem> filtrarTransacciones(
    List<TransaccionItem> transacciones,
    CriteriosBusqueda criterios,
  ) {
    List<TransaccionItem> resultados = List.from(transacciones);
    
    // Filtrar por tipo de transacción
    if (criterios.tipoFiltro != TipoFiltro.todos) {
      resultados = _filtrarPorTipo(resultados, criterios.tipoFiltro);
    }

    // Filtrar por categoría
    if (criterios.categoriaFiltro?.isNotEmpty == true) {
      resultados = _filtrarPorCategoria(resultados, criterios.categoriaFiltro!);
    }

    // Filtrar por rango de fechas
    if (criterios.fechaInicio != null || criterios.fechaFin != null) {
      resultados = _filtrarPorRangoFechas(
        resultados,
        criterios.fechaInicio,
        criterios.fechaFin,
      );
    }

    // Ordenar resultados
    resultados = _ordenarTransacciones(resultados, criterios.criterioOrden);

    return resultados;
  }

  /// Filtra transacciones por tipo (ingreso/gasto)
  List<TransaccionItem> _filtrarPorTipo(
    List<TransaccionItem> transacciones,
    TipoFiltro tipo,
  ) {
    switch (tipo) {
      case TipoFiltro.ingresos:
        return transacciones.where((t) => t.tipo == 'ingreso').toList();
      case TipoFiltro.gastos:
        return transacciones.where((t) => t.tipo == 'gasto').toList();
      case TipoFiltro.todos:
        return transacciones;
    }
  }

  /// Filtra transacciones por categoría específica
  List<TransaccionItem> _filtrarPorCategoria(
    List<TransaccionItem> transacciones,
    String categoria,
  ) {
    return transacciones.where((transaccion) {
      return transaccion.categoria.toLowerCase() == categoria.toLowerCase();
    }).toList();
  }

  /// Filtra transacciones por rango de fechas
  List<TransaccionItem> _filtrarPorRangoFechas(
    List<TransaccionItem> transacciones,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  ) {
    return transacciones.where((transaccion) {
      // Normalizar fechas eliminando hora, minuto, segundo y milisegundo
      final fechaTransaccionSoloFecha = DateTime(
        transaccion.fecha.year,
        transaccion.fecha.month,
        transaccion.fecha.day,
      );
      
      bool cumpleRango = true;
      
      // Verificar fecha de inicio
      if (fechaInicio != null) {
        final fechaInicioSoloFecha = DateTime(
          fechaInicio.year,
          fechaInicio.month,
          fechaInicio.day,
        );
        cumpleRango = cumpleRango && 
                     !fechaTransaccionSoloFecha.isBefore(fechaInicioSoloFecha);
      }
      
      // Verificar fecha de fin
      if (fechaFin != null) {
        final fechaFinSoloFecha = DateTime(
          fechaFin.year,
          fechaFin.month,
          fechaFin.day,
        );
        cumpleRango = cumpleRango && 
                     !fechaTransaccionSoloFecha.isAfter(fechaFinSoloFecha);
      }
      
      return cumpleRango;
    }).toList();
  }

  /// Ordena las transacciones según el criterio especificado
  List<TransaccionItem> _ordenarTransacciones(
    List<TransaccionItem> transacciones,
    CriterioOrden criterio,
  ) {
    List<TransaccionItem> lista = List.from(transacciones);
    
    switch (criterio) {
      case CriterioOrden.fechaReciente:
        lista.sort((a, b) => b.fecha.compareTo(a.fecha));
        break;
      case CriterioOrden.fechaAntigua:
        lista.sort((a, b) => a.fecha.compareTo(b.fecha));
        break;
      case CriterioOrden.categoria:
        lista.sort((a, b) => a.categoria.compareTo(b.categoria));
        break;
    }
    
    return lista;
  }

  /// Obtiene una lista única de categorías de las transacciones
  List<String> obtenerCategorias(List<TransaccionItem> transacciones) {
    final categorias = transacciones.map((t) => t.categoria).toSet().toList();
    categorias.sort();
    return categorias;
  }

  /// Obtiene transacciones del último mes
  List<TransaccionItem> obtenerTransaccionesUltimoMes(
    List<TransaccionItem> transacciones,
  ) {
    final ahora = DateTime.now();
    final hacUnMes = DateTime(ahora.year, ahora.month - 1, ahora.day);
    
    final criterios = CriteriosBusqueda(
      fechaInicio: hacUnMes,
      fechaFin: ahora,
    );
    
    return filtrarTransacciones(transacciones, criterios);
  }

  /// Obtiene transacciones de la última semana
  List<TransaccionItem> obtenerTransaccionesUltimaSemana(
    List<TransaccionItem> transacciones,
  ) {
    final ahora = DateTime.now();
    final hacUnaSemana = ahora.subtract(const Duration(days: 7));
    
    final criterios = CriteriosBusqueda(
      fechaInicio: hacUnaSemana,
      fechaFin: ahora,
    );
    
    return filtrarTransacciones(transacciones, criterios);
  }

  /// Obtiene transacciones de hoy
  List<TransaccionItem> obtenerTransaccionesHoy(
    List<TransaccionItem> transacciones,
  ) {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    
    final criterios = CriteriosBusqueda(
      fechaInicio: inicioHoy,
      fechaFin: inicioHoy, // Mismo día para inicio y fin
    );
    
    return filtrarTransacciones(transacciones, criterios);
  }

  /// Obtiene estadísticas básicas de un conjunto de transacciones
  Map<String, dynamic> obtenerEstadisticas(List<TransaccionItem> transacciones) {
    final ingresos = transacciones.where((t) => t.tipo == 'ingreso').toList();
    final gastos = transacciones.where((t) => t.tipo == 'gasto').toList();
    
    final totalIngresos = ingresos.fold<double>(0.0, (sum, item) => sum + item.monto);
    final totalGastos = gastos.fold<double>(0.0, (sum, item) => sum + item.monto);
    final balance = totalIngresos - totalGastos;
    
    final promedioIngreso = ingresos.isNotEmpty ? totalIngresos / ingresos.length : 0.0;
    final promedioGasto = gastos.isNotEmpty ? totalGastos / gastos.length : 0.0;
    
    return {
      'totalTransacciones': transacciones.length,
      'totalIngresos': totalIngresos,
      'totalGastos': totalGastos,
      'balance': balance,
      'cantidadIngresos': ingresos.length,
      'cantidadGastos': gastos.length,
      'promedioIngreso': promedioIngreso,
      'promedioGasto': promedioGasto,
      'categorias': obtenerCategorias(transacciones),
    };
  }
}
