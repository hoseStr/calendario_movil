import 'package:drift/drift.dart';

import '../../domain/entities/agenda_summary.dart';
import '../../domain/entities/pet_message.dart';
import '../db/database.dart';

/// Mensajes diarios de la mascota persistidos en la BD.
class PetMessageRepository {
  PetMessageRepository(this._db);

  final AppDatabase _db;

  /// Mensaje ya generado para [day] (normalizado), o null.
  Future<PetMessage?> getForDay(DateTime day) async {
    final key = DateTime(day.year, day.month, day.day);
    final row = await (_db.select(_db.petMessages)
          ..where((t) => t.date.equals(key)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<PetMessage> save(PetMessage message) async {
    final id = await _db.into(_db.petMessages).insert(
          PetMessagesCompanion.insert(
            date: DateTime(
                message.date.year, message.date.month, message.date.day),
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
