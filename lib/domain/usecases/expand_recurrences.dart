import '../entities/event.dart';

/// Reglas soportadas en events.recurrence_rule.
abstract final class RecurrenceRules {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';

  static const Map<String?, String> labels = {
    null: 'Nunca',
    daily: 'Cada día',
    weekly: 'Cada semana',
    monthly: 'Cada mes',
  };
}

/// Expande eventos recurrentes en ocurrencias virtuales dentro de un
/// rango. Las ocurrencias comparten el id del evento base (editar o
/// borrar afecta a toda la serie).
class ExpandRecurrences {
  const ExpandRecurrences();

  static const int _safetyCap = 5000;

  /// Filtra los no recurrentes por solape y expande los recurrentes.
  /// Devuelve la lista ordenada por inicio.
  List<Event> call(List<Event> events, DateTime from, DateTime to) {
    final result = <Event>[];
    for (final event in events) {
      if (event.recurrenceRule == null) {
        if (event.startAt.isBefore(to) && !event.endAt.isBefore(from)) {
          result.add(event);
        }
      } else {
        result.addAll(_occurrencesInRange(event, from, to));
      }
    }
    result.sort((a, b) => a.startAt.compareTo(b.startAt));
    return result;
  }

  /// Inicio de la primera ocurrencia estrictamente posterior a [after],
  /// o null si la regla es inválida o no hay ocurrencia razonable.
  DateTime? nextOccurrenceStart(Event event, DateTime after) {
    final rule = event.recurrenceRule;
    var start = event.startAt;
    if (rule == null) return start.isAfter(after) ? start : null;

    var i = 0;
    while (i < _safetyCap) {
      if (start.isAfter(after)) return start;
      final next = _advance(start, rule);
      if (next == null) return null;
      start = next;
      i++;
    }
    return null;
  }

  Iterable<Event> _occurrencesInRange(
      Event event, DateTime from, DateTime to) sync* {
    final rule = event.recurrenceRule!;
    final duration = event.endAt.difference(event.startAt);
    var start = event.startAt;
    var i = 0;

    while (start.isBefore(to) && i < _safetyCap) {
      final end = start.add(duration);
      if (!end.isBefore(from)) {
        yield event.copyWith(startAt: start, endAt: end);
      }
      final next = _advance(start, rule);
      if (next == null) return;
      start = next;
      i++;
    }
  }

  DateTime? _advance(DateTime start, String rule) {
    switch (rule) {
      case RecurrenceRules.daily:
        return start.add(const Duration(days: 1));
      case RecurrenceRules.weekly:
        return start.add(const Duration(days: 7));
      case RecurrenceRules.monthly:
        // Mismo día del mes; los meses sin ese día se saltan
        // (ej.: el 31 no ocurre en abril).
        var year = start.year;
        var month = start.month;
        for (var i = 0; i < 24; i++) {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
          final candidate = DateTime(year, month, start.day, start.hour,
              start.minute, start.second);
          if (candidate.day == start.day) return candidate;
        }
        return null;
      default:
        return null;
    }
  }
}
