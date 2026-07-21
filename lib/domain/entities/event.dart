/// Entidad de dominio pura: sin dependencias de drift ni Flutter.
/// La capa de datos la mapea desde/hacia la tabla `events`.
class Event {
  const Event({
    this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    this.colorIndex = 0,
    this.category,
    this.recurrenceRule,
    this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// null solo antes de persistirse por primera vez.
  final int? id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;

  /// Índice en AppColors.eventCategories.
  final int colorIndex;
  final String? category;

  /// Regla de recurrencia simple (Fase 9): 'daily' | 'weekly' | 'monthly'.
  final String? recurrenceRule;

  /// Minutos de antelación del recordatorio; null = sin recordatorio.
  final int? reminderMinutes;

  final DateTime createdAt;
  final DateTime updatedAt;

  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    int? colorIndex,
    String? category,
    String? recurrenceRule,
    int? reminderMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      colorIndex: colorIndex ?? this.colorIndex,
      category: category ?? this.category,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.startAt == startAt &&
          other.endAt == endAt &&
          other.colorIndex == colorIndex &&
          other.category == category &&
          other.recurrenceRule == recurrenceRule &&
          other.reminderMinutes == reminderMinutes;

  @override
  int get hashCode => Object.hash(id, title, description, startAt, endAt,
      colorIndex, category, recurrenceRule, reminderMinutes);
}
