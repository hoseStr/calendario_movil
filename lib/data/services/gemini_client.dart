import 'package:dio/dio.dart';

import 'llm_client.dart';

/// Cliente REST de Gemini (Google AI Studio, capa gratuita).
class GeminiClient implements LlmClient {
  GeminiClient({Dio? dio, this.model = defaultModel})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Alias que apunta siempre al flash-lite vigente.
  static const String defaultModel = 'gemini-flash-lite-latest';

  final Dio _dio;
  final String model;

  @override
  Future<String?> generate({
    required String apiKey,
    required String system,
    required String user,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        options: Options(headers: {'x-goog-api-key': apiKey}),
        data: {
          'system_instruction': {
            'parts': [
              {'text': system}
            ]
          },
          'contents': [
            {
              'parts': [
                {'text': user}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 1.1,
            'maxOutputTokens': 500,
          },
        },
      );

      final candidates = response.data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts = ((candidates.first as Map<String, dynamic>)['content']
          as Map<String, dynamic>?)?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;
      final text = (parts.first as Map<String, dynamic>)['text'] as String?;
      final trimmed = text?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    } catch (_) {
      // Sin red, clave inválida, cuota, respuesta rara… da igual:
      // el llamador usará el banco local.
      return null;
    }
  }
}
