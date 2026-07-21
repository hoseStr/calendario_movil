import 'package:drift/drift.dart';

import '../../domain/entities/event.dart';
import '../db/database.dart';

/// Acceso a eventos. La UI nunca toca drift directamente:
/// consume esta clase (vía provider en Fase 3).
class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  /// Stream reactivo de los eventos que se solapan con [from, to).
  /// Se emite de nuevo automáticamente ante cualquier cambio.
  Stream<List<Event>> watchEventsBetween(DateTime from, DateTime to) {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.startAt.isSmallerThanValue(to) &
          t.endAt.isBiggerOrEqualValue(from))
      ..orderBy([(t) => OrderingTerm.asc(t.startAt)]);
    return query.watch().map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  /// Inserta y devuelve la entidad con su id asignado.
  Future<Event> create(Event event) async {
    final now = DateTime.now();
    final id = await _db.into(_db.events).insert(
          EventsCompanion.insert(
            title: event.title,
            description: Value(event.description),
            startAt: event.startAt,
            endAt: event.endAt,
            colorIndex: Value(event.colorIndex),
            category: Value(event.category),
            recurrenceRule: Value(event.recurrenceRule),
            reminderMinutes: Value(event.reminderMinutes),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return event.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  /// Actualiza por id. Lanza ArgumentError si la entidad no tiene id.
  Future<void> update(Event event) async {
    final id = event.id;
    if (id == null) {
      throw ArgumentError('No se puede actualizar un evento sin id');
    }
    await (_db.update(_db.events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(
        title: Value(event.title),
        description: Value(event.description),
        startAt: Value(event.startAt),
        endAt: Value(event.endAt),
        colorIndex: Value(event.colorIndex),
        category: Value(event.category),
        recurrenceRule: Value(event.recurrenceRule),
        reminderMinutes: Value(event.reminderMinutes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
  }

  /// Stream reactivo de un evento por id. Emite null si no existe
  /// (por ejemplo, tras borrarlo).
  Stream<Event?> watchById(int id) {
    final query = _db.select(_db.events)..where((t) => t.id.equals(id));
    return query
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toEntity(row));
  }

  Future<Event?> getById(int id) async {
    final row = await (_db.select(_db.events)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Event _toEntity(EventRow row) => Event(
        id: row.id,
        title: row.title,
        description: row.description,
        startAt: row.startAt,
        endAt: row.endAt,
        colorIndex: row.colorIndex,
        category: row.category,
        recurrenceRule: row.recurrenceRule,
        reminderMinutes: row.reminderMinutes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
