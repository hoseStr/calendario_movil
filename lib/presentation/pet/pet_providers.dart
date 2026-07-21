import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/fallback_messages.dart';
import '../../data/repositories/pet_message_repository.dart';
import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/pet_message.dart';
import '../../domain/usecases/summarize_agenda.dart';
import '../calendar/calendar_providers.dart';

final petMessageRepositoryProvider = Provider<PetMessageRepository>(
  (ref) => PetMessageRepository(ref.watch(databaseProvider)),
);

/// Resumen anonimizado de la agenda de hoy (solo conteos).
final agendaSummaryProvider = FutureProvider<AgendaSummary>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  final today = dayKey(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  final weekEnd = today.add(const Duration(days: 7));

  final todayEvents = await repo.watchEventsBetween(today, tomorrow).first;
  final weekEvents = await repo.watchEventsBetween(today, weekEnd).first;

  return const SummarizeAgenda()(
    todayCount: todayEvents.length,
    weekCount: weekEvents.length,
  );
});

/// Mensaje del día de la mascota. Máx. 1 por día: si ya existe en la BD
/// se reutiliza; si no, se genera del banco local y se guarda.
/// (En la Fase 7, Gemini se intenta primero y este banco queda de respaldo.)
final dailyPetMessageProvider = FutureProvider<PetMessage>((ref) async {
  final repo = ref.watch(petMessageRepositoryProvider);
  final today = dayKey(DateTime.now());

  final cached = await repo.getForDay(today);
  if (cached != null) return cached;

  final summary = await ref.watch(agendaSummaryProvider.future);
  return repo.save(PetMessage(
    date: today,
    mood: summary.mood,
    message: FallbackMessages.randomFor(summary.load),
    source: 'fallback',
  ));
});

/// Historial de mensajes (más recientes primero).
final petHistoryProvider = StreamProvider<List<PetMessage>>(
  (ref) => ref.watch(petMessageRepositoryProvider).watchHistory(),
);
