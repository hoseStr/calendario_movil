import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/database.dart';

/// Exporta y restaura TODO el contenido de la app en un JSON local.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const int version = 1;

  Future<String> exportJson() async {
    final events = await _db.select(_db.events).get();
    final settings = await _db.select(_db.settings).get();
    final petMessages = await _db.select(_db.petMessages).get();

    return const JsonEncoder.withIndent('  ').convert({
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'events': [
        for (final e in events)
          {
            'id': e.id,
            'title': e.title,
            'description': e.description,
            'startAt': e.startAt.toIso8601String(),
            'endAt': e.endAt.toIso8601String(),
            'colorIndex': e.colorIndex,
            'category': e.category,
            'recurrenceRule': e.recurrenceRule,
            'reminderMinutes': e.reminderMinutes,
            'createdAt': e.createdAt.toIso8601String(),
            'updatedAt': e.updatedAt.toIso8601String(),
          }
      ],
      'settings': [
        for (final s in settings) {'key': s.key, 'value': s.value}
      ],
      'petMessages': [
        for (final m in petMessages)
          {
            'date': m.date.toIso8601String(),
            'mood': m.mood,
            'message': m.message,
            'source': m.source,
          }
      ],
    });
  }

  /// Restaura un backup: BORRA todo lo actual e importa el archivo.
  /// Lanza FormatException si el JSON no es un backup válido.
  Future<void> restoreFromJson(String json) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('El archivo no es un JSON válido');
    }
    if (data['version'] is! int || data['events'] is! List) {
      throw const FormatException(
          'El archivo no parece un backup de esta app');
    }

    await _db.transaction(() async {
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.events).go();
      await _db.delete(_db.settings).go();
      await _db.delete(_db.petMessages).go();

      for (final raw in data['events'] as List) {
        final e = raw as Map<String, dynamic>;
        await _db.into(_db.events).insert(EventsCompanion.insert(
              id: Value(e['id'] as int),
              title: e['title'] as String,
              description: Value(e['description'] as String?),
              startAt: DateTime.parse(e['startAt'] as String),
              endAt: DateTime.parse(e['endAt'] as String),
              colorIndex: Value(e['colorIndex'] as int? ?? 0),
              category: Value(e['category'] as String?),
              recurrenceRule: Value(e['recurrenceRule'] as String?),
              reminderMinutes: Value(e['reminderMinutes'] as int?),
              createdAt: DateTime.parse(e['createdAt'] as String),
              updatedAt: DateTime.parse(e['updatedAt'] as String),
            ));
      }
      for (final raw in (data['settings'] as List? ?? const [])) {
        final s = raw as Map<String, dynamic>;
        await _db.into(_db.settings).insert(SettingsCompanion.insert(
              key: s['key'] as String,
              value: s['value'] as String,
            ));
      }
      for (final raw in (data['petMessages'] as List? ?? const [])) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.petMessages).insert(PetMessagesCompanion.insert(
              date: DateTime.parse(m['date'] as String),
              mood: m['mood'] as String,
              message: m['message'] as String,
              source: Value(m['source'] as String? ?? 'fallback'),
            ));
      }
    });
  }
}
