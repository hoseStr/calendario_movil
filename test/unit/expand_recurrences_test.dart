import 'package:flutter_test/flutter_test.dart';

import 'package:calendario_movil/domain/entities/event.dart';
import 'package:calendario_movil/domain/usecases/expand_recurrences.dart';

void main() {
  const expand = ExpandRecurrences();

  Event build({
    DateTime? start,
    Duration duration = const Duration(hours: 1),
    String? rule,
  }) {
    final s = start ?? DateTime(2026, 7, 1, 10);
    return Event(
      id: 1,
      title: 'Evento',
      startAt: s,
      endAt: s.add(duration),
      recurrenceRule: rule,
      createdAt: s,
      updatedAt: s,
    );
  }

  group('expansión en rango', () {
    test('no recurrente: pasa solo si solapa', () {
      final event = build(start: DateTime(2026, 7, 10, 10));

      expect(
        expand([event], DateTime(2026, 7, 1), DateTime(2026, 8, 1)).length,
        1,
      );
      expect(
        expand([event], DateTime(2026, 8, 1), DateTime(2026, 9, 1)),
        isEmpty,
      );
    });

    test('diaria: una ocurrencia por día del rango', () {
      final event = build(
          start: DateTime(2026, 7, 1, 10), rule: RecurrenceRules.daily);

      final result =
          expand([event], DateTime(2026, 7, 10), DateTime(2026, 7, 13));

      expect(result.length, 3);
      expect(result[0].startAt, DateTime(2026, 7, 10, 10));
      expect(result[2].startAt, DateTime(2026, 7, 12, 10));
      expect(result[0].id, event.id); // comparte id con la base
    });

    test('semanal: mismo día de la semana', () {
      final event = build(
          start: DateTime(2026, 7, 1, 9), rule: RecurrenceRules.weekly);

      final result =
          expand([event], DateTime(2026, 7, 1), DateTime(2026, 8, 1));

      expect(result.map((e) => e.startAt.day).toList(), [1, 8, 15, 22, 29]);
    });

    test('mensual día 31: salta los meses cortos', () {
      final event = build(
          start: DateTime(2026, 1, 31, 8), rule: RecurrenceRules.monthly);

      final result =
          expand([event], DateTime(2026, 1, 1), DateTime(2026, 6, 1));

      // Ene, Mar, May (feb y abr no tienen 31).
      expect(result.map((e) => e.startAt.month).toList(), [1, 3, 5]);
      expect(result.every((e) => e.startAt.day == 31), isTrue);
    });

    test('la serie no genera ocurrencias antes de su inicio', () {
      final event = build(
          start: DateTime(2026, 7, 15, 10), rule: RecurrenceRules.daily);

      final result =
          expand([event], DateTime(2026, 7, 10), DateTime(2026, 7, 17));

      expect(result.first.startAt, DateTime(2026, 7, 15, 10));
      expect(result.length, 2);
    });
  });

  group('nextOccurrenceStart', () {
    test('no recurrente: su inicio si es futuro, null si pasó', () {
      final event = build(start: DateTime(2026, 7, 10, 10));

      expect(
        expand.nextOccurrenceStart(event, DateTime(2026, 7, 5)),
        DateTime(2026, 7, 10, 10),
      );
      expect(
        expand.nextOccurrenceStart(event, DateTime(2026, 7, 20)),
        isNull,
      );
    });

    test('diaria: siguiente ocurrencia estricta', () {
      final event = build(
          start: DateTime(2026, 7, 1, 10), rule: RecurrenceRules.daily);

      expect(
        expand.nextOccurrenceStart(event, DateTime(2026, 7, 10, 10)),
        DateTime(2026, 7, 11, 10),
      );
      expect(
        expand.nextOccurrenceStart(event, DateTime(2026, 7, 10, 9, 59)),
        DateTime(2026, 7, 10, 10),
      );
    });
  });
}
