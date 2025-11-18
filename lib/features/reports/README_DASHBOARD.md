# Dashboard Financiero - VanguardMoney

## 📊 Vista General

El dashboard financiero es una pantalla completa que muestra estadísticas y análisis de las finanzas del usuario en VanguardMoney.

## 🎯 Funcionalidades Implementadas

### 1. **Resumen Mensual**
- Balance total (Ingresos - Gastos)
- Total de ingresos del mes
- Total de gastos del mes
- Cantidad de transacciones
- Porcentaje de ahorro
- Indicadores visuales (trending up/down)

### 2. **Distribución de Gastos por Categoría**
- Gráfico circular (pie chart) interactivo
- Top 5 categorías con mayor gasto
- Porcentaje de cada categoría respecto al total
- Colores distintivos para cada categoría
- Diseño tipo "donut chart"

### 3. **Lista Detallada de Categorías**
- Todas las categorías con gastos en el mes
- Monto total por categoría
- Cantidad de transacciones por categoría
- Porcentaje respecto al total
- Iconos representativos por tipo de gasto

### 4. **Estado de Planes Financieros**
- Lista de planes activos del mes
- Progreso visual con barras de color
- Estados del plan:
  - ✅ **Healthy** (< 70% usado) - Verde
  - ⚠️ **Caution** (70-89% usado) - Naranja
  - 🔶 **Warning** (90-99% usado) - Naranja oscuro
  - 🔴 **Exceeded** (≥ 100% usado) - Rojo
- Presupuesto vs gastado
- Monto restante
- Cantidad de categorías por plan

### 5. **Navegación Temporal**
- Selector de mes/año
- Botones para mes anterior/siguiente
- Carga automática de datos al cambiar mes

### 6. **Actualización de Datos**
- Pull-to-refresh para recargar datos
- Carga automática al abrir la vista
- Indicadores de carga y error

## 📁 Estructura de Archivos

```
lib/features/reports/
├── models/
│   └── dashboard_stats_model.dart       # Modelos de datos
├── viewmodels/
│   └── dashboard_viewmodel.dart         # Lógica de negocio
└── views/
    └── dashboard_view.dart              # UI del dashboard
```

## 🔄 Integración

El dashboard está integrado en el tab de **Reportes** del `MainLayout`:

```dart
// lib/features/layout/views/tabs/reportes_tab_page.dart
class ReportesTabPage extends ConsumerWidget {
  const ReportesTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DashboardView();
  }
}
```

## 🎨 Componentes UI Personalizados

### PieChartPainter
Custom painter que dibuja el gráfico circular de distribución de gastos:
- Renderizado eficiente con Canvas
- Colores dinámicos por categoría
- Efecto "donut" con círculo blanco central

### Cards de Resumen
- Tarjetas elevadas con sombras
- Diseño responsive
- Separadores visuales
- Chips informativos

### Lista de Planes
- ExpansionTile para cada plan
- Barras de progreso con colores dinámicos
- Información detallada expandible

## 📊 Fuentes de Datos

El dashboard obtiene datos de Firebase Firestore:

### Colecciones consultadas:
1. **`facturas`** - Gastos/egresos del usuario
2. **`ingresos`** - Ingresos del usuario
3. **`financial_plans`** - Planes financieros activos

### Filtros aplicados:
- Por usuario actual (`idUsuario` / `userId`)
- Por mes y año seleccionados
- Planes activos (`isActive = true`)

## 🔧 Uso del ViewModel

```dart
final dashboardViewModelProvider =
    ChangeNotifierProvider.autoDispose<DashboardViewModel>(
  (ref) {
    final viewModel = DashboardViewModel();
    viewModel.loadDashboardData();
    return viewModel;
  },
);
```

### Métodos principales:
- `loadDashboardData()` - Carga datos del mes seleccionado
- `previousMonth()` - Navega al mes anterior
- `nextMonth()` - Navega al mes siguiente
- `refresh()` - Recarga los datos actuales
- `setMonth(month, year)` - Cambia a un mes específico

## 🎨 Paleta de Colores

El dashboard utiliza una paleta de 8 colores para las categorías:
- Azul (`Colors.blue[600]`)
- Rojo (`Colors.red[600]`)
- Verde (`Colors.green[600]`)
- Naranja (`Colors.orange[600]`)
- Púrpura (`Colors.purple[600]`)
- Teal (`Colors.teal[600]`)
- Rosa (`Colors.pink[600]`)
- Ámbar (`Colors.amber[600]`)

## 📱 Estados de la UI

### Loading
- CircularProgressIndicator centrado

### Error
- Icono de error
- Mensaje descriptivo
- Botón de reintentar

### Empty
- Icono de analytics
- Mensaje "No hay datos disponibles"
- Sugerencia para registrar transacciones

### Success
- Todas las secciones visibles
- Datos actualizados
- Interactividad completa

## 🚀 Próximas Mejoras

- [ ] Gráficos de línea para tendencias mensuales
- [ ] Comparación con meses anteriores
- [ ] Exportar reporte a PDF
- [ ] Filtros adicionales (por categoría, rango de fechas)
- [ ] Gráficos de barras para comparación
- [ ] Predicciones con IA

## 📝 Notas Técnicas

- Utiliza **Riverpod** para gestión de estado
- Integrado con **Firebase Firestore**
- Custom painters para gráficos
- Diseño Material Design 3
- Responsive y adaptable
- Pull-to-refresh implementado
- Manejo robusto de errores
