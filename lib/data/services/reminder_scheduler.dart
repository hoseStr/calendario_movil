import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/event.dart';
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
  Future<void> syncEvent(Event event) async {
    final id = event.id;
    if (id == null) return;
    await cancelForEvent(id);

    final minutes = event.reminderMinutes;
    if (minutes == null) return;
    final fireAt = event.startAt.subtract(Duration(minutes: minutes));
    if (!fireAt.isAfter(DateTime.now())) return;

    await _notifications.schedule(
      id: id,
      title: event.title,
      body: _body(event.startAt),
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

  /// Borrar evento: cancela su notificación y limpia la bitácora.
  Future<void> cancelForEvent(int eventId) async {
    await _notifications.cancel(eventId);
    await (_db.delete(_db.reminders)
          ..where((t) => t.eventId.equals(eventId)))
        .go();
  }

  /// Red de seguridad al abrir la app: reprograma los próximos
  /// recordatorios. Cubre reinicios del dispositivo, actualizaciones de
  /// la app y el tope de pendientes de iOS.
  Future<void> rescheduleAll() async {
    final now = DateTime.now();
    await _db.delete(_db.reminders).go();

    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.reminderMinutes.isNotNull() &
              t.startAt.isBiggerThanValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();

    var scheduled = 0;
    for (final row in rows) {
      if (scheduled >= _maxPending) break;
      final fireAt =
          row.startAt.subtract(Duration(minutes: row.reminderMinutes!));
      if (!fireAt.isAfter(now)) continue;

      await _notifications.schedule(
        id: row.id,
        title: row.title,
        body: _body(row.startAt),
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
      scheduled++;
    }
  }

  String _body(DateTime startAt) =>
      'Empieza a las ${DateFormat.Hm().format(startAt)}';
}
