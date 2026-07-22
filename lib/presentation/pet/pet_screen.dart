import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_gradients.dart';
import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/pet_message.dart';
import 'pet_providers.dart';

/// Pantalla de la mascota: mensaje vigente + historial.
/// La imagen estática se reemplaza por animaciones en la Fase 8.
class PetScreen extends ConsumerStatefulWidget {
  const PetScreen({super.key});

  @override
  ConsumerState<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends ConsumerState<PetScreen> {
  bool _generating = false;

  Future<void> _refresh() async {
    setState(() => _generating = true);
    await ref.read(petMessageServiceProvider).ensureFreshMessage(force: true);
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final latest = ref.watch(latestPetMessageProvider).value;
    final history = ref.watch(petHistoryProvider).value ?? const [];
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Mascota'),
        actions: [
          IconButton(
            tooltip: 'Nuevo mensaje',
            onPressed: _generating ? null : _refresh,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
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
