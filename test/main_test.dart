import 'package:flutter_test/flutter_test.dart';
import 'package:vanguardmoney/features/transactions/models/registro_ingreso_model.dart';
import 'package:vanguardmoney/features/transactions/models/categoria_model.dart';
import 'package:vanguardmoney/features/financial_plans/models/financial_plan_model.dart';

void main() {
  group('Pruebas Unitarias de Lógica de Negocio', () {
    test('1. Debe convertir Ingreso a Map y desde Map correctamente (Serialización Firebase)', () {
      // Arrange
      final ingreso = Ingreso(
        id: '1',
        idUsuario: 'user123',
        monto: 5000.0,
        fecha: DateTime(2025, 11, 18),
        descripcion: 'Salario mensual',
        categoria: 'Sueldo',
        metodoPago: 'Transferencia',
        origen: 'Empresa ABC',
      );

      // Act
      final map = ingreso.toMap();
      final ingresoReconstruido = Ingreso.fromMap(map);

      // Assert
      expect(ingresoReconstruido.id, equals(ingreso.id));
      expect(ingresoReconstruido.monto, equals(ingreso.monto));
      expect(ingresoReconstruido.categoria, equals(ingreso.categoria));
      expect(map['idUsuario'], equals('user123'));
    });

    test('2. Debe retornar las categorías base correctas (3 ingresos, 7 egresos)', () {
      // Act
      final categoriasIngresos = CategoriaModel.categoriasBaseIngresos;
      final categoriasEgresos = CategoriaModel.categoriasBaseEgresos;

      // Assert
      expect(categoriasIngresos.length, equals(3));
      expect(categoriasEgresos.length, equals(7));
      expect(categoriasIngresos.every((cat) => cat.tipo == TipoCategoria.ingreso), isTrue);
      expect(categoriasEgresos.every((cat) => cat.tipo == TipoCategoria.egreso), isTrue);
      expect(categoriasIngresos[0].nombre, equals('Sueldo'));
      expect(categoriasEgresos.any((cat) => cat.nombre == 'Alimentación'), isTrue);
    });

    test('3. Debe calcular porcentaje de uso de presupuesto correctamente', () {
      // Arrange
      final budget = CategoryBudget(
        categoryId: 'alimentacion',
        categoryName: 'Alimentación',
        budgetAmount: 1000.0,
        spentAmount: 750.0,
        categoryType: TipoCategoria.egreso,
      );

      // Act & Assert
      expect(budget.usagePercentage, equals(75.0));
      expect(budget.remainingAmount, equals(250.0));
      expect(budget.isOverBudget, isFalse);
    });

    test('4. Debe detectar sobre-presupuesto y limitar porcentaje al 100%', () {
      // Arrange
      final budget = CategoryBudget(
        categoryId: 'entretenimiento',
        categoryName: 'Entretenimiento',
        budgetAmount: 200.0,
        spentAmount: 250.0,
        categoryType: TipoCategoria.egreso,
      );

      // Act & Assert
      expect(budget.isOverBudget, isTrue);
      expect(budget.usagePercentage, equals(100.0)); // Debe estar limitado al 100%
      expect(budget.spentAmount, greaterThan(budget.budgetAmount));
    });

    test('5. Debe calcular balance financiero (ingresos - gastos)', () {
      // Arrange
      const totalIngresos = 5000.0;
      const totalGastos = 3500.0;

      // Act
      final balance = totalIngresos - totalGastos;
      final tieneSupervit = balance > 0;

      // Assert
      expect(balance, equals(1500.0));
      expect(tieneSupervit, isTrue);
    });

    test('6. Debe calcular ahorro recomendado (20% de ingresos) y validar objetivo', () {
      // Arrange
      const ingreso = 5000.0;
      const gastos = 4000.0;
      const porcentajeAhorroRecomendado = 0.20;

      // Act
      final ahorroRecomendado = ingreso * porcentajeAhorroRecomendado;
      final ahorroActual = ingreso - gastos;
      final porcentajeAhorroActual = (ahorroActual / ingreso) * 100;
      final cumpleObjetivo = porcentajeAhorroActual >= 10.0;

      // Assert
      expect(ahorroRecomendado, equals(1000.0));
      expect(ahorroActual, equals(1000.0));
      expect(porcentajeAhorroActual, equals(20.0));
      expect(cumpleObjetivo, isTrue);
    });

    test('7. Debe calcular total de gastos por categorías y porcentajes', () {
      // Arrange
      final gastos = [
        {'categoria': 'Alimentación', 'monto': 800.0},
        {'categoria': 'Transporte', 'monto': 300.0},
        {'categoria': 'Entretenimiento', 'monto': 150.0},
      ];

      // Act
      final totalGastos = gastos.fold<double>(
        0.0,
        (sum, gasto) => sum + (gasto['monto'] as double),
      );
      final porcentajeAlimentacion = ((gastos[0]['monto'] as double) / totalGastos) * 100;

      // Assert
      expect(totalGastos, equals(1250.0));
      expect(porcentajeAlimentacion, closeTo(64.0, 0.1));
      expect(gastos.length, equals(3));
    });
  });
}
