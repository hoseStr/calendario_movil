import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// Base de datos de la app.
/// Las tablas `reminders` y `pet_messages` se añadirán en las
/// Fases 5 y 6 con sus migraciones.
@DriftDatabase(tables: [Events, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Para tests: pásale NativeDatabase.memory().
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'calendario_movil');
  }
}
