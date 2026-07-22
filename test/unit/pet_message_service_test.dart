import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/data/repositories/event_repository.dart';
import 'package:calendario_movil/data/repositories/pet_message_repository.dart';
import 'package:calendario_movil/data/repositories/settings_repository.dart';
import 'package:calendario_movil/data/services/llm_client.dart';
import 'package:calendario_movil/data/services/pet_message_service.dart';

class FakeLlm implements LlmClient {
  FakeLlm({this.response});

  String? response;
  int calls = 0;
  String? lastUserPrompt;

  @override
  Future<String?> generate({
    required String apiKey,
    required String system,
    required String user,
  }) async {
    calls++;
    lastUserPrompt = user;
    return response;
  }
}

void main() {
  setUpAll(() async {
    // El prompt formatea fechas con locale 'es'.
    await initializeDateFormatting('es');
  });

  late AppDatabase db;
  late PetMessageRepository messages;
  late EventRepository events;
  late FakeLlm llm;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    messages = PetMessageRepository(db);
    events = EventRepository(db);
    llm = FakeLlm();
  });

  tearDown(() async {
    await db.close();
  });

  PetMessageService buildService({String? apiKey}) => PetMessageService(
        events,
        messages,
        llm,
        () async => apiKey,
        SettingsRepository(db),
      );

  test('sin API key usa el banco local y no llama al LLM', () async {
    final msg = await buildService(apiKey: null).ensureFreshMessage();

    expect(msg.source, 'fallback');
    expect(msg.message, isNotEmpty);
    expect(llm.calls, 0);
  });

  test('con API key y respuesta del LLM guarda source gemini', () async {
    llm.response = '¡Ánimo humano, tú puedes!';
    final msg = await buildService(apiKey: 'key').ensureFreshMessage();

    expect(msg.source, 'gemini');
    expect(msg.message, '¡Ánimo humano, tú puedes!');
    expect(llm.calls, 1);
  });

  test('si el LLM falla (null) cae al banco local sin error', () async {
    llm.response = null;
    final msg = await buildService(apiKey: 'key').ensureFreshMessage();

    expect(msg.source, 'fallback');
    expect(msg.message, isNotEmpty);
    expect(llm.calls, 1);
  });

  test('cada llamada (apertura) genera un mensaje nuevo', () async {
    llm.response = 'Primero';
    final service = buildService(apiKey: 'key');

    final first = await service.ensureFreshMessage();
    llm.response = 'Segundo';
    final second = await service.ensureFreshMessage();

    expect(first.message, 'Primero');
    expect(second.message, 'Segundo');
    expect(second.id, isNot(first.id));
    expect(llm.calls, 2);
  });

  test('al llegar al tope diario reutiliza el último', () async {
    llm.response = 'Mensaje';
    final service = buildService(apiKey: 'key');

    for (var i = 0; i < PetMessageService.maxDailyGenerations; i++) {
      await service.ensureFreshMessage();
    }
    expect(llm.calls, PetMessageService.maxDailyGenerations);

    final extra = await service.ensureFreshMessage();
    expect(llm.calls, PetMessageService.maxDailyGenerations); // sin llamada
    expect(extra.message, 'Mensaje');
  });

  test('limpia comillas envolventes y saltos de línea', () async {
    llm.response = '"Hola\nhumano"';
    final msg = await buildService(apiKey: 'key').ensureFreshMessage();

    expect(msg.message, 'Hola humano');
  });

  test('el prompt incluye conteos y mensajes recientes', () async {
    llm.response = 'Uno';
    final service = buildService(apiKey: 'key');
    await service.ensureFreshMessage();
    await service.ensureFreshMessage(force: true);

    expect(llm.lastUserPrompt, contains('hoy 0 eventos'));
    expect(llm.lastUserPrompt, contains('NO los repitas'));
    expect(llm.lastUserPrompt, contains('- Uno'));
  });
}
