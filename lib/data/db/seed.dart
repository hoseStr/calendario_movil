import 'package:drift/drift.dart';

import 'database.dart';

/// TEMPORAL — Fase 3.
/// Eventos de muestra para ver el calendario pintado.
/// ELIMINAR en la Fase 4 (junto con su llamada en calendar_providers.dart)
/// cuando exista el CRUD real.
Future<void> seedDemoEvents(AppDatabase db) async {
  final existing = await db.select(db.events).get();
  if (existing.isNotEmpty) return;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  await db.batch((batch) {
    batch.insertAll(db.events, [
      EventsCompanion.insert(
        title: 'Clase de cálculo',
        description: const Value('Aula 302'),
        startAt: today.add(const Duration(hours: 10)),
        endAt: today.add(const Duration(hours: 12)),
        colorIndex: const Value(1),
        category: const Value('estudio'),
        createdAt: now,
        updatedAt: now,
      ),
      EventsCompanion.insert(
        title: 'Cita médica',
        startAt: today.add(const Duration(days: 1, hours: 15, minutes: 30)),
        endAt: today.add(const Duration(days: 1, hours: 16, minutes: 30)),
        colorIndex: const Value(2),
        category: const Value('personal'),
        reminderMinutes: const Value(30),
        createdAt: now,
        updatedAt: now,
      ),
      EventsCompanion.insert(
        title: 'Salida con amigos',
        startAt: today.add(const Duration(days: 3, hours: 19)),
        endAt: today.add(const Duration(days: 3, hours: 22)),
        colorIndex: const Value(5),
        category: const Value('ocio'),
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  });
}
