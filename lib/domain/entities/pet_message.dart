import 'agenda_summary.dart';

/// Mensaje diario de la mascota.
class PetMessage {
  const PetMessage({
    this.id,
    required this.date,
    required this.mood,
    required this.message,
    required this.source,
  });

  final int? id;

  /// Día normalizado (sin hora).
  final DateTime date;
  final PetMood mood;
  final String message;

  /// 'gemini' | 'fallback'.
  final String source;

  PetMessage copyWith({int? id}) => PetMessage(
        id: id ?? this.id,
        date: date,
        mood: mood,
        message: message,
        source: source,
      );
}
