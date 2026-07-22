import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/build_config.dart';
import '../../data/repositories/pet_message_repository.dart';
import '../../data/services/gemini_client.dart';
import '../../data/services/llm_client.dart';
import '../../data/services/pet_message_service.dart';
import '../../domain/entities/pet_message.dart';
import '../calendar/calendar_providers.dart';
import '../settings/settings_providers.dart';

final petMessageRepositoryProvider = Provider<PetMessageRepository>(
  (ref) => PetMessageRepository(ref.watch(databaseProvider)),
);

final llmClientProvider = Provider<LlmClient>((ref) => GeminiClient());

/// Generador de mensajes (gate de 30 min + Gemini + fallback).
final petMessageServiceProvider = Provider<PetMessageService>(
  (ref) => PetMessageService(
    ref.watch(eventRepositoryProvider),
    ref.watch(petMessageRepositoryProvider),
    ref.watch(llmClientProvider),
    // Clave embebida al compilar (secrets.json + --dart-define-from-file).
    () async =>
        BuildConfig.hasEmbeddedKey ? BuildConfig.embeddedGeminiKey : null,
    ref.watch(settingsRepositoryProvider),
  ),
);

/// Último mensaje de la mascota (reactivo: la UI se actualiza sola
/// cuando el servicio guarda uno nuevo).
final latestPetMessageProvider = StreamProvider<PetMessage?>(
  (ref) => ref
      .watch(petMessageRepositoryProvider)
      .watchHistory(limit: 1)
      .map((list) => list.isEmpty ? null : list.first),
);

/// Historial de mensajes (más recientes primero).
final petHistoryProvider = StreamProvider<List<PetMessage>>(
  (ref) => ref.watch(petMessageRepositoryProvider).watchHistory(),
);
