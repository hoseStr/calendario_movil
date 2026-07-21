import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../domain/entities/event.dart';
import 'calendar_providers.dart';

/// Pantalla principal: mes + lista de eventos del día seleccionado.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final eventsByDay = ref.watch(eventsByDayProvider);
    final dayEvents =
        ref.watch(selectedDayEventsProvider).value ?? const <Event>[];
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(title: const Text('Calendario')),
      body: DreamyBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              TableCalendar<Event>(
                locale: 'es',
                firstDay: DateTime(2020),
                lastDay: DateTime(2035, 12, 31),
                focusedDay: focusedMonth,
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                onDaySelected: (selected, focused) {
                  ref.read(selectedDayProvider.notifier).select(selected);
                  ref.read(focusedMonthProvider.notifier).focus(focused);
                },
                onPageChanged: (focused) =>
                    ref.read(focusedMonthProvider.notifier).focus(focused),
                eventLoader: (day) => eventsByDay[dayKey(day)] ?? const [],
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: textTheme.titleLarge ?? const TextStyle(),
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: scheme.primary),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: scheme.primary),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  outsideTextStyle:
                      TextStyle(color: scheme.onSurface.withValues(alpha: 0.3)),
                  weekendTextStyle: TextStyle(color: scheme.secondary),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 1.5),
                  ),
                  todayTextStyle: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final event in events.take(3))
                            Container(
                              width: 5,
                              height: 5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.eventCategories[
                                    event.colorIndex %
                                        AppColors.eventCategories.length],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dayTitle(selectedDay),
                    style: textTheme.titleMedium,
                  ),
                ),
              ),
              Expanded(
                child: dayEvents.isEmpty
                    ? Center(
                        child: Text(
                          'Nada agendado — día para soñar',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) =>
                            _EventCard(event: dayEvents[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/event/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _dayTitle(DateTime day) {
    final now = DateTime.now();
    if (isSameDay(day, now)) return 'Hoy';
    if (isSameDay(day, now.add(const Duration(days: 1)))) return 'Mañana';
    final formatted = DateFormat("EEEE d 'de' MMMM", 'es').format(day);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = AppColors
        .eventCategories[event.colorIndex % AppColors.eventCategories.length];
    final titleColor = HSLColor.fromColor(categoryColor)
        .withLightness(isDark ? 0.8 : 0.3)
        .toColor();
    final timeFormat = DateFormat.Hm();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${timeFormat.format(event.startAt)} – '
                      '${timeFormat.format(event.endAt)}'
                      '${event.reminderMinutes != null ? ' · recordatorio ${event.reminderMinutes} min antes' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
