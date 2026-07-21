import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// Base de datos de la app.
/// La tabla `pet_messages` se añadirá en la Fase 6 con su migración.
@DriftDatabase(tables: [Events, Settings, Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Para tests: pásale NativeDatabase.memory().
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 → v2 (Fase 5): tabla de recordatorios.
            await m.createTable(reminders);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'calendario_movil');
  }
}
