import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/data/repositories/pet_message_repository.dart';
import 'package:calendario_movil/domain/entities/agenda_summary.dart';
import 'package:calendario_movil/domain/entities/pet_message.dart';

void main() {
  late AppDatabase db;
  late PetMessageRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PetMessageRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  PetMessage build(DateTime date, {String text = 'Hola humano'}) =>
      PetMessage(
        date: date,
        mood: PetMood.happy,
        message: text,
        source: 'fallback',
      );

  test('latest devuelve null sin mensajes', () async {
    expect(await repo.latest(), isNull);
  });

  test('latest devuelve el más reciente con su timestamp completo',
      () async {
    await repo.save(build(DateTime(2026, 7, 21, 9, 0), text: 'mañana'));
    await repo.save(build(DateTime(2026, 7, 21, 18, 30), text: 'tarde'));

    final latest = await repo.latest();
    expect(latest!.message, 'tarde');
    expect(latest.date, DateTime(2026, 7, 21, 18, 30));
  });

  test('recentTexts devuelve los últimos N textos', () async {
    for (var i = 1; i <= 5; i++) {
      await repo.save(build(DateTime(2026, 7, 21, i), text: 'm$i'));
    }
    expect(await repo.recentTexts(3), ['m5', 'm4', 'm3']);
  });

  test('watchHistory ordena del más nuevo al más viejo', () async {
    await repo.save(build(DateTime(2026, 7, 19), text: 'viejo'));
    await repo.save(build(DateTime(2026, 7, 21), text: 'nuevo'));
    await repo.save(build(DateTime(2026, 7, 20), text: 'medio'));

    final history = await repo.watchHistory().first;
    expect(history.map((m) => m.message).toList(),
        ['nuevo', 'medio', 'viejo']);
  });
}
