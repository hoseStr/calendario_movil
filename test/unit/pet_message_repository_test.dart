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

  test('getForDay devuelve null si no hay mensaje', () async {
    expect(await repo.getForDay(DateTime(2026, 7, 21)), isNull);
  });

  test('save guarda y getForDay recupera (normalizando la hora)', () async {
    await repo.save(build(DateTime(2026, 7, 21, 15, 30)));

    final found = await repo.getForDay(DateTime(2026, 7, 21, 8));
    expect(found, isNotNull);
    expect(found!.message, 'Hola humano');
    expect(found.mood, PetMood.happy);
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
