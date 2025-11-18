import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../financial_plans/models/financial_plan_model.dart';
import '../models/report_period.dart';
import '../models/report_data.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== FILTRADO DE TRANSACCIONES ====================

  Future<TransactionReportData> getTransactionReportData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Convertir fechas a strings ISO8601 (formato usado en Firestore)
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    print('DEBUG: Buscando transacciones entre $startDateStr y $endDateStr para usuario $userId');
    
    // Obtener todos los ingresos del usuario (filtrado por fecha en memoria)
    final ingresosSnapshot = await _firestore
        .collection('ingresos')
        .where('idUsuario', isEqualTo: userId)
        .get();

    print('DEBUG: Encontrados ${ingresosSnapshot.docs.length} ingresos totales');

    // Obtener todos los egresos/facturas del usuario (filtrado por fecha en memoria)
    final egresosSnapshot = await _firestore
        .collection('facturas')
        .where('idUsuario', isEqualTo: userId)
        .get();
        
    print('DEBUG: Encontrados ${egresosSnapshot.docs.length} egresos totales');

    double totalIngresos = 0;
    double totalEgresos = 0;
    Map<String, double> ingresosPorCategoria = {};
    Map<String, double> egresosPorCategoria = {};
    List<TransactionItem> transactions = [];

    // Procesar ingresos con filtrado por fecha en memoria
    int ingresosEnRango = 0;
    for (var doc in ingresosSnapshot.docs) {
      final data = doc.data();
      
      // Convertir fecha desde String ISO8601 o Timestamp
      DateTime fecha;
      if (data['fecha'] == null) {
        print('Ingreso sin fecha, saltando...');
        continue;
      }
      
      if (data['fecha'] is Timestamp) {
        fecha = (data['fecha'] as Timestamp).toDate();
      } else if (data['fecha'] is String) {
        try {
          fecha = DateTime.parse(data['fecha'] as String);
        } catch (e) {
          print('Error parseando fecha de ingreso: $e');
          continue;
        }
      } else {
        print('Formato de fecha desconocido en ingreso');
        continue;
      }
      
      // Filtrar por rango de fechas
      if (fecha.isBefore(startDate) || fecha.isAfter(endDate)) {
        continue;
      }
      
      ingresosEnRango++;
      final monto = (data['monto'] as num).toDouble();
      final categoria = data['categoria'] as String? ?? 'Sin categoría';
      
      totalIngresos += monto;
      ingresosPorCategoria[categoria] = 
          (ingresosPorCategoria[categoria] ?? 0) + monto;
      
      transactions.add(TransactionItem(
        fecha: fecha,
        categoria: categoria,
        descripcion: data['descripcion'] as String? ?? '',
        monto: monto,
        isIngreso: true,
      ));
    }
    
    print('DEBUG: $ingresosEnRango ingresos en el rango de fechas');

    // Procesar egresos con filtrado por fecha en memoria
    int egresosEnRango = 0;
    for (var doc in egresosSnapshot.docs) {
      final data = doc.data();
      
      // Convertir fecha desde String ISO8601 o Timestamp
      DateTime fecha;
      if (data['invoiceDate'] != null) {
        // Formato de Factura
        if (data['invoiceDate'] is Timestamp) {
          fecha = (data['invoiceDate'] as Timestamp).toDate();
        } else if (data['invoiceDate'] is String) {
          try {
            fecha = DateTime.parse(data['invoiceDate'] as String);
          } catch (e) {
            print('Error parseando invoiceDate: $e');
            continue;
          }
        } else {
          print('Formato de invoiceDate desconocido');
          continue;
        }
      } else if (data['fecha'] != null) {
        // Formato antiguo
        if (data['fecha'] is Timestamp) {
          fecha = (data['fecha'] as Timestamp).toDate();
        } else if (data['fecha'] is String) {
          try {
            fecha = DateTime.parse(data['fecha'] as String);
          } catch (e) {
            print('Error parseando fecha: $e');
            continue;
          }
        } else {
          print('Formato de fecha desconocido');
          continue;
        }
      } else {
        print('Egreso sin fecha válida, saltando...');
        continue;
      }
      
      // Filtrar por rango de fechas
      if (fecha.isBefore(startDate) || fecha.isAfter(endDate)) {
        continue;
      }
      
      egresosEnRango++;
      
      // Obtener monto - puede estar como 'totalAmount' o 'monto'
      final monto = (data['totalAmount'] ?? data['monto'] ?? 0).toDouble();
      if (monto == 0) continue; // Saltar si no hay monto
      
      final categoria = data['categoria'] as String? ?? 'Sin categoría';
      
      totalEgresos += monto;
      egresosPorCategoria[categoria] = 
          (egresosPorCategoria[categoria] ?? 0) + monto;
      
      transactions.add(TransactionItem(
        fecha: fecha,
        categoria: categoria,
        descripcion: data['description'] as String? ?? data['descripcion'] as String? ?? '',
        monto: monto,
        isIngreso: false,
      ));
    }
    
    print('DEBUG: $egresosEnRango egresos en el rango de fechas');

    // Ordenar transacciones por fecha
    transactions.sort((a, b) => b.fecha.compareTo(a.fecha));

    return TransactionReportData(
      startDate: startDate,
      endDate: endDate,
      totalIngresos: totalIngresos,
      totalEgresos: totalEgresos,
      balance: totalIngresos - totalEgresos,
      ingresosPorCategoria: ingresosPorCategoria,
      egresosPorCategoria: egresosPorCategoria,
      transactions: transactions,
    );
  }

  DateTime getStartDateForPeriod(ReportPeriod period, int year, int month) {
    switch (period) {
      case ReportPeriod.monthly:
        return DateTime(year, month, 1);
      case ReportPeriod.quarterly:
        int quarterStartMonth = ((month - 1) ~/ 3) * 3 + 1;
        return DateTime(year, quarterStartMonth, 1);
      case ReportPeriod.semiannual:
        int semesterStartMonth = month <= 6 ? 1 : 7;
        return DateTime(year, semesterStartMonth, 1);
      case ReportPeriod.annual:
        return DateTime(year, 1, 1);
    }
  }

  DateTime getEndDateForPeriod(DateTime startDate, ReportPeriod period) {
    int endMonth = startDate.month + period.monthsCount;
    int endYear = startDate.year;
    
    while (endMonth > 12) {
      endMonth -= 12;
      endYear++;
    }
    
    return DateTime(endYear, endMonth, 1).subtract(const Duration(days: 1));
  }

  // ==================== REPORTE DE CUMPLIMIENTO DE PLANES ====================

  Future<PlanComplianceReportData?> getPlanComplianceData({
    required String userId,
    required String planId,
  }) async {
    try {
      final planDoc = await _firestore
          .collection('financial_plans')
          .doc(planId)
          .get();

      if (!planDoc.exists) return null;

      final planData = planDoc.data()!;
      planData['id'] = planDoc.id;
      final plan = FinancialPlanModel.fromMap(planData);

      // Obtener transacciones del mes del plan
      final startDate = DateTime(plan.year, plan.month, 1);
      final endDate = DateTime(plan.year, plan.month + 1, 0);

      // Obtener egresos/facturas y filtrar en memoria
      final egresosSnapshot = await _firestore
          .collection('facturas')
          .where('idUsuario', isEqualTo: userId)
          .get();

      // Calcular gastos por categoría
      Map<String, double> gastosPorCategoria = {};
      double totalSpent = 0;

      for (var doc in egresosSnapshot.docs) {
        final data = doc.data();
        
        // Filtrar por fecha en memoria
        DateTime? fecha;
        if (data['invoiceDate'] != null) {
          if (data['invoiceDate'] is Timestamp) {
            fecha = (data['invoiceDate'] as Timestamp).toDate();
          } else if (data['invoiceDate'] is String) {
            try {
              fecha = DateTime.parse(data['invoiceDate'] as String);
            } catch (e) {
              continue;
            }
          }
        } else if (data['fecha'] != null) {
          if (data['fecha'] is Timestamp) {
            fecha = (data['fecha'] as Timestamp).toDate();
          } else if (data['fecha'] is String) {
            try {
              fecha = DateTime.parse(data['fecha'] as String);
            } catch (e) {
              continue;
            }
          }
        }
        
        if (fecha == null || fecha.isBefore(startDate) || fecha.isAfter(endDate)) {
          continue;
        }
        
        final monto = (data['totalAmount'] ?? data['monto'] ?? 0).toDouble();
        final categoria = data['categoria'] as String? ?? 'Sin categoría';
        
        gastosPorCategoria[categoria] = 
            (gastosPorCategoria[categoria] ?? 0) + monto;
        totalSpent += monto;
      }

      // Calcular cumplimiento por categoría
      List<CategoryCompliance> categoryCompliances = [];
      
      for (var budget in plan.categoryBudgets) {
        final spent = gastosPorCategoria[budget.categoryName] ?? 0;
        final compliance = budget.budgetAmount > 0
            ? (spent / budget.budgetAmount) * 100
            : 0;

        categoryCompliances.add(CategoryCompliance(
          categoryName: budget.categoryName,
          budgetAmount: budget.budgetAmount,
          spentAmount: spent,
          compliancePercentage: compliance.toDouble(),
        ));
      }

      final overallCompliance = plan.totalBudget > 0
          ? (totalSpent / plan.totalBudget) * 100
          : 0;

      return PlanComplianceReportData(
        planName: plan.planName,
        year: plan.year,
        month: plan.month,
        totalBudget: plan.totalBudget,
        totalSpent: totalSpent,
        compliancePercentage: overallCompliance.toDouble(),
        categoryCompliances: categoryCompliances,
      );
    } catch (e) {
      print('Error obteniendo datos de cumplimiento del plan: $e');
      return null;
    }
  }

  // ==================== GENERACIÓN DE PDF DE TRANSACCIONES ====================

  Future<File> generateTransactionPDF(TransactionReportData data) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Encabezado
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Transacciones',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Periodo: ${dateFormat.format(data.startDate)} - ${dateFormat.format(data.endDate)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Text(
                  'VanguardMoney',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink300,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Resumen General
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen General',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildSummaryRow('Total Ingresos', data.totalIngresos, true),
                _buildSummaryRow('Total Egresos', data.totalEgresos, false),
                pw.Divider(),
                _buildSummaryRow(
                  'Balance',
                  data.balance,
                  data.balance >= 0,
                  isBold: true,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Ingresos por Categoría
          if (data.ingresosPorCategoria.isNotEmpty) ...[
            pw.Text(
              'Ingresos por Categoría',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildCategoryTable(data.ingresosPorCategoria, true),
            pw.SizedBox(height: 20),
          ],

          // Egresos por Categoría
          if (data.egresosPorCategoria.isNotEmpty) ...[
            pw.Text(
              'Egresos por Categoría',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildCategoryTable(data.egresosPorCategoria, false),
            pw.SizedBox(height: 20),
          ],

          // Detalle de Transacciones
          pw.Text(
            'Detalle de Transacciones',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildTransactionsTable(data.transactions, dateFormat),
        ],
      ),
    );

    return _savePDF(pdf, 'reporte_transacciones_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // ==================== GENERACIÓN DE PDF DE CUMPLIMIENTO ====================

  Future<File> generatePlanCompliancePDF(PlanComplianceReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Encabezado
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte de Cumplimiento',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      data.planName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.pink300,
                      ),
                    ),
                    pw.Text(
                      _getMonthName(data.month) + ' ${data.year}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Text(
                  'VanguardMoney',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink300,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Resumen del Plan
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen del Plan',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildSummaryRow('Presupuesto Total', data.totalBudget, null),
                _buildSummaryRow('Total Gastado', data.totalSpent, null),
                pw.Divider(),
                _buildComplianceRow(
                  'Cumplimiento General',
                  data.compliancePercentage,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Gráfico de cumplimiento general (visual simple)
          _buildComplianceBar(data.compliancePercentage),

          pw.SizedBox(height: 20),

          // Detalle por Categoría
          pw.Text(
            'Cumplimiento por Categoría',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildComplianceTable(data.categoryCompliances),
        ],
      ),
    );

    return _savePDF(pdf, 'reporte_cumplimiento_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  // ==================== WIDGETS AUXILIARES ====================

  pw.Widget _buildSummaryRow(String label, double amount, bool? isPositive,
      {bool isBold = false}) {
    final color = isPositive == null
        ? PdfColors.black
        : isPositive
            ? PdfColors.green
            : PdfColors.red;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'S/ ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              color: color,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildComplianceRow(String label, double percentage) {
    final color = percentage <= 100 ? PdfColors.green : PdfColors.red;
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${percentage.toStringAsFixed(1)}%',
            style: pw.TextStyle(
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryTable(Map<String, double> categories, bool isIncome) {
    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Categoría', 'Monto', '%'],
      data: sortedEntries.map((entry) {
        final total = categories.values.fold(0.0, (a, b) => a + b);
        final percentage = (entry.value / total * 100).toStringAsFixed(1);
        return [
          entry.key,
          'S/ ${entry.value.toStringAsFixed(2)}',
          '$percentage%',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTransactionsTable(
      List<TransactionItem> transactions, DateFormat dateFormat) {
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Fecha', 'Categoría', 'Descripción', 'Monto'],
      data: transactions.take(50).map((t) {
        return [
          dateFormat.format(t.fecha),
          t.categoria,
          t.descripcion.length > 30
              ? '${t.descripcion.substring(0, 27)}...'
              : t.descripcion,
          '${t.isIngreso ? '+' : '-'} S/ ${t.monto.toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildComplianceTable(List<CategoryCompliance> compliances) {
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Categoría', 'Presupuesto', 'Gastado', 'Cumplimiento'],
      data: compliances.map((c) {
        return [
          c.categoryName,
          'S/ ${c.budgetAmount.toStringAsFixed(2)}',
          'S/ ${c.spentAmount.toStringAsFixed(2)}',
          '${c.compliancePercentage.toStringAsFixed(1)}%',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildComplianceBar(double percentage) {
    final barColor = percentage <= 100 ? PdfColors.green : PdfColors.red;
    final displayPercentage = percentage > 100 ? 100.0 : percentage;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Progreso de Cumplimiento'),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          height: 30,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Stack(
            children: [
              pw.Container(
                width: displayPercentage * 5, // Ajustar al ancho de la página
                decoration: pw.BoxDecoration(
                  color: barColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== UTILIDADES ====================

  Future<File> _savePDF(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  // ==================== COMPARTIR/EXPORTAR PDF ====================

  Future<void> sharePDF(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  Future<void> printPDF(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await pdfFile.readAsBytes(),
    );
  }
}
