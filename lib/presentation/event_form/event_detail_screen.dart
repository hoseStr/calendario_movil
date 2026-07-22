import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_gradients.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/expand_recurrences.dart';
import '../app_providers.dart';
import '../calendar/calendar_providers.dart';
import 'event_providers.dart';

/// Detalle de un evento con acciones de editar y eliminar.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(eventId);
    if (id == null) {
      return _MessageScaffold(message: 'Evento no válido');
    }

    final asyncEvent = ref.watch(eventByIdProvider(id));
    return asyncEvent.when(
      loading: () => const _MessageScaffold(loading: true),
      error: (error, _) =>
          _MessageScaffold(message: 'No se pudo cargar el evento'),
      data: (event) {
        if (event == null) {
          return const _MessageScaffold(message: 'Evento no encontrado');
        }
        return _EventDetailView(event: event);
      },
    );
  }
}

class _EventDetailView extends ConsumerWidget {
  const _EventDetailView({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = AppColors
        .eventCategories[event.colorIndex % AppColors.eventCategories.length];
    final titleColor = HSLColor.fromColor(categoryColor)
        .withLightness(isDark ? 0.8 : 0.3)
        .toColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => context.push('/event/${event.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: DreamyBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Gap.xl, Gap.sm, Gap.xl, Gap.xxxl),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 44,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      event.title,
                      style: textTheme.headlineMedium
                          ?.copyWith(color: titleColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(
                icon: Icons.schedule,
                text: _formatRange(event.startAt, event.endAt),
              ),
              if (event.recurrenceRule != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.repeat,
                  text:
                      'Se repite: ${RecurrenceRules.labels[event.recurrenceRule]?.toLowerCase() ?? event.recurrenceRule!}',
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.notifications_outlined,
                text: event.reminderMinutes == null
                    ? 'Sin recordatorio'
                    : _formatReminder(event.reminderMinutes!),
              ),
              if (event.description != null) ...[
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      event.description!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    final dayFormat = DateFormat("EEEE d 'de' MMMM", 'es');
    final timeFormat = DateFormat('h:mm a');
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final startDay = _capitalize(dayFormat.format(start));
    if (sameDay) {
      return '$startDay\n'
          '${timeFormat.format(start)} – ${timeFormat.format(end)}';
    }
    final endDay = _capitalize(dayFormat.format(end));
    return 'Desde: $startDay, ${timeFormat.format(start)}\n'
        'Hasta: $endDay, ${timeFormat.format(end)}';
  }

  String _formatReminder(int minutes) {
    if (minutes == 0) return 'Al momento del evento';
    if (minutes < 60) return '$minutes minutos antes';
    if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hora antes' : '$hours horas antes';
    }
    final days = minutes ~/ 1440;
    return days == 1 ? '1 día antes' : '$days días antes';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: Text('"${event.title}" se eliminará definitivamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Cancela la alarma antes de borrar el evento.
    await ref.read(reminderSchedulerProvider).cancelForEvent(event.id!);
    await ref.read(eventRepositoryProvider).delete(event.id!);
    if (context.mounted) context.pop();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold({this.message, this.loading = false});

  final String? message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Detalle')),
      body: DreamyBackground(
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Text(message ?? '',
                  style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}
