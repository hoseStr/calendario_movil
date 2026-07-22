import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/data/repositories/event_repository.dart';
import 'package:calendario_movil/domain/entities/event.dart';

void main() {
  late AppDatabase db;
  late EventRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = EventRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Event buildEvent({
    String title = 'Evento de prueba',
    DateTime? start,
    DateTime? end,
  }) {
    final s = start ?? DateTime(2026, 7, 21, 10);
    return Event(
      title: title,
      startAt: s,
      endAt: end ?? s.add(const Duration(hours: 1)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('EventRepository', () {
    test('create asigna id y getById lo recupera', () async {
      final created = await repo.create(buildEvent(title: 'Clase de cálculo'));

      expect(created.id, isNotNull);

      final found = await repo.getById(created.id!);
      expect(found, isNotNull);
      expect(found!.title, 'Clase de cálculo');
      expect(found.startAt, DateTime(2026, 7, 21, 10));
    });

    test('getById devuelve null si no existe', () async {
      expect(await repo.getById(999), isNull);
    });

    test('update modifica los campos', () async {
      final created = await repo.create(buildEvent());

      await repo.update(created.copyWith(
        title: 'Título nuevo',
        colorIndex: 3,
      ));

      final found = await repo.getById(created.id!);
      expect(found!.title, 'Título nuevo');
      expect(found.colorIndex, 3);
    });

    test('update sin id lanza ArgumentError', () async {
      expect(() => repo.update(buildEvent()), throwsArgumentError);
    });

    test('delete elimina el evento', () async {
      final created = await repo.create(buildEvent());

      await repo.delete(created.id!);

      expect(await repo.getById(created.id!), isNull);
    });

    test('watchEventsBetween filtra por rango y ordena por inicio', () async {
      await repo.create(buildEvent(
        title: 'Dentro B',
        start: DateTime(2026, 7, 15, 14),
      ));
      await repo.create(buildEvent(
        title: 'Dentro A',
        start: DateTime(2026, 7, 15, 9),
      ));
      await repo.create(buildEvent(
        title: 'Fuera (junio)',
        start: DateTime(2026, 6, 1, 9),
      ));

      final events = await repo
          .watchEventsBetween(DateTime(2026, 7, 1), DateTime(2026, 8, 1))
          .first;

      expect(events.length, 2);
      expect(events[0].title, 'Dentro A');
      expect(events[1].title, 'Dentro B');
    });

    test('watchEventsBetween incluye eventos que cruzan el borde del rango',
        () async {
      await repo.create(buildEvent(
        title: 'Cruza medianoche',
        start: DateTime(2026, 6, 30, 23),
        end: DateTime(2026, 7, 1, 1),
      ));

      final events = await repo
          .watchEventsBetween(DateTime(2026, 7, 1), DateTime(2026, 8, 1))
          .first;

      expect(events.length, 1);
      expect(events[0].title, 'Cruza medianoche');
    });

    test('watchById emite el evento y null tras borrarlo', () async {
      final created = await repo.create(buildEvent(title: 'Observado'));

      final first = await repo.watchById(created.id!).first;
      expect(first?.title, 'Observado');

      await repo.delete(created.id!);

      final after = await repo.watchById(created.id!).first;
      expect(after, isNull);
    });

    test('watchEventsBetween expande eventos recurrentes', () async {
      final base = buildEvent(
        title: 'Yoga diaria',
        start: DateTime(2026, 6, 1, 7),
      );
      await repo.create(Event(
        title: base.title,
        startAt: base.startAt,
        endAt: base.endAt,
        recurrenceRule: 'daily',
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      ));

      final events = await repo
          .watchEventsBetween(DateTime(2026, 7, 10), DateTime(2026, 7, 13))
          .first;

      expect(events.length, 3);
      expect(events.every((e) => e.title == 'Yoga diaria'), isTrue);
      expect(events[0].startAt, DateTime(2026, 7, 10, 7));
    });

    test('search encuentra por título y descripción', () async {
      await repo.create(buildEvent(title: 'Cita con el dentista'));
      final withDesc = buildEvent(title: 'Reunión');
      await repo.create(Event(
        title: withDesc.title,
        description: 'Llevar informe del dentista',
        startAt: withDesc.startAt,
        endAt: withDesc.endAt,
        createdAt: withDesc.createdAt,
        updatedAt: withDesc.updatedAt,
      ));
      await repo.create(buildEvent(title: 'Gimnasio'));

      final results = await repo.search('dentista');

      expect(results.length, 2);
    });

    test('el stream emite de nuevo al insertar', () async {
      final stream = repo.watchEventsBetween(
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
      );

      final futureEmissions = stream.take(2).toList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.create(buildEvent(start: DateTime(2026, 7, 10, 8)));

      final emissions = await futureEmissions;
      expect(emissions[0], isEmpty);
      expect(emissions[1].length, 1);
    });
  });
}
