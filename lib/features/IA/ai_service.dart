import 'dart:async';

/// Prototipo mínimo de servicio de IA (reglas simples) para categorizar
/// transacciones. Esto sirve como PoC (sin dependencias externas) y se puede
/// reemplazar por un modelo TFLite o por llamadas a un servicio en la nube.

class AIResult {
  final String categoryId; // Id de categoría (puede mapearse a categorias)
  final double confidence; // 0.0 - 1.0
  final List<String> tags; // Etiquetas extraídas

  AIResult({
    required this.categoryId,
    required this.confidence,
    List<String>? tags,
  }) : tags = tags ?? [];

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'confidence': confidence,
    'tags': tags,
  };

  @override
  String toString() =>
      'AIResult(categoryId: $categoryId, confidence: $confidence, tags: $tags)';
}

class AIService {
  // Reglas clave-valor: categoría -> keywords
  final Map<String, List<String>> _keywordMap = {
    // Asumir que estas IDs se mapearán a categorías existentes en Firestore.
    'alimentacion': ['restaurante', 'comida', 'cafetería', 'cafe', 'bar'],
    'transporte': ['uber', 'taxi', 'metro', 'bus', 'boleto'],
    'salud': ['hospital', 'farmacia', 'doctor', 'consulta', 'medicamento'],
    'servicios': ['agua', 'luz', 'telefono', 'internet', 'gas'],
    'salario': ['nomina', 'salario', 'sueldo', 'pago'],
    'otros': [],
  };

  /// Categoriza una transacción usando reglas simples sobre la descripción.
  /// Inputs mínimos: userId (por privacidad/rastreo), description, amount, date.
  /// Retorna un [AIResult] con la categoría sugerida y una confianza estimada.
  Future<AIResult> categorizeTransaction({
    required String userId,
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    // Normalizar texto
    final text = description.toLowerCase();

    // Conteo de coincidencias por categoría
    final Map<String, int> counts = {for (var k in _keywordMap.keys) k: 0};

    for (final entry in _keywordMap.entries) {
      for (final kw in entry.value) {
        if (text.contains(kw)) counts[entry.key] = counts[entry.key]! + 1;
      }
    }

    // Elegir categoría con más coincidencias
    String chosen = 'otros';
    int maxCount = 0;
    counts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        chosen = key;
      }
    });

    // Calcular confianza básica: si no hay coincidencias, confianza baja
    double confidence;
    if (maxCount == 0) {
      // Heurística: si el monto es muy alto, sugerir "servicios"/"otros" con confianza moderada
      if (amount > 1000) {
        confidence = 0.5;
        chosen = 'otros';
      } else {
        confidence = 0.35;
      }
    } else {
      // Más coincidencias -> mayor confianza
      confidence = (0.5 + (maxCount / 10)).clamp(0.5, 0.95);
    }

    // Extraer tags (keywords halladas)
    final List<String> tags = [];
    _keywordMap.forEach((cat, kws) {
      for (final kw in kws) {
        if (text.contains(kw) && !tags.contains(kw)) tags.add(kw);
      }
    });

    // Pequeño retardo para simular procesamiento
    await Future.delayed(const Duration(milliseconds: 120));

    return AIResult(categoryId: chosen, confidence: confidence, tags: tags);
  }
}