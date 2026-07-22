/// Valores inyectados en tiempo de compilación con --dart-define.
/// La clave NO vive en el código fuente: se pasa al compilar
/// (ver secrets.json en la raíz del proyecto).
abstract final class BuildConfig {
  static const String embeddedGeminiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasEmbeddedKey => embeddedGeminiKey.isNotEmpty;
}
