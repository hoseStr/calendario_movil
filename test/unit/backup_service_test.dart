import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calendario_movil/data/db/database.dart';
import 'package:calendario_movil/data/repositories/event_repository.dart';
import 'package:calendario_movil/data/repositories/pet_message_repository.dart';
import 'package:calendario_movil/data/repositories/settings_repository.dart';
import 'package:calendario_movil/data/services/backup_service.dart';
import 'package:calendario_movil/domain/entities/agenda_summary.dart';
import 'package:calendario_movil/domain/entities/event.dart';
import 'package:calendario_movil/domain/entities/pet_message.dart';

void main() {
  late AppDatabase db;
  late BackupService backup;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backup = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('exportar y restaurar conserva todos los datos e ids', () async {
    final events = EventRepository(db);
    final settings = SettingsRepository(db);
    final messages = PetMessageRepository(db);

    final created = await events.create(Event(
      title: 'Yoga',
      description: 'Con música',
      startAt: DateTime(2026, 7, 21, 7),
      endAt: DateTime(2026, 7, 21, 8),
      colorIndex: 2,
      recurrenceRule: 'daily',
      reminderMinutes: 15,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    ));
    await settings.set('theme_mode', 'dark');
    await settings.set('pet_name', 'Nube');
    await messages.save(PetMessage(
      date: DateTime(2026, 7, 21, 9, 30),
      mood: PetMood.happy,
      message: 'Holaa',
      source: 'gemini',
    ));

    final json = await backup.exportJson();

    // Ensucia la BD para comprobar que restaurar la reemplaza.
    await events.create(Event(
      title: 'Basura',
      startAt: DateTime(2026, 8, 1, 10),
      endAt: DateTime(2026, 8, 1, 11),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await settings.set('theme_mode', 'light');

    await backup.restoreFromJson(json);

    final restored = await events.getById(created.id!);
    expect(restored, isNotNull);
    expect(restored!.title, 'Yoga');
    expect(restored.recurrenceRule, 'daily');
    expect(restored.reminderMinutes, 15);

    final all = await events
        .watchEventsBetween(DateTime(2026, 8, 1), DateTime(2026, 8, 2))
        .first;
    expect(all.where((e) => e.title == 'Basura'), isEmpty);

    expect(await settings.get('theme_mode'), 'dark');
    expect(await settings.get('pet_name'), 'Nube');

    final history = await messages.watchHistory().first;
    expect(history.single.message, 'Holaa');
    expect(history.single.source, 'gemini');
  });

  test('restaurar un archivo inválido lanza FormatException', () async {
    expect(
      () => backup.restoreFromJson('esto no es json'),
      throwsFormatException,
    );
    expect(
      () => backup.restoreFromJson('{"cosa": 1}'),
      throwsFormatException,
    );
  });
}
