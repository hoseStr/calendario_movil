import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_gradients.dart';
import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/pet_message.dart';
import 'pet_providers.dart';

/// Pantalla de la mascota: mensaje del día + historial.
/// La imagen estática se reemplaza por animaciones en la Fase 8.
class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyMessage = ref.watch(dailyPetMessageProvider);
    final history = ref.watch(petHistoryProvider).value ?? const [];
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(title: const Text('Mascota')),
      body: DreamyBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.pets, size: 72, color: scheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: dailyMessage.when(
                  data: (msg) => _MoodChip(mood: msg.mood),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
              dailyMessage.when(
                data: (msg) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      msg.message,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Hoy amanecí sin palabras… vuelve en un ratito.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (history.length > 1) ...[
                const SizedBox(height: 28),
                Text('Días anteriores', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final msg in history.skip(1))
                  _HistoryTile(message: msg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, icon) = switch (mood) {
      PetMood.sleeping => ('Relajada', Icons.nightlight_outlined),
      PetMood.happy => ('Feliz', Icons.sentiment_satisfied_outlined),
      PetMood.cheering => ('Animándote', Icons.emoji_events_outlined),
      PetMood.celebrating => ('Celebrando', Icons.celebration_outlined),
      PetMood.hurrying => ('Apurada', Icons.timer_outlined),
    };
    return Chip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      label: Text(label),
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
      side: BorderSide.none,
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.message});

  final PetMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final dateLabel =
        DateFormat("EEE d 'de' MMM", 'es').format(message.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(message.message, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
