import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../viewmodels/registrar_voz_viewmodel.dart';
import '../egreso/register_egreso_view.dart';
import '../ingreso/register_ingreso_view.dart';

/// Pantalla para registrar transacciones mediante audio/voz con IA
class RegistrarConVozScreen extends StatefulWidget {
  final String? idUsuario;

  const RegistrarConVozScreen({super.key, this.idUsuario});

  @override
  State<RegistrarConVozScreen> createState() => _RegistrarConVozScreenState();
}

class _RegistrarConVozScreenState extends State<RegistrarConVozScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _audioPath;
  bool _isRecording = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Inicializar Gemini al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<RegistrarMedianteVozViewModel>(
        context,
        listen: false,
      );
      viewModel.initializeGeminiModel();
    });
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _audioRecorder.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se necesita permiso de micrófono')),
      );
      await _checkPermissions();
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _audioPath = null;
      });

      final viewModel = Provider.of<RegistrarMedianteVozViewModel>(
        context,
        listen: false,
      );
      viewModel.setRecording(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Grabando... Describe tu transacción'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar grabación: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      final viewModel = Provider.of<RegistrarMedianteVozViewModel>(
        context,
        listen: false,
      );
      viewModel.setRecording(false);
      if (path != null) {
        viewModel.setAudioPath(path);
      }

      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Grabación completada'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al detener grabación: $e')),
        );
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _audioPath = result.files.single.path;
        });

        final viewModel = Provider.of<RegistrarMedianteVozViewModel>(
          context,
          listen: false,
        );
        viewModel.setAudioPath(_audioPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Audio seleccionado'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar audio: $e')),
        );
      }
    }
  }

  Future<void> _analyzeAudio() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero graba o selecciona un audio')),
      );
      return;
    }

    final idUsuario = widget.idUsuario ?? 'usuario_default';
    final viewModel = Provider.of<RegistrarMedianteVozViewModel>(
      context,
      listen: false,
    );

    // Analizar audio
    await viewModel.analizarAudioYExtraerDatos(_audioPath!, idUsuario);

    if (!mounted) return;

    // Si hubo error, mostrar mensaje
    if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Si se extrajeron datos, ir a la vista correspondiente
    if (viewModel.datosExtraidos != null && viewModel.tipoTransaccion != null) {
      if (viewModel.tipoTransaccion == 'egreso') {
        // Mapear datos para egresos
        final datosParaEgreso = {
          'invoiceNumber': viewModel.datosExtraidos!['invoiceNumber'],
          'invoiceDate': viewModel.datosExtraidos!['invoiceDate'],
          'totalAmount': viewModel.datosExtraidos!['totalAmount'],
          'supplierName': viewModel.datosExtraidos!['supplierName'],
          'supplierTaxId': viewModel.datosExtraidos!['supplierTaxId'],
          'description': viewModel.datosExtraidos!['description'],
          'taxAmount': viewModel.datosExtraidos!['taxAmount'],
          'lugarLocal': viewModel.datosExtraidos!['lugarLocal'],
          'categoria': viewModel.datosExtraidos!['categoria'],
          // RegisterBillView espera 'scanImagePath' para la ruta del escaneo/archivo;
          // reutilizamos ese campo para pasar la ruta del audio desde la IA.
          'scanImagePath': _audioPath,
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterBillView(
              idUsuario: idUsuario,
              datosIniciales: datosParaEgreso,
            ),
          ),
        );
      } else if (viewModel.tipoTransaccion == 'ingreso') {
        // Navegar a la vista de registro de ingreso pasando los datos extraídos
        final datosParaIngreso = {
          'monto': viewModel.datosExtraidos!['monto'],
          'fecha': viewModel.datosExtraidos!['fecha'],
          'descripcion': viewModel.datosExtraidos!['descripcion'],
          'categoria': viewModel.datosExtraidos!['categoria'],
          'metodoPago': viewModel.datosExtraidos!['metodoPago'],
          'origen': viewModel.datosExtraidos!['origen'],
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterIngresoView(
              idUsuario: idUsuario,
              datosIniciales: datosParaIngreso,
            ),
          ),
        );
      }
    }
  }

  // Nota: el flujo de ingresos ahora navega directamente a RegisterIngresoView
  // con datosIniciales, por lo que el diálogo antiguo fue removido.

  // helper removido: el diálogo de ingreso fue reemplazado por navegación directa.

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: 24),
            SizedBox(width: 8),
            Text('Registrar con Voz'),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<RegistrarMedianteVozViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con ícono
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? Colors.red.withOpacity(0.2)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 50,
                          color: _isRecording ? Colors.red : Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRecording
                            ? '🔴 Grabando...'
                            : 'Describe tu transacción',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.red : Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRecording
                            ? 'Menciona si es un gasto o ingreso, el monto y detalles'
                            : 'La IA detectará automáticamente si es ingreso o egreso',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Controles de grabación
                if (!_isRecording && _audioPath == null) ...[
                  // Botón para grabar
                  ElevatedButton.icon(
                    onPressed: _hasPermission
                        ? _startRecording
                        : _checkPermissions,
                    icon: const Icon(Icons.mic, size: 28),
                    label: Text(
                      _hasPermission ? 'Grabar Audio' : 'Solicitar Permiso',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider con texto
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón para seleccionar archivo
                  OutlinedButton.icon(
                    onPressed: _pickAudioFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text(
                      'Cargar Archivo de Audio',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.purple, width: 2),
                    ),
                  ),
                ],

                if (_isRecording) ...[
                  // Botón para detener grabación
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop, size: 28),
                    label: const Text(
                      'Detener Grabación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Indicador visual de grabación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Grabando audio...',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_audioPath != null && !_isRecording) ...[
                  // Tarjeta de audio listo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Audio listo para analizar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                File(_audioPath!).path.split('/').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: viewModel.isLoading ? null : _analyzeAudio,
                          icon: viewModel.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            viewModel.isLoading
                                ? 'Analizando...'
                                : 'Analizar con IA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _audioPath = null;
                          });
                          viewModel.setAudioPath(null);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Tips informativos
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.purple[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Consejos para mejores resultados',
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('💰', 'Menciona si es un "gasto" o "ingreso"'),
                      _buildTip(
                        '🔢',
                        'Di el monto claramente: "pagué 500 pesos"',
                      ),
                      _buildTip(
                        '📝',
                        'Describe brevemente: "compra de supermercado"',
                      ),
                      _buildTip(
                        '🏪',
                        'Menciona el lugar: "en Walmart" o "por transferencia"',
                      ),
                      _buildTip(
                        '🎯',
                        'La IA detectará automáticamente el tipo',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.purple[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
