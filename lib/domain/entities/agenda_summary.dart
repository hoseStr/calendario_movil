/// Carga del día según la agenda.
enum DayLoad { free, normal, busy, veryBusy }

/// Estados de ánimo de la mascota (las animaciones llegan en Fase 8).
enum PetMood { sleeping, happy, cheering, celebrating, hurrying }

/// Resumen anonimizado de la agenda: solo conteos, nunca títulos.
/// Es lo único que se enviará a Gemini en la Fase 7 (modo privado).
class AgendaSummary {
  const AgendaSummary({
    required this.todayCount,
    required this.weekCount,
    required this.load,
    required this.mood,
  });

  final int todayCount;
  final int weekCount;
  final DayLoad load;
  final PetMood mood;
}
