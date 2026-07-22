import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/fallback_messages.dart';
import '../../core/theme/app_gradients.dart';
import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/event.dart';
import '../app_providers.dart';
import '../event_form/event_providers.dart';
import '../widgets/dreamy_pet.dart';

/// Pantalla de alarma a pantalla completa (se muestra sobre el bloqueo).
/// Desde la Fase 6-8 la mascota animada vivirá aquí.
class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(eventId);
    final asyncEvent =
        id == null ? null : ref.watch(eventByIdProvider(id));
    final event = asyncEvent?.value;

    return Scaffold(
      body: DreamyBackground(
        child: SafeArea(
          child: event == null
              ? const Center(child: CircularProgressIndicator())
              : _AlarmContent(event: event),
        ),
      ),
    );
  }
}

class _AlarmContent extends ConsumerWidget {
  const _AlarmContent({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final petMessage = FallbackMessages.randomHurry();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            event.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            _subtitle(event.startAt),
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(flex: 1),
          // La mascota, apurándote con cariño.
          const DreamyPet(mood: PetMood.hurrying, size: 130),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text(
                petMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ),
          ),
          const Spacer(flex: 2),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => _dismiss(context, ref),
            child: const Text('Descartar'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => _snooze(context, ref),
            child: const Text('Aplazar 5 min'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/event/${event.id}'),
            child: const Text('Ver detalle'),
          ),
        ],
      ),
    );
  }

  String _subtitle(DateTime startAt) {
    final time = DateFormat.Hm().format(startAt);
    final diff = startAt.difference(DateTime.now()).inMinutes;
    if (diff > 1) return 'Hoy $time · comienza en $diff min';
    if (diff >= 0) return 'Hoy $time · ¡comienza ya!';
    return 'Hoy $time · empezó hace ${-diff} min';
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    await ref.read(notificationServiceProvider).cancel(event.id!);
    if (context.mounted) context.go('/');
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref) async {
    final notifications = ref.read(notificationServiceProvider);
    await notifications.cancel(event.id!);
    await notifications.schedule(
      id: event.id!,
      title: event.title,
      body: 'Aplazado 5 minutos',
      fireAt: DateTime.now().add(const Duration(minutes: 5)),
      payload: '${event.id}',
    );
    if (context.mounted) context.go('/');
  }
}
