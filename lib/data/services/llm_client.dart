/// Interfaz del cliente LLM. La mascota no sabe qué modelo hay detrás:
/// hoy Gemini, mañana cualquier otro implementando esto.
abstract interface class LlmClient {
  /// Devuelve el texto generado, o null ante cualquier problema
  /// (sin red, clave inválida, cuota agotada…). Nunca lanza.
  Future<String?> generate({
    required String apiKey,
    required String system,
    required String user,
  });
}
