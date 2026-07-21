import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/data/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('get devuelve null si la clave no existe', () async {
    expect(await repo.get('theme_mode'), isNull);
  });

  test('set guarda y get recupera', () async {
    await repo.set('theme_mode', 'dark');
    expect(await repo.get('theme_mode'), 'dark');
  });

  test('set sobreescribe el valor anterior', () async {
    await repo.set('theme_mode', 'dark');
    await repo.set('theme_mode', 'light');
    expect(await repo.get('theme_mode'), 'light');
  });
}
