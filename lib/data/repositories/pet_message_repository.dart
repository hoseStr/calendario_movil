import 'package:drift/drift.dart';

import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/pet_message.dart';
import '../db/database.dart';

/// Mensajes diarios de la mascota persistidos en la BD.
class PetMessageRepository {
  PetMessageRepository(this._db);

  final AppDatabase _db;

  /// Último mensaje generado (con timestamp completo), o null.
  Future<PetMessage?> latest() async {
    final row = await (_db.select(_db.petMessages)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// Cuántos mensajes se han generado desde [since] (tope diario).
  Future<int> countSince(DateTime since) async {
    final rows = await (_db.select(_db.petMessages)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();
    return rows.length;
  }

  /// Textos de los [count] mensajes más recientes (anti-repetición).
  Future<List<String>> recentTexts(int count) async {
    final rows = await (_db.select(_db.petMessages)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(count))
        .get();
    return rows.map((r) => r.message).toList();
  }

  Future<PetMessage> save(PetMessage message) async {
    final id = await _db.into(_db.petMessages).insert(
          PetMessagesCompanion.insert(
            // Desde la Fase 7 se guarda el timestamp completo
            // (varios mensajes por día + gate de intervalo mínimo).
            date: message.date,
            mood: message.mood.name,
            message: message.message,
            source: Value(message.source),
          ),
        );
    return message.copyWith(id: id);
  }

  /// Historial reciente, del más nuevo al más viejo.
  Stream<List<PetMessage>> watchHistory({int limit = 30}) {
    final query = _db.select(_db.petMessages)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);
    return query.watch().map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  PetMessage _toEntity(PetMessageRow row) => PetMessage(
        id: row.id,
        date: row.date,
        mood: PetMood.values.firstWhere(
          (m) => m.name == row.mood,
          orElse: () => PetMood.happy,
        ),
        message: row.message,
        source: row.source,
      );
}
