import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/db/database.dart';
import '../../data/repositories/event_repository.dart';
import '../../domain/entities/event.dart';

/// Normaliza una fecha a su día (sin hora). Clave de los mapas por día.
DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Base de datos única de la app. En tests se sobreescribe con
/// AppDatabase.forTesting(NativeDatabase.memory()).
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(databaseProvider)),
);

/// Día seleccionado en el calendario.
class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dayKey(DateTime.now());

  void select(DateTime day) => state = dayKey(day);
}

final selectedDayProvider =
    NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

/// Día en foco del calendario: define la página (mes) y la semana visible.
/// Se guarda el día real (normalizado a medianoche), NO el primero del mes,
/// para que las vistas de semana / 2 semanas se alineen correctamente y el
/// día actual / seleccionado quede dentro de la ventana visible.
class FocusedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dayKey(DateTime.now());

  void focus(DateTime day) => state = dayKey(day);
}

final focusedDayProvider =
    NotifierProvider<FocusedDayNotifier, DateTime>(FocusedDayNotifier.new);

/// Formato del calendario (mes / 2 semanas / semana).
class CalendarFormatNotifier extends Notifier<CalendarFormat> {
  @override
  CalendarFormat build() => CalendarFormat.month;

  void set(CalendarFormat format) => state = format;
}

final calendarFormatProvider =
    NotifierProvider<CalendarFormatNotifier, CalendarFormat>(
        CalendarFormatNotifier.new);

/// Stream reactivo de eventos del mes visible (± 1 semana para cubrir
/// los días de meses vecinos que se ven en la cuadrícula).
final monthEventsProvider = StreamProvider<List<Event>>((ref) {
  // Solo depende del mes: seleccionar un día o mover el foco dentro del mismo
  // mes no recrea la suscripción a la BD (evita jank al deslizar el calendario).
  final month = ref.watch(
    focusedDayProvider.select((d) => DateTime(d.year, d.month)),
  );
  final from = month.subtract(const Duration(days: 7));
  final to =
      DateTime(month.year, month.month + 1, 1).add(const Duration(days: 7));
  return ref.watch(eventRepositoryProvider).watchEventsBetween(from, to);
});

/// Eventos agrupados por día (un evento multi-día aparece en cada día).
final eventsByDayProvider = Provider<Map<DateTime, List<Event>>>((ref) {
  final events = ref.watch(monthEventsProvider).value ?? const <Event>[];
  final map = <DateTime, List<Event>>{};
  for (final event in events) {
    var day = dayKey(event.startAt);
    final last = dayKey(event.endAt);
    while (!day.isAfter(last)) {
      map.putIfAbsent(day, () => []).add(event);
      day = day.add(const Duration(days: 1));
    }
  }
  return map;
});

/// Eventos del día seleccionado, con stream propio a la base de datos.
/// Independiente del mes visible: si navegas a otro mes, la lista del
/// día seleccionado sigue mostrando sus eventos.
final selectedDayEventsProvider = StreamProvider<List<Event>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref
      .watch(eventRepositoryProvider)
      .watchEventsBetween(day, day.add(const Duration(days: 1)));
});
