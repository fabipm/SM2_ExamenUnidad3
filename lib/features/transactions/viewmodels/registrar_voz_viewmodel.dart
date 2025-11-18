import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/categoria_model.dart';
import '../services/categoria_service.dart';

class RegistrarMedianteVozViewModel extends ChangeNotifier {
  GenerativeModel? _model;
  final CategoriaService _categoriaService = CategoriaService();
  bool _isLoading = false;
  bool _isRecording = false;
  String? _errorMessage;
  Map<String, dynamic>? _datosExtraidos;
  String? _categoriaSugerida;
  String? _tipoTransaccion; // 'ingreso' o 'egreso'
  String? _audioPath;
  String? _currentUserId; // Para almacenar el userId cuando se llama a analizarAudio

  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get datosExtraidos => _datosExtraidos;
  String? get categoriaSugerida => _categoriaSugerida;
  String? get tipoTransaccion => _tipoTransaccion;
  String? get audioPath => _audioPath;

  /// Inicializa el modelo Gemini usando Firebase AI
  Future<void> initializeGeminiModel() async {
    try {
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash-exp',
      );
      
      if (kDebugMode) {
        print('✅ Modelo Gemini inicializado correctamente para voz');
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al inicializar el modelo: $e';
      if (kDebugMode) {
        print('❌ Error en initializeGeminiModel: $e');
      }
      notifyListeners();
    }
  }

  /// Marca que se está grabando
  void setRecording(bool recording) {
    _isRecording = recording;
    notifyListeners();
  }

  /// Establece la ruta del audio
  void setAudioPath(String? path) {
    _audioPath = path;
    notifyListeners();
  }

  /// Analiza un archivo de audio y extrae datos de la transacción
  Future<void> analizarAudioYExtraerDatos(String audioPath, String idUsuario) async {
    // Inicializar Gemini si no está inicializado
    if (_model == null) {
      await initializeGeminiModel();
    }

    _isLoading = true;
    _errorMessage = null;
    _datosExtraidos = null;
    _categoriaSugerida = null;
    _tipoTransaccion = null;
    _audioPath = audioPath;
    _currentUserId = idUsuario; // Guardar userId para usarlo en _analizarAudioConGemini
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════');
        debugPrint('🎤 ANALIZANDO AUDIO CON GEMINI...');
        debugPrint('📁 Ruta: $audioPath');
        debugPrint('═══════════════════════════════════════');
      }

      // Analizar audio con Gemini
      final datosIA = await _analizarAudioConGemini(audioPath);
      
      if (datosIA == null) {
        _errorMessage = _errorMessage ?? 'No se pudo analizar el audio con IA';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Agregar datos adicionales
      datosIA['idUsuario'] = idUsuario;
      datosIA['audioPath'] = audioPath;
      
      _datosExtraidos = datosIA;
      _categoriaSugerida = datosIA['categoria'];
      _tipoTransaccion = datosIA['tipo']?.toString().toLowerCase(); // 'ingreso' o 'egreso'
      
      if (kDebugMode) {
        debugPrint('🤖 DATOS EXTRAÍDOS DEL AUDIO:');
        debugPrint('Tipo: ${_tipoTransaccion}');
        debugPrint('Monto: ${datosIA['monto']}');
        debugPrint('Descripción: ${datosIA['descripcion']}');
        debugPrint('Categoría: ${datosIA['categoria']}');
        
        if (_tipoTransaccion == 'egreso') {
          debugPrint('Proveedor: ${datosIA['proveedor']}');
          debugPrint('Lugar: ${datosIA['lugar']}');
        } else if (_tipoTransaccion == 'ingreso') {
          debugPrint('Origen: ${datosIA['origen']}');
          debugPrint('Método de pago: ${datosIA['metodoPago']}');
        }
        
        debugPrint('═══════════════════════════════════════');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al procesar audio: $e';
      _isLoading = false;
      if (kDebugMode) {
        debugPrint('❌ Error: $e');
      }
      notifyListeners();
    }
  }

