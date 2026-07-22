import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_gradients.dart';
import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/pet_message.dart';
import '../settings/settings_providers.dart';
import '../widgets/dreamy_pet.dart';
import 'pet_providers.dart';

/// Pantalla de la mascota: mensaje vigente + historial.
/// La imagen estática se reemplaza por animaciones en la Fase 8.
class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestPetMessageProvider).value;
    final history = ref.watch(petHistoryProvider).value ?? const [];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(ref.watch(petPrefsProvider).name.isEmpty
            ? 'Mascota'
            : ref.watch(petPrefsProvider).name),
      ),
      body: DreamyBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Gap.xl, Gap.sm, Gap.xl, Insets.bottomGap),
            children: [
              const SizedBox(height: 8),
              Center(
                child: DreamyPet(
                  mood: latest?.mood ?? PetMood.happy,
                  // Se adapta al ancho: ~45 % de la pantalla, con tope
                  // para no dominar en equipos grandes.
                  size: context.scaleCapped(160, 190),
                ),
              ),
              const SizedBox(height: 12),
              if (latest != null)
                Center(child: _MoodChip(mood: latest.mood)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    latest?.message ??
                        'Dame un segundo, estoy pensando qué decirte…',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                ),
              ),
              if (history.length > 1) ...[
                const SizedBox(height: 28),
                Text('Mensajes anteriores', style: textTheme.titleMedium),
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
        DateFormat("EEE d 'de' MMM · HH:mm", 'es').format(message.date);

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
