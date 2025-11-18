import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../models/report_period.dart';
import '../services/report_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'dart:io';

class ReportsSelectionView extends ConsumerStatefulWidget {
  const ReportsSelectionView({super.key});

  @override
  ConsumerState<ReportsSelectionView> createState() =>
      _ReportsSelectionViewState();
}

class _ReportsSelectionViewState extends ConsumerState<ReportsSelectionView> {
  final ReportService _reportService = ReportService();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blackGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Exportar Reportes',
          style: TextStyle(
            color: AppColors.blackGrey,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.pinkPastel),
                  SizedBox(height: 16),
                  Text(
                    'Generando reporte...',
                    style: TextStyle(fontSize: 16, color: AppColors.greyDark),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Descripción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blueLavender.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.blueLavender,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Genera reportes en PDF de tus finanzas para analizar y compartir',
                          style: TextStyle(
                            color: AppColors.greyDark,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Reporte de Transacciones
                _buildReportCard(
                  title: 'Reporte de Ingresos y Egresos',
                  description:
                      'Obtén un resumen detallado de tus transacciones por periodo',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.pinkPastel,
                  onTap: () => _showTransactionReportDialog(),
                ),

                const SizedBox(height: 16),

                // Reporte de Cumplimiento de Planes
                _buildReportCard(
                  title: 'Reporte de Cumplimiento de Planes',
                  description:
                      'Verifica si estás alcanzando los objetivos de tus planes financieros',
                  icon: Icons.assessment,
                  color: AppColors.greenJade,
                  onTap: () => _showPlanComplianceDialog(),
                ),
              ],
            ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.greyDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.greyDark,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionReportDialog() {
    final now = DateTime.now();
    ReportPeriod selectedPeriod = ReportPeriod.monthly;
    int selectedYear = now.year;
    int selectedMonth = now.month;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reporte de Transacciones'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el periodo:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportPeriod>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ReportPeriod.values
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(period.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedPeriod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Año:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: now.year - index,
                      child: Text('${now.year - index}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedYear = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mes:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedMonth,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_getMonthName(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedMonth = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generateTransactionReport(
                  selectedPeriod,
                  selectedYear,
                  selectedMonth,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPastel,
                foregroundColor: Colors.white,
              ),
              child: const Text('Generar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanComplianceDialog() async {
    final authState = ref.read(authStateProvider);
    String? userId;

    authState.whenData((user) {
      if (user != null) {
        userId = user.id;
      }
    });

    if (userId == null) {
      _showErrorSnackBar('Error: Usuario no autenticado');
      return;
    }

    // Aquí deberías obtener la lista de planes del usuario
    // Por ahora usaremos un diálogo simple
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reporte de Cumplimiento'),
        content: const Text(
          'Selecciona un plan financiero desde tu lista de planes activos para generar el reporte de cumplimiento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a la lista de planes para seleccionar uno
              Navigator.pop(context); // Cerrar la vista de reportes
              // El usuario debe ir a la sección de planes y desde ahí generar el reporte
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenJade,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTransactionReport(
    ReportPeriod period,
    int year,
    int month,
  ) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      String? userId;

      authState.whenData((user) {
        if (user != null) {
          userId = user.id;
        }
      });

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final startDate = _reportService.getStartDateForPeriod(period, year, month);
      final endDate = _reportService.getEndDateForPeriod(startDate, period);

      final reportData = await _reportService.getTransactionReportData(
        userId: userId!,
        startDate: startDate,
        endDate: endDate,
      );

      final pdfFile = await _reportService.generateTransactionPDF(reportData);

      setState(() {
        _isGenerating = false;
      });

      _showReportOptions(pdfFile);
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _showErrorSnackBar('Error al generar reporte: $e');
    }
  }

  void _showReportOptions(File pdfFile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reporte generado exitosamente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.pinkPastel),
              title: const Text('Compartir PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _reportService.sharePDF(pdfFile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.blueLavender),
              title: const Text('Imprimir PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _reportService.printPDF(pdfFile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.greenJade),
              title: const Text('Guardado en Documentos'),
              subtitle: Text(
                pdfFile.path,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.redCoral,
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }
}
