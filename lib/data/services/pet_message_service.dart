import '../../core/constants/fallback_messages.dart';
import '../../core/constants/pet_prompt.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/pet_message.dart';
import '../../domain/usecases/summarize_agenda.dart';
import '../repositories/event_repository.dart';
import '../repositories/pet_message_repository.dart';
import '../repositories/settings_repository.dart';
import 'llm_client.dart';

/// Genera el mensaje de la mascota: Gemini si hay clave e internet,
/// banco local si no. El usuario NUNCA ve un error.
class PetMessageService {
  PetMessageService(
    this._events,
    this._messages,
    this._llm,
    this._readApiKey,
    this._settings,
  );

  final EventRepository _events;
  final PetMessageRepository _messages;
  final LlmClient _llm;
  final Future<String?> Function() _readApiKey;
  final SettingsRepository _settings;

  /// Tope de generaciones por día POR DISPOSITIVO (protege la cuota
  /// gratuita de ~1.000 peticiones diarias de la clave compartida).
  static const int maxDailyGenerations = 500;

  /// Genera un mensaje nuevo en cada llamada (cada apertura de la app),
  /// salvo que ya se haya alcanzado el tope diario: en ese caso
  /// devuelve el último. [force] se mantiene por compatibilidad con el
  /// botón de refresco (mismo comportamiento).
  Future<PetMessage> ensureFreshMessage({bool force = false}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final last = await _messages.latest();
    if (last != null &&
        await _messages.countSince(today) >= maxDailyGenerations) {
      return last;
    }
    final tomorrow = today.add(const Duration(days: 1));
    final todayEvents = await _events.watchEventsBetween(today, tomorrow).first;
    final weekEvents = await _events
        .watchEventsBetween(today, today.add(const Duration(days: 7)))
        .first;
    final monthEvents = await _events
        .watchEventsBetween(today, today.add(const Duration(days: 30)))
        .first;

    final summary = const SummarizeAgenda()(
      todayCount: todayEvents.length,
      weekCount: weekEvents.length,
      monthCount: monthEvents.length,
    );

    Event? next;
    for (final event in todayEvents) {
      if (event.startAt.isAfter(now)) {
        next = event;
        break;
      }
    }

    String? text;
    var source = 'fallback';
    final apiKey = await _readApiKey();
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      final generated = await _llm.generate(
        apiKey: apiKey.trim(),
        system: PetPrompt.systemWith(
          name: await _settings.get('pet_name'),
          personality: await _settings.get('pet_personality'),
        ),
        user: PetPrompt.user(
          summary: summary,
          todayTitles: todayEvents.map((e) => e.title).toList(),
          nextEventStart: next?.startAt,
          recentMessages: await _messages.recentTexts(3),
          now: now,
        ),
      );
      if (generated != null) {
        text = _sanitize(generated);
        source = 'gemini';
      }
    }
    text ??= FallbackMessages.randomFor(summary.load);

    return _messages.save(PetMessage(
      date: now,
      mood: summary.mood,
      message: text,
      source: source,
    ));
  }

  /// Limpia la respuesta del modelo: comillas envolventes, saltos de
  /// línea y longitud desmedida.
  String _sanitize(String raw) {
    var text = raw.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    if (text.length >= 2 &&
        (text.startsWith('"') && text.endsWith('"') ||
            text.startsWith('«') && text.endsWith('»'))) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.length > 260) {
      text = '${text.substring(0, 257)}…';
    }
    return text;
  }
}
