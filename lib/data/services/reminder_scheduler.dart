import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
import '../../domain/usecases/expand_recurrences.dart';
import '../db/database.dart';
import 'notification_service.dart';

/// Coordina eventos ↔ notificaciones.
/// El id de notificación es el id del evento (un recordatorio por evento).
class ReminderScheduler {
  ReminderScheduler(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  /// iOS admite 64 notificaciones pendientes; dejamos margen y al abrir
  /// la app se repone la ventana (rescheduleAll).
  static const int _maxPending = 50;

  /// Crear/editar evento: cancela lo anterior y programa lo nuevo.
  /// Para recurrentes se programa SOLO la próxima ocurrencia; al abrir
  /// la app (rescheduleAll) se renueva la siguiente.
  Future<void> syncEvent(Event event) async {
    final id = event.id;
    if (id == null) return;
    await cancelForEvent(id);

    final fireAt = _nextFireAt(event);
    if (fireAt == null) return;

    await _notifications.schedule(
      id: id,
      title: event.title,
      body: _body(fireAt.add(Duration(minutes: event.reminderMinutes!))),
      fireAt: fireAt,
      payload: '$id',
    );
    await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(
            eventId: id,
            fireAt: fireAt,
            notificationId: id,
          ),
        );
  }

  /// Próximo disparo del recordatorio (ocurrencia siguiente si es
  /// recurrente), o null si no aplica.
  DateTime? _nextFireAt(Event event) {
    final minutes = event.reminderMinutes;
    if (minutes == null) return null;
    final now = DateTime.now();
    // La ocurrencia debe empezar después de now + antelación para que
    // el disparo (inicio - antelación) quede en el futuro.
    final start = const ExpandRecurrences()
        .nextOccurrenceStart(event, now.add(Duration(minutes: minutes)));
    if (start == null) return null;
    final fireAt = start.subtract(Duration(minutes: minutes));
    return fireAt.isAfter(now) ? fireAt : null;
  }

  /// Borrar evento: cancela su notificación y limpia la bitácora.
  Future<void> cancelForEvent(int eventId) async {
    await _notifications.cancel(eventId);
    await (_db.delete(_db.reminders)
          ..where((t) => t.eventId.equals(eventId)))
        .go();
  }

  /// Red de seguridad al abrir la app: reprograma los próximos
  /// recordatorios (incluida la siguiente ocurrencia de cada serie
  /// recurrente). Cubre reinicios, actualizaciones y el tope de iOS.
  Future<void> rescheduleAll() async {
    final now = DateTime.now();
    await _db.delete(_db.reminders).go();

    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.reminderMinutes.isNotNull() &
              (t.startAt.isBiggerThanValue(now) |
                  t.recurrenceRule.isNotNull())))
        .get();

    // Calcula el próximo disparo de cada evento y ordena por cercanía.
    final candidates = <(DateTime, EventRow)>[];
    for (final row in rows) {
      final fireAt = _nextFireAt(_toEntity(row));
      if (fireAt != null) candidates.add((fireAt, row));
    }
    candidates.sort((a, b) => a.$1.compareTo(b.$1));

    for (final (fireAt, row) in candidates.take(_maxPending)) {
      await _notifications.schedule(
        id: row.id,
        title: row.title,
        body: _body(fireAt.add(Duration(minutes: row.reminderMinutes!))),
        fireAt: fireAt,
        payload: '${row.id}',
      );
      await _db.into(_db.reminders).insert(
            RemindersCompanion.insert(
              eventId: row.id,
              fireAt: fireAt,
              notificationId: row.id,
            ),
          );
    }
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

  String _body(DateTime startAt) =>
      'Empieza a las ${DateFormat('h:mm a').format(startAt)}';
}