  /// Analiza el audio con Gemini y retorna datos estructurados
  Future<Map<String, dynamic>?> _analizarAudioConGemini(String audioPath) async {
    if (_model == null) {
      _errorMessage = 'El modelo Gemini no está inicializado';
      return null;
    }

    try {
      // Leer el archivo de audio como bytes
      final audioFile = File(audioPath);
      final audioBytes = await audioFile.readAsBytes();
      
      // Obtener las categorías disponibles desde la base de datos
      if (_currentUserId == null) {
        _errorMessage = 'No se encontró el ID de usuario';
        return null;
      }
      
      final categoriasEgresosList = await _categoriaService.obtenerCategorias(_currentUserId!, TipoCategoria.egreso);
      final categoriasIngresosList = await _categoriaService.obtenerCategorias(_currentUserId!, TipoCategoria.ingreso);
      
      final categoriasEgresos = categoriasEgresosList
          .map((c) => c.nombre)
          .join(', ');
      
      final categoriasIngresos = categoriasIngresosList
          .map((c) => c.nombre)
          .join(', ');

      final prompt = '''
Analiza este audio donde una persona describe una transacción financiera (ingreso o egreso/gasto).

Tu tarea es:
1. Determinar si es un INGRESO o un EGRESO
2. Extraer todos los datos mencionados

Responde ÚNICAMENTE con un objeto JSON válido (sin markdown, sin bloques de código) con esta estructura:

Para INGRESOS:
{
  "tipo": "ingreso",
  "monto": "cantidad en números con punto decimal (ej: 1500.00)",
  "fecha": "fecha mencionada en formato YYYY-MM-DD, o fecha actual si no se menciona",
  "descripcion": "descripción o concepto del ingreso",
  "categoria": "una de estas categorías: $categoriasIngresos",
  "metodoPago": "método de pago mencionado (efectivo, transferencia, tarjeta, etc.)",
  "origen": "origen o fuente del ingreso (salario, venta, freelance, etc.)"
}

Para EGRESOS/GASTOS:
{
  "tipo": "egreso",
  "invoiceNumber": "número de factura si se menciona, o genera uno simple como 'VOZ-YYYY-MM-DD-XXX'",
  "invoiceDate": "fecha mencionada en formato YYYY-MM-DD, o fecha actual",
  "totalAmount": "monto total en números con punto decimal (ej: 847.00)",
  "supplierName": "nombre del proveedor, tienda o lugar del gasto",
  "supplierTaxId": "RFC/NIF si se menciona, o cadena vacía",
  "description": "descripción del gasto o servicio",
  "taxAmount": "impuestos si se mencionan, o 0.0",
  "lugarLocal": "lugar, dirección o ubicación del gasto",
  "categoria": "una de estas categorías: $categoriasEgresos"
}

REGLAS IMPORTANTES:
- PRIMERO determina si es ingreso o egreso analizando el contexto
- Palabras clave para INGRESO: "recibí", "me pagaron", "ingreso", "cobré", "ganancia", "salario", "venta"
- Palabras clave para EGRESO: "pagué", "compré", "gasto", "factura", "compra", "gasté", "egreso"
- Si no encuentras un campo, usa un string vacío "" o 0.0 para números
- Los montos deben ser solo números con punto decimal (ej: "125.50")
- NO incluyas símbolos de moneda
- La fecha debe estar en formato YYYY-MM-DD
- La categoría DEBE ser una de las listadas según el tipo
- Si el audio está poco claro, haz tu mejor inferencia basándote en el contexto
- Si no se menciona el tipo explícitamente, infiere del contexto (hablar de compras/gastos = egreso, hablar de recibir dinero = ingreso)
- Responde SOLO con el JSON, nada más
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          InlineDataPart('audio/mp3', audioBytes), // Ajustar mime type según formato
        ])
      ];
      
      final response = await _model!.generateContent(content);
      
      if (response.text == null) {
        _errorMessage = 'Gemini no generó respuesta del audio';
        return null;
      }

      // Limpiar respuesta
      String jsonString = response.text!.trim();
      jsonString = jsonString.replaceAll(RegExp(r'```json\s*'), '');
      jsonString = jsonString.replaceAll(RegExp(r'```\s*'), '');
      jsonString = jsonString.trim();
      
      if (kDebugMode) {
        debugPrint('📥 Respuesta de Gemini (Audio): $jsonString');
      }

      // Parsear JSON
      final Map<String, dynamic> result = json.decode(jsonString);
      
      // Validar que tenga el campo tipo
      if (!result.containsKey('tipo')) {
        _errorMessage = 'No se pudo determinar el tipo de transacción';
        return null;
      }

      final tipo = result['tipo'].toString().toLowerCase();
      
      // Validar campos según el tipo
      if (tipo == 'ingreso') {
        final camposRequeridos = ['monto', 'fecha', 'descripcion', 'categoria', 'metodoPago', 'origen'];
        for (final campo in camposRequeridos) {
          if (!result.containsKey(campo)) {
            result[campo] = '';
          }
        }
      } else if (tipo == 'egreso') {
        final camposRequeridos = [
          'invoiceNumber', 'invoiceDate', 'totalAmount', 
          'supplierName', 'supplierTaxId', 'description', 
          'taxAmount', 'lugarLocal', 'categoria'
        ];
        for (final campo in camposRequeridos) {
          if (!result.containsKey(campo)) {
            result[campo] = campo == 'taxAmount' ? '0.0' : '';
          }
        }
      } else {
        _errorMessage = 'Tipo de transacción no válido: $tipo';
        return null;
      }

      // Guardar categoría sugerida
      result['categoriaSugerida'] = result['categoria'];
      result['textoCompleto'] = 'Audio analizado por Gemini';
      
      return result;
      
    } catch (e) {
      _errorMessage = 'Error al analizar audio con Gemini: $e';
      if (kDebugMode) {
        debugPrint('❌ Error en _analizarAudioConGemini: $e');
      }
      return null;
    }
  }

  /// Cambia la categoría sugerida
  void cambiarCategoria(String nuevaCategoria) {
    _categoriaSugerida = nuevaCategoria;
    if (_datosExtraidos != null) {
      _datosExtraidos!['categoria'] = nuevaCategoria;
    }
    notifyListeners();
  }

  /// Limpia todos los datos
  void limpiarDatos() {
    _datosExtraidos = null;
    _categoriaSugerida = null;
    _tipoTransaccion = null;
    _errorMessage = null;
    _audioPath = null;
    _isRecording = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _model = null;
    super.dispose();
  }
}
