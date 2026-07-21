import '../entities/agenda_summary.dart';

/// Clasifica el día según los conteos de la agenda y deriva el
/// estado de ánimo de la mascota. Lógica pura, sin dependencias.
class SummarizeAgenda {
  const SummarizeAgenda();

  AgendaSummary call({required int todayCount, required int weekCount}) {
    final load = switch (todayCount) {
      0 => DayLoad.free,
      1 || 2 => DayLoad.normal,
      3 || 4 => DayLoad.busy,
      _ => DayLoad.veryBusy,
    };

    final mood = switch (load) {
      DayLoad.free => PetMood.sleeping,
      DayLoad.normal => PetMood.happy,
      DayLoad.busy || DayLoad.veryBusy => PetMood.cheering,
    };

    return AgendaSummary(
      todayCount: todayCount,
      weekCount: weekCount,
      load: load,
      mood: mood,
    );
  }
}
